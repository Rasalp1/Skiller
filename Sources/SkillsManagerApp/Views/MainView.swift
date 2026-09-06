import SwiftUI

public struct MainView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
                .frame(minWidth: 220, idealWidth: 250)
        } content: {
            SkillListView(appState: appState)
                .frame(minWidth: 300, idealWidth: 360)
        } detail: {
            if let item = appState.selectedItem {
                SkillDetailView(appState: appState, item: item)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Select a component to inspect")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Manage Skills, Agents, Commands, Rules, MCP Servers, and Hooks across Claude, Codex, and Workspaces.")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await appState.refreshSkills()
        }
        .alert("Agent Stack Error", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            if let msg = appState.errorMessage {
                Text(msg)
            }
        }
    }
}
