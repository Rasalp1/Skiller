import SwiftUI

public struct MainView: View {
    @Bindable var appState: AppState
    public init(appState: AppState) { self.appState = appState }

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
                .navigationSplitViewColumnWidth(min: 205, ideal: 225, max: 280)
        } content: {
            SkillListView(appState: appState)
                .navigationSplitViewColumnWidth(min: 290, ideal: 340, max: 440)
        } detail: {
            if let item = appState.selectedItem {
                SkillDetailView(appState: appState, item: item)
                    .id(item.id)
            } else {
                EmptyLibraryView(icon: "square.stack.3d.up", title: "A place for every capability",
                                 message: "Select a component to explore its instructions, configuration, and files.")
                    .background(Theme.canvas)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Theme.accent)
        .navigationTitle("Skiller")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await appState.refreshSkills() }
                } label: {
                    Label("Refresh Library", systemImage: "arrow.clockwise")
                }
                .disabled(appState.isLoading).help("Refresh library (⌘R)")
            }
        }
        .task { await appState.refreshSkills() }
        .alert("Couldn’t complete the action", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}
