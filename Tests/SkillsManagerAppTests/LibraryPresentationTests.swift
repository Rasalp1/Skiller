import Foundation
import Testing
@testable import SkillsManagerApp

@Suite("Library presentation")
struct LibraryPresentationTests {
    @Test("Markdown retains code literally while separating document structure")
    func documentBlocks() {
        let document = """
        # Getting started

        A **useful** instruction.

        - First step
        2. Second step

        ```swift
        # This is code, not a heading
        let enabled = true
        ```

        > Remember this
        ---
        """
        #expect(MarkdownBlock.parse(document) == [
            .heading(1, "Getting started"),
            .paragraph("A **useful** instruction."),
            .bullet("•", "First step"),
            .bullet("2.", "Second step"),
            .code("# This is code, not a heading\nlet enabled = true"),
            .quote("Remember this"),
            .divider
        ])
    }

    @Test("Incomplete code fences do not hide the remaining instructions")
    func incompleteFence() {
        #expect(MarkdownBlock.parse("Before\n\n~~~sh\necho hello") == [
            .paragraph("Before"), .code("echo hello")
        ])
        #expect(MarkdownBlock.parse("   \n\n").isEmpty)
    }

    @Test("Shared configurations and non-Markdown files cannot use the document editor")
    func documentCapabilities() {
        func item(_ kind: ComponentKind, _ path: String?) -> StackItem {
            StackItem(id: "test", kind: kind, name: "Test", description: "",
                      sourceId: "test", sourceKind: .claude, sourceName: "Test", isEnabled: true,
                      fileURL: path.map { URL(fileURLWithPath: $0) }, content: "",
                      lastModified: Date())
        }
        #expect(item(.skill, "/tmp/SKILL.md").isEditableDocument)
        #expect(item(.rule, "/tmp/rules.MD").isEditableDocument)
        #expect(!item(.mcpServer, "/tmp/config.json").isEditableDocument)
        #expect(!item(.hook, "/tmp/hook.md").isEditableDocument)
        #expect(!item(.rule, "/tmp/rules.toml").isEditableDocument)
        #expect(!item(.skill, nil).isEditableDocument)
    }
}
