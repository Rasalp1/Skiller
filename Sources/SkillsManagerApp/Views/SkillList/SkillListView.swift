import SwiftUI

public struct SkillListView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar with Count and Sort
            HStack {
                Text("\(appState.filteredItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    Picker("Sort By", selection: $appState.sortOrder) {
                        ForEach(SortOrder.allCases) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text(appState.sortOrder.rawValue)
                            .font(.caption)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.sidebarBackground)

            Divider()

            // List of Items
            if appState.filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No items match the filter")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if !appState.searchText.isEmpty {
                        Button("Clear Search") {
                            appState.searchText = ""
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $appState.selectedItemId) {
                    ForEach(appState.filteredItems) { item in
                        SkillRowView(item: item) {
                            appState.toggleItem(item)
                        }
                        .tag(item.id as String?)
                        .contextMenu {
                            Button {
                                appState.toggleItem(item)
                            } label: {
                                Label(item.isEnabled ? "Disable Item" : "Enable Item",
                                      systemImage: item.isEnabled ? "pause.circle" : "play.circle")
                            }

                            if item.kind == .skill || item.kind == .command {
                                Button {
                                    appState.toggleInvocationMode(item)
                                } label: {
                                    Label(item.invocationType == .auto ? "Set to Manual Only" : "Set to Auto-Trigger",
                                          systemImage: item.invocationType == .auto ? "hand.tap" : "bolt.badge.automatic")
                                }
                            }

                            Divider()

                            Button {
                                ShellLauncher.copyToClipboard(item.name)
                            } label: {
                                Label("Copy Name", systemImage: "doc.on.clipboard")
                            }

                            if let u = item.fileURL ?? item.directoryURL {
                                Button {
                                    ShellLauncher.copyToClipboard(u.path)
                                } label: {
                                    Label("Copy Path", systemImage: "link")
                                }

                                Divider()

                                Button {
                                    ShellLauncher.revealInFinder(url: u)
                                } label: {
                                    Label("Reveal in Finder", systemImage: "folder")
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                appState.deleteItem(item)
                            } label: {
                                Label("Delete Item", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $appState.searchText, prompt: "Search skills, agents, commands, rules, MCP, hooks...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await appState.refreshSkills()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}
