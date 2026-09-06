import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var search = ""
    @State private var copiedID: String?
    @State private var copyResetTask: Task<Void, Never>?
    @State private var launchAtLogin: Bool = false

    public init(appState: AppState) { self.appState = appState }

    private var matchingItems: [StackItem] {
        Array(appState.items.filter { search.isEmpty || $0.matches(query: search) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }.prefix(40))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("Quick access").font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(appState.activeCount) active").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)
            MacSearchField(text: $search, placeholder: "Find a component")
                .frame(height: 28).padding(.horizontal, 16).padding(.bottom, 14)
            Divider()
            if matchingItems.isEmpty {
                EmptyLibraryView(icon: "magnifyingglass", title: "No results",
                                 message: "Try a different name or search term.")
                    .frame(height: 210)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(matchingItems) { item in
                            HStack(spacing: 10) {
                                Button {
                                    appState.resetFilters()
                                    appState.selectedItemId = item.id
                                    showLibrary()
                                } label: {
                                    HStack(spacing: 10) {
                                        ComponentIcon(kind: item.kind, size: 30)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                            Text("\(item.sourceKind.rawValue) · \(item.kind.singularName)")
                                                .font(.system(size: 10)).foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain).help("Open component in library")
                                Button {
                                    ShellLauncher.copyToClipboard(item.kind == .command ? "/\(item.name)" : "Use \(item.name): \(item.description)")
                                    copiedID = item.id
                                    copyResetTask?.cancel()
                                    copyResetTask = Task { @MainActor in
                                        try? await Task.sleep(for: .seconds(2))
                                        guard !Task.isCancelled else { return }
                                        copiedID = nil
                                    }
                                } label: {
                                    Image(systemName: copiedID == item.id ? "checkmark" : "doc.on.doc")
                                        .foregroundStyle(copiedID == item.id ? Theme.accent : .secondary)
                                }
                                .buttonStyle(.borderless).help("Copy prompt for \(item.name)")
                                if item.kind != .hook {
                                    Toggle("Enable \(item.name)", isOn: Binding(
                                        get: { item.isEnabled }, set: { _ in appState.toggleItem(item) }
                                    ))
                                    .labelsHidden().toggleStyle(.switch).controlSize(.mini)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 11)
                        }
                    }
                }
                .frame(height: 340)
            }
            Divider()
            HStack(spacing: 10) {
                Button {
                    Task { await appState.refreshSkills() }
                } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless).disabled(appState.isLoading).help("Refresh library")
                
                Menu {
                    Toggle("Launch at Login", isOn: Binding(
                        get: { launchAtLogin },
                        set: { newValue in
                            launchAtLogin = newValue
                            LaunchAtLoginManager.setEnabled(newValue)
                        }
                    ))
                    Divider()
                    Button(role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit Skiller")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("Settings & Options")

                Text("Skiller").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Open Library", action: showLibrary).buttonStyle(.bordered).controlSize(.small)
            }
            .padding(14)
        }
        .frame(width: 380).tint(Theme.accent)
        .task { if appState.items.isEmpty { await appState.refreshSkills() } }
        .onAppear { launchAtLogin = LaunchAtLoginManager.isEnabled }
        .onDisappear { copyResetTask?.cancel() }
    }

    private func showLibrary() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "library")
        NSApp.activate(ignoringOtherApps: true)
    }
}
