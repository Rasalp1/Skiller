import SwiftUI
import AppKit

public struct SidebarView: View {
    @Bindable var appState: AppState
    public init(appState: AppState) { self.appState = appState }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 20, weight: .medium)).foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Skiller").font(.system(size: 16, weight: .semibold))
                    Text("Your agent library").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 26)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 3) {
                        sectionTitle("Library")
                        navigationRow("All components", icon: "square.grid.2x2", count: appState.totalItemsCount,
                                      selected: appState.selectedKind == nil) { appState.selectedKind = nil }
                        ForEach(ComponentKind.allCases) { kind in
                            navigationRow(kind.rawValue, icon: kind.icon, count: appState.count(for: kind),
                                          selected: appState.selectedKind == kind) { appState.selectedKind = kind }
                        }
                    }
                    VStack(spacing: 3) {
                        sectionTitle("Sources")
                        navigationRow("All sources", icon: "tray.2", selected: appState.selectedSourceId == nil) {
                            appState.selectedSourceId = nil
                        }
                        ForEach(appState.sources.filter { !$0.isCustomWorkspace }) { source in
                            navigationRow(sourceTitle(source), icon: source.kind.icon,
                                          count: appState.items.filter { $0.sourceId == source.id }.count,
                                          selected: appState.selectedSourceId == source.id) {
                                appState.selectedSourceId = source.id
                            }
                        }
                    }
                    VStack(spacing: 3) {
                        sectionTitle("Workspaces")
                        ForEach(appState.sources.filter(\.isCustomWorkspace)) { source in
                            navigationRow(source.name, icon: "folder", selected: appState.selectedSourceId == source.id) {
                                appState.selectedSourceId = source.id
                            }
                            .help(source.activeDirectoryURL.path)
                            .contextMenu {
                                Button("Remove from Library", role: .destructive) {
                                    if appState.selectedSourceId == source.id { appState.selectedSourceId = nil }
                                    appState.removeWorkspace(path: source.activeDirectoryURL.deletingLastPathComponent().deletingLastPathComponent().path)
                                }
                            }
                        }
                        Button(action: selectWorkspaceFolder) {
                            Label("Add workspace…", systemImage: "plus").font(.system(size: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10).padding(.vertical, 9)
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 20)
            }
            Divider().padding(.horizontal, 20)
            HStack(spacing: 8) {
                Image(systemName: "internaldrive").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("On this Mac").font(.system(size: 11, weight: .medium))
                    Text("\(appState.activeCount) active components")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                if appState.isLoading { ProgressView().controlSize(.small) }
            }
            .padding(20)
        }
        .background(.regularMaterial)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10).padding(.bottom, 7)
    }

    private func navigationRow(_ title: String, icon: String, count: Int? = nil,
                               selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 13)).frame(width: 17)
                    .foregroundStyle(selected ? Theme.accent : .secondary)
                Text(title).font(.system(size: 12, weight: selected ? .semibold : .regular)).lineLimit(1)
                Spacer(minLength: 4)
                if let count {
                    Text(count, format: .number).font(.system(size: 11)).monospacedDigit()
                        .foregroundStyle(selected ? Theme.accent : .secondary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(selected ? Theme.selection : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func sourceTitle(_ source: SkillSource) -> String {
        switch source.id {
        case "claude-global": return "Claude"
        case "codex-global": return "Codex"
        case "antigravity-config": return "Antigravity"
        case "antigravity-builtin": return "Antigravity Built-in"
        default: return source.name
        }
    }

    private func selectWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add Workspace"
        panel.message = "Choose a project to include its agent components in your library."
        if panel.runModal() == .OK, let url = panel.url { appState.addWorkspaceFolder(url: url) }
    }
}
