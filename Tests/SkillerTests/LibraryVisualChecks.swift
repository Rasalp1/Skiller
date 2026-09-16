import AppKit
import SwiftUI
import Testing
@testable import Skiller

/// Opt-in, synthetic-data renders. No screen recording or real component edits.
@Suite("Library visual checks", .serialized)
struct LibraryVisualChecks {
    @Test("Render library at standard and minimum sizes")
    @MainActor
    func renderLibrary() throws {
        guard let output = ProcessInfo.processInfo.environment["SKILLER_SNAPSHOT_DIR"] else { return }
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let state = AppState()
        let sample = StackItem(
            id: "sample", kind: .skill, name: "frontend-design",
            description: "Create distinctive, production-grade interfaces with thoughtful typography, clear hierarchy, and a strong visual point of view.",
            sourceId: "claude-global", sourceKind: .claude, sourceName: "Claude Global",
            isEnabled: true, fileURL: URL(fileURLWithPath: "/tmp/example/frontend-design/SKILL.md"),
            directoryURL: URL(fileURLWithPath: "/tmp/example/frontend-design"),
            content: "# Frontend Design\n\nBuild interfaces that feel deliberate.\n\n## Design principles\n\n- Start with a clear hierarchy.\n- Make every interaction understandable.\n\n```swift\nText(\"Hello, Mac.\")\n    .font(.headline)\n```",
            frontmatter: ["name": "frontend-design", "origin": "Personal library"],
            lastModified: Date(timeIntervalSince1970: 1788652800)
        )
        state.items = [
            StackItem(id: "agent", kind: .agent, name: "code-reviewer",
                      description: "Thoughtful code review for correctness, clarity, and maintainability.",
                      sourceId: "claude-global", sourceKind: .claude, sourceName: "Claude Global", isEnabled: true, content: ""),
            sample,
            StackItem(id: "command", kind: .command, name: "prepare-release",
                      description: "Prepare a release with a changelog and version checks.",
                      sourceId: "codex-global", sourceKind: .codex, sourceName: "Codex Global", isEnabled: true, content: ""),
            StackItem(id: "rule", kind: .rule, name: "swift-conventions",
                      description: "Shared conventions for clear, idiomatic Swift.",
                      sourceId: "claude-global", sourceKind: .claude, sourceName: "Claude Global", isEnabled: false, content: "")
        ]
        state.selectedItemId = sample.id
        for (name, width, height, dark) in [
            ("library-light", 1240.0, 780.0, false),
            ("library-dark", 1240.0, 780.0, true),
            ("library-narrow", 980.0, 600.0, false)
        ] {
            let root = HStack(spacing: 0) {
                SidebarView(appState: state).frame(width: dark || width > 1000 ? 225 : 205)
                Divider()
                SkillListView(appState: state).frame(width: width > 1000 ? 340 : 290)
                Divider()
                SkillDetailView(appState: state, item: sample)
            }
            .tint(Theme.accent).environment(\.colorScheme, dark ? .dark : .light)
            try render(root, width: width, height: height, dark: dark, path: output + "/" + name + ".png")
        }
        try render(MarkdownDocumentView(content: sample.content), width: 650, height: 600,
                   dark: false, path: output + "/instructions.png")
        try render(ComponentEditorView(appState: state, item: sample), width: 680, height: 680,
                   dark: false, path: output + "/editor.png")
    }

    @MainActor
    private func render<Content: View>(_ content: Content, width: Double, height: Double,
                                      dark: Bool, path: String) throws {
        let view = NSHostingView(rootView: content)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        window.contentView = view
        view.frame = NSRect(x: 0, y: 0, width: width, height: height)
        window.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        view.layoutSubtreeIfNeeded()
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: path))
        window.orderOut(nil)
    }
}
