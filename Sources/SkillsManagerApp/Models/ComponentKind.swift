import SwiftUI

public enum ComponentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case skill = "Skills"
    case agent = "Agents"
    case command = "Commands"
    case rule = "Rules"
    case mcpServer = "MCP Servers"
    case hook = "Hooks & Plugins"

    public var id: String { rawValue }

    public var singularName: String {
        switch self {
        case .skill: return "Skill"
        case .agent: return "Agent"
        case .command: return "Command"
        case .rule: return "Rule"
        case .mcpServer: return "MCP Server"
        case .hook: return "Hook / Plugin"
        }
    }

    public var icon: String {
        switch self {
        case .skill: return "bolt.fill"
        case .agent: return "person.crop.rectangle.stack.fill"
        case .command: return "terminal.fill"
        case .rule: return "scroll.fill"
        case .mcpServer: return "network"
        case .hook: return "puzzlepiece.extension.fill"
        }
    }

    public var color: Color {
        switch self {
        case .skill: return Color(red: 0.85, green: 0.45, blue: 0.25)
        case .agent: return Color(red: 0.58, green: 0.30, blue: 0.82)
        case .command: return Color(red: 0.24, green: 0.55, blue: 0.95)
        case .rule: return Color(red: 0.20, green: 0.72, blue: 0.45)
        case .mcpServer: return Color(red: 0.15, green: 0.65, blue: 0.75)
        case .hook: return Color(red: 0.88, green: 0.30, blue: 0.55)
        }
    }
}
