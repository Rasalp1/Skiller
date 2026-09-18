import Testing
import Foundation
@testable import Skiller

@Suite("Skiller Core Tests")
struct SkillerTests {

    @Test("Test Frontmatter Parsing and Serializing")
    func testFrontmatter() {
        let sampleMarkdown = """
        ---
        name: test-skill
        description: Diagnostic loop for hard bugs. Use when the user says "diagnose this".
        origin: ECC
        ---

        # Test Skill Body

        ## When to use
        - Use when encountering runtime errors.
        """

        let parsed = FrontmatterParser.parse(sampleMarkdown)
        #expect(parsed.name == "test-skill")
        #expect(parsed.attributes["origin"] == "ECC")
        #expect(parsed.body.contains("# Test Skill Body"))

        let analysis = SkillTriggerAnalysis.analyze(
            name: "test-skill",
            frontmatter: parsed.attributes,
            markdownBody: parsed.body
        )
        #expect(analysis.triggerType == .auto || analysis.triggerType == .hybrid)
        #expect(analysis.criteria.count > 0)
    }

    @Test("Test Manual Trigger Detection")
    func testManualTrigger() {
        let sampleManual = """
        ---
        name: manual-utility
        description: A utility script invoked strictly by user command. Manual only.
        ---

        # Manual Utility
        Run `/manual-utility` in chat.
        """

        let parsed = FrontmatterParser.parse(sampleManual)
        let analysis = SkillTriggerAnalysis.analyze(
            name: "manual-utility",
            frontmatter: parsed.attributes,
            markdownBody: parsed.body
        )
        #expect(analysis.triggerType == .manual)
    }

    @Test("Test Search Matching Excludes Provider")
    func testSearchMatchingExcludesProvider() {
        let item = StackItem(
            id: "test-item-id",
            kind: .skill,
            name: "git-rebase-helper",
            description: "Interactive git rebase helper",
            sourceId: "claude-personal",
            sourceKind: .claude,
            sourceName: "Claude (Personal)",
            isEnabled: true,
            fileURL: URL(fileURLWithPath: "/Users/test/.claude/skills/git-rebase-helper/SKILL.md"),
            directoryURL: URL(fileURLWithPath: "/Users/test/.claude/skills/git-rebase-helper"),
            content: "Run git rebase -i HEAD~5 to squash commits.",
            frontmatter: ["author": "alice", "tags": "vcs"],
            metadata: ["key": "custom-val"],
            invocationType: .auto,
            lastModified: Date(),
            files: [
                SkillFileItem(
                    id: "f1",
                    name: "script.sh",
                    relativePath: "scripts/script.sh",
                    url: URL(fileURLWithPath: "/Users/test/.claude/skills/git-rebase-helper/scripts/script.sh"),
                    isDirectory: false,
                    sizeInBytes: 120
                )
            ]
        )

        // Matching various parts of the item
        #expect(item.matches(query: "git"))
        #expect(item.matches(query: "rebase"))
        #expect(item.matches(query: "squash"))
        #expect(item.matches(query: "skills")) // kind plural
        #expect(item.matches(query: "skill"))  // kind singular
        #expect(item.matches(query: "auto"))   // invocation type
        #expect(item.matches(query: "alice"))  // frontmatter
        #expect(item.matches(query: "custom-val")) // metadata
        #expect(item.matches(query: "script.sh"))  // attached file
        #expect(item.matches(query: "git squash")) // multiple terms

        // Must NOT match provider name "claude" or "codex"
        #expect(!item.matches(query: "claude"))
        #expect(!item.matches(query: "codex"))
    }

    @Test("MCP discovery redacts environment values")
    func testMCPEnvironmentRedaction() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("skiller-mcp-" + UUID().uuidString, isDirectory: true)
        let skills = root.appendingPathComponent("skills", isDirectory: true)
        try FileManager.default.createDirectory(at: skills, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let mcp = root.appendingPathComponent("mcp.json")
        let config = #"{"mcpServers":{"private":{"command":"node","env":{"API_KEY":"super-secret","REGION":"eu"}}}}"#
        try config.data(using: .utf8)!.write(to: mcp)

        let source = SkillSource(
            id: "test-source",
            name: "Test",
            kind: .workspace,
            activeDirectoryURL: skills,
            disabledDirectoryURL: root.appendingPathComponent("skills-disabled")
        )
        let items = await StackDiscoveryService().discoverAll(in: [source])
        let server = items.first { $0.kind == .mcpServer }

        #expect(server?.content.contains("super-secret") == false)
        #expect(server?.content.contains("<redacted>") == true)
        #expect(server?.metadata["envKeys"]?.contains("API_KEY") == true)
    }

    @Test("Skill directory names reject traversal")
    func testSkillDirectoryNameValidation() {
        #expect(SkillManagerService.isSafeDirectoryName("review-helper"))
        #expect(!SkillManagerService.isSafeDirectoryName("../escape"))
        #expect(!SkillManagerService.isSafeDirectoryName("nested/name"))
        #expect(!SkillManagerService.isSafeDirectoryName(".."))
    }
}
