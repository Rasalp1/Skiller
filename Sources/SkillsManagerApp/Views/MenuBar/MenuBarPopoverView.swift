import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @Bindable var appState: AppState
    @State private var search: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    var matchingItems: [StackItem] {
        if search.isEmpty {
            return Array(appState.items.prefix(25))
        }
        return appState.items.filter { $0.matches(query: search) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                MacSearchField(text: $search, placeholder: "Search skills, agents, commands...")
                    .frame(height: 24)

                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Theme.sidebarBackground)

            Divider()

            // Item list
            if matchingItems.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No matching items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(matchingItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(item.name)
                                            .font(.system(size: 12, weight: .semibold))
                                        KindBadge(kind: item.kind)
                                        SourceBadge(kind: item.sourceKind)
                                    }
                                    if !item.description.isEmpty {
                                        Text(item.description)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Button {
                                    let prompt = item.kind == .command ? "/\(item.name)" : "Use \(item.name): \(item.description)"
                                    ShellLauncher.copyToClipboard(prompt)
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                .help("Copy Prompt / Name")

                                Toggle("", isOn: Binding(
                                    get: { item.isEnabled },
                                    set: { _ in appState.toggleItem(item) }
                                ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .scaleEffect(0.7)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.02))
                            .cornerRadius(6)
                        }
                    }
                    .padding(6)
                }
                .frame(maxHeight: 340)
            }

            Divider()

            HStack {
                Text("\(appState.activeCount) active of \(appState.totalItemsCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Open App") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(8)
            .background(Theme.sidebarBackground)
        }
        .frame(width: 380)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
