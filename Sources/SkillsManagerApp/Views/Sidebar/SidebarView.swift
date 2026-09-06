import SwiftUI
import AppKit

public struct SidebarView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        List {
            // Component Categories
            Section("Components") {
                categoryRow(title: "All Components", icon: "square.stack.3d.up.fill", count: appState.totalItemsCount, isSelected: appState.selectedKind == nil) {
                    appState.selectedKind = nil
                }

                ForEach(ComponentKind.allCases) { kind in
                    categoryRow(
                        title: kind.rawValue,
                        icon: kind.icon,
                        iconColor: kind.color,
                        count: appState.count(for: kind),
                        isSelected: appState.selectedKind == kind
                    ) {
                        appState.selectedKind = kind
                    }
                }
            }

            // Sources
            Section("Sources") {
                sourceRow(title: "All Sources", icon: "globe", isSelected: appState.selectedSourceId == nil) {
                    appState.selectedSourceId = nil
                }

                ForEach(appState.sources.filter { !$0.isCustomWorkspace }) { source in
                    let count = appState.items.filter { $0.sourceId == source.id && (appState.selectedKind == nil || $0.kind == appState.selectedKind) }.count
                    sourceRow(
                        title: source.name,
                        icon: source.kind.icon,
                        iconColor: Theme.colorForSource(source.kind),
                        count: count,
                        isSelected: appState.selectedSourceId == source.id
                    ) {
                        appState.selectedSourceId = source.id
                    }
                }
            }

            // Project Workspaces
            let workspaceSources = appState.sources.filter { $0.isCustomWorkspace }
            Section {
                ForEach(workspaceSources) { source in
                    let count = appState.items.filter { $0.sourceId == source.id && (appState.selectedKind == nil || $0.kind == appState.selectedKind) }.count
                    HStack {
                        Label(source.name, systemImage: "folder.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.selectedSourceId = (appState.selectedSourceId == source.id) ? nil : source.id
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            appState.removeWorkspace(path: source.activeDirectoryURL.deletingLastPathComponent().deletingLastPathComponent().path)
                        } label: {
                            Label("Remove Workspace", systemImage: "trash")
                        }
                    }
                }

                Button(action: selectWorkspaceFolder) {
                    Label("Add Project Workspace...", systemImage: "plus.circle")
                        .font(.callout)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            } header: {
                Text("Project Workspaces")
            }

            // Status Filter
            Section("Status Filter") {
                Picker("Status", selection: $appState.statusFilter) {
                    ForEach(FilterStatus.allCases) { st in
                        Text(st.rawValue).tag(st)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Agent Stack")
    }

    private func categoryRow(title: String, icon: String, iconColor: Color = .accentColor, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private func sourceRow(title: String, icon: String, iconColor: Color = .primary, count: Int? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
            Spacer()
            if let c = count {
                Text("\(c)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func selectWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add Workspace"

        if panel.runModal() == .OK, let url = panel.url {
            appState.addWorkspaceFolder(url: url)
        }
    }
}
