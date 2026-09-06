import AppKit
import SwiftUI
import Testing
@testable import Skiller

@Suite("Library layout", .serialized)
struct LibraryLayoutTests {
    @Test("Selection keeps library content inside the window", arguments: [
        CGSize(width: 980, height: 692), // 640-point content plus the unified toolbar.
        CGSize(width: 1470, height: 812)
    ])
    @MainActor
    func selectionLayout(size: CGSize) throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let state = AppState()
        state.sources = []
        let host = NSHostingView(rootView: MainView(appState: state)
            .frame(minWidth: 980, minHeight: 640))
        // Keep the window size fixed, as when it already fills the available screen.
        host.sizingOptions = []
        let window = NSWindow(contentRect: NSRect(origin: CGPoint(x: 0, y: 100), size: size),
                              styleMask: [.titled, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.toolbar = NSToolbar(identifier: "Library")
        window.toolbarStyle = .unified
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        func settle() {
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            host.layoutSubtreeIfNeeded()
        }
        settle()
        let agent = StackItem(id: "agent", kind: .agent, name: "a11y-architect", description: "Accessibility Architect",
                              sourceId: "test", sourceKind: .claude, sourceName: "Claude Global", isEnabled: true,
                              fileURL: URL(fileURLWithPath: "/tmp/example/agent.md"), content: "")
        let skill = StackItem(id: "skill", kind: .skill, name: "agent-harness-construction",
                              description: "Design and optimize AI agent action spaces, tool definitions, and observation formatting for higher completion rates.",
                              sourceId: "test", sourceKind: .claude, sourceName: "Claude Global", isEnabled: true,
                              fileURL: URL(fileURLWithPath: "/tmp/example/SKILL.md"), content: "# Instructions",
                              frontmatter: ["invocation": "manual", "origin": "ECC"])
        state.items = [agent, skill]
        func splitView(in view: NSView) -> NSSplitView? {
            if let split = view as? NSSplitView { return split }
            return view.subviews.lazy.compactMap { splitView(in: $0) }.first
        }
        state.selectedItemId = agent.id
        settle()
        let initialWindowFrame = window.frame
        let initialSplit = try #require(splitView(in: host))
        let initialContentFrame = initialSplit.convert(initialSplit.bounds, to: host)
        func expectStableLayout() throws {
            let split = try #require(splitView(in: host))
            let contentFrame = split.convert(split.bounds, to: host)
            #expect(window.frame == initialWindowFrame)
            #expect(contentFrame == initialContentFrame)
            #expect(contentFrame.minY >= host.bounds.minY - 1)
            #expect(contentFrame.maxY <= host.bounds.maxY + 1)
        }
        // List selection.
        state.selectedItemId = skill.id
        settle()
        try expectStableLayout()
        state.selectedItemId = agent.id
        settle()
        // Sidebar category selection selects the first matching skill.
        state.selectedKind = .skill
        settle()
        #expect(state.selectedItemId == skill.id)
        try expectStableLayout()
        // Quick-access selection clears filters before selecting the item.
        state.selectedKind = .agent
        settle()
        state.resetFilters()
        state.selectedItemId = skill.id
        settle()
        #expect(state.selectedItemId == skill.id)
        try expectStableLayout()
    }
}
