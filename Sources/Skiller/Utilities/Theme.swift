import SwiftUI
import AppKit

public enum Theme {
    public static let accent = Color(red: 0.22, green: 0.43, blue: 0.86)
    public static let background = Color(NSColor.windowBackgroundColor)
    public static let sidebarBackground = Color(NSColor.controlBackgroundColor)
    public static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.6)
    public static let subtleBorder = Color.primary.opacity(0.08)
    public static let canvas = Color(NSColor.textBackgroundColor)
    public static let secondarySurface = Color.primary.opacity(0.035)
    public static let selection = accent.opacity(0.11)
    public static let pageInset: CGFloat = 28

    public static let claudeOrange = Color(red: 0.85, green: 0.45, blue: 0.25)
    public static let codexIndigo = Color(red: 0.35, green: 0.40, blue: 0.88)
    public static let antigravityPurple = Color(red: 0.58, green: 0.30, blue: 0.82)
    public static let autoGreen = Color(red: 0.20, green: 0.72, blue: 0.45)
    public static let manualBlue = Color(red: 0.24, green: 0.55, blue: 0.95)
    public static let hybridAmber = Color(red: 0.95, green: 0.65, blue: 0.20)

    public static func colorForSource(_ kind: SkillSourceKind) -> Color {
        switch kind {
        case .claude: return claudeOrange
        case .codex: return codexIndigo
        case .antigravity: return antigravityPurple
        case .workspace: return .blue
        }
    }

    public static func colorForTrigger(_ type: InvocationTriggerType) -> Color {
        switch type {
        case .auto: return autoGreen
        case .manual: return manualBlue
        case .hybrid: return hybridAmber
        }
    }
}

struct ComponentIcon: View {
    let kind: ComponentKind
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: kind.icon)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .background(Theme.accent.opacity(0.085), in: RoundedRectangle(cornerRadius: size * 0.25))
            .accessibilityHidden(true)
    }
}

struct EmptyLibraryView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Theme.accent)
                .frame(width: 68, height: 68)
                .background(Theme.selection, in: RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 4)
            Text(title).font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(.system(size: 13)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 290)
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct CardContainerModifier: ViewModifier {
    public var cornerRadius: CGFloat = 10
    public var padding: CGFloat = 12

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            )
    }
}

public extension View {
    func cardContainer(cornerRadius: CGFloat = 10, padding: CGFloat = 12) -> some View {
        modifier(CardContainerModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
