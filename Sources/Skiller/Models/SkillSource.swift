import Foundation

public enum SkillSourceKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case claude = "Claude"
    case codex = "Codex"
    case antigravity = "Antigravity"
    case workspace = "Workspace"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .claude: return "sparkle"
        case .codex: return "cpu"
        case .antigravity: return "atom"
        case .workspace: return "folder.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .claude: return "orange"
        case .codex: return "indigo"
        case .antigravity: return "purple"
        case .workspace: return "blue"
        }
    }
}

public struct SkillSource: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: SkillSourceKind
    public let activeDirectoryURL: URL
    public let disabledDirectoryURL: URL
    public let isCustomWorkspace: Bool

    public init(
        id: String,
        name: String,
        kind: SkillSourceKind,
        activeDirectoryURL: URL,
        disabledDirectoryURL: URL,
        isCustomWorkspace: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.activeDirectoryURL = activeDirectoryURL
        self.disabledDirectoryURL = disabledDirectoryURL
        self.isCustomWorkspace = isCustomWorkspace
    }

    public static func defaultSources() -> [SkillSource] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var sources: [SkillSource] = []

        // Claude global
        let claudeActive = home.appendingPathComponent(".claude/skills")
        let claudeDisabled = home.appendingPathComponent(".claude/skills-disabled")
        sources.append(SkillSource(
            id: "claude-global",
            name: "Claude Global",
            kind: .claude,
            activeDirectoryURL: claudeActive,
            disabledDirectoryURL: claudeDisabled
        ))

        // Codex global
        let codexActive = home.appendingPathComponent(".codex/skills")
        let codexDisabled = home.appendingPathComponent(".codex/skills-disabled")
        sources.append(SkillSource(
            id: "codex-global",
            name: "Codex Global",
            kind: .codex,
            activeDirectoryURL: codexActive,
            disabledDirectoryURL: codexDisabled
        ))

        // Antigravity builtin & config
        let agyConfig = home.appendingPathComponent(".gemini/config/skills")
        let agyConfigDisabled = home.appendingPathComponent(".gemini/config/skills-disabled")
        sources.append(SkillSource(
            id: "antigravity-config",
            name: "Antigravity User Config",
            kind: .antigravity,
            activeDirectoryURL: agyConfig,
            disabledDirectoryURL: agyConfigDisabled
        ))

        let agyBuiltin = home.appendingPathComponent(".gemini/antigravity-ide/builtin/skills")
        let agyBuiltinDisabled = home.appendingPathComponent(".gemini/antigravity-ide/builtin/skills-disabled")
        sources.append(SkillSource(
            id: "antigravity-builtin",
            name: "Antigravity Built-in",
            kind: .antigravity,
            activeDirectoryURL: agyBuiltin,
            disabledDirectoryURL: agyBuiltinDisabled
        ))

        return sources
    }

    public static func workspaceSource(for folderURL: URL) -> [SkillSource] {
        var result: [SkillSource] = []
        let folderName = folderURL.lastPathComponent

        let claudeLocal = folderURL.appendingPathComponent(".claude/skills")
        let claudeLocalDisabled = folderURL.appendingPathComponent(".claude/skills-disabled")
        if FileManager.default.fileExists(atPath: claudeLocal.path) || FileManager.default.fileExists(atPath: claudeLocalDisabled.path) {
            result.append(SkillSource(
                id: "ws-claude-\(folderURL.path)",
                name: "\(folderName) (.claude)",
                kind: .workspace,
                activeDirectoryURL: claudeLocal,
                disabledDirectoryURL: claudeLocalDisabled,
                isCustomWorkspace: true
            ))
        }

        let codexLocal = folderURL.appendingPathComponent(".codex/skills")
        let codexLocalDisabled = folderURL.appendingPathComponent(".codex/skills-disabled")
        if FileManager.default.fileExists(atPath: codexLocal.path) || FileManager.default.fileExists(atPath: codexLocalDisabled.path) {
            result.append(SkillSource(
                id: "ws-codex-\(folderURL.path)",
                name: "\(folderName) (.codex)",
                kind: .workspace,
                activeDirectoryURL: codexLocal,
                disabledDirectoryURL: codexLocalDisabled,
                isCustomWorkspace: true
            ))
        }

        let agentsLocal = folderURL.appendingPathComponent(".agents/skills")
        let agentsLocalDisabled = folderURL.appendingPathComponent(".agents/skills-disabled")
        if FileManager.default.fileExists(atPath: agentsLocal.path) || FileManager.default.fileExists(atPath: agentsLocalDisabled.path) || result.isEmpty {
            result.append(SkillSource(
                id: "ws-agents-\(folderURL.path)",
                name: "\(folderName) (.agents)",
                kind: .workspace,
                activeDirectoryURL: agentsLocal,
                disabledDirectoryURL: agentsLocalDisabled,
                isCustomWorkspace: true
            ))
        }

        return result
    }
}
