import SwiftUI

public struct SkillListView: View {
    @Bindable var appState: AppState
    @State private var showingFilters = false
    @State private var itemToDelete: StackItem?
    @FocusState private var searchFocused: Bool
    public init(appState: AppState) { self.appState = appState }

    public var body: some View {
        let visibleItems = appState.filteredItems
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text(appState.selectedKind?.rawValue ?? "All components")
                        .font(.system(size: 21, weight: .bold))
                    Spacer()
                    Text(visibleItems.count, format: .number)
                        .font(.system(size: 13)).monospacedDigit().foregroundStyle(.secondary)
                }
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search library", text: $appState.searchText)
                        .textFieldStyle(.plain).focused($searchFocused).accessibilityLabel("Search library")
                    if !appState.searchText.isEmpty {
                        Button { appState.searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain).help("Clear search")
                    } else {
                        Text("⌘F").font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 13)).padding(9)
                .background(Theme.secondarySurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.subtleBorder))
                HStack {
                    Menu {
                        Picker("Sort by", selection: $appState.sortOrder) {
                            ForEach(SortOrder.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(appState.sortOrder.rawValue, systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 11))
                    }
                    .menuStyle(.borderlessButton).fixedSize()
                    Spacer()
                    Button { showingFilters.toggle() } label: {
                        Label(hasFilters ? "Filtered" : "Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 11)).foregroundStyle(hasFilters ? Theme.accent : .secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingFilters) { FilterSectionView(appState: appState) }
                }
                .foregroundStyle(.secondary)
            }
            .padding(20)
            Divider()
            if appState.isLoading && appState.items.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Reading your library…").font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visibleItems.isEmpty {
                VStack(spacing: 0) {
                    EmptyLibraryView(icon: "magnifyingglass", title: "No components found",
                        message: appState.items.isEmpty ? "Add a workspace or install components in one of your agent sources." : "Try another search or reset your filters to see more of your library.")
                    if !appState.items.isEmpty {
                        Button("Reset search and filters") { appState.resetFilters() }
                            .buttonStyle(.bordered).padding(.bottom, 32)
                    }
                }
            } else {
                List(selection: $appState.selectedItemId) {
                    ForEach(visibleItems) { item in
                        SkillRowView(item: item)
                            .tag(item.id).listRowSeparator(.hidden)
                            .contextMenu {
                                if item.kind != .hook {
                                    Button(item.isEnabled ? "Disable Component" : "Enable Component") { appState.toggleItem(item) }
                                }
                                Button("Copy Name") { ShellLauncher.copyToClipboard(item.name) }
                                if let url = item.fileURL ?? item.directoryURL {
                                    Button("Reveal in Finder") { ShellLauncher.revealInFinder(url: url) }
                                    Button("Copy Path") { ShellLauncher.copyToClipboard(url.path) }
                                }
                                if item.isEditableDocument {
                                    Divider()
                                    Button("Delete Component…", role: .destructive) { itemToDelete = item }
                                }
                            }
                    }
                }
                .listStyle(.inset).scrollContentBackground(.hidden)
            }
            Divider()
            HStack {
                Text(appState.selectedSourceId.flatMap { id in appState.sources.first { $0.id == id }?.name } ?? "All sources")
                    .lineLimit(1)
                Spacer()
                Text("\(visibleItems.filter(\.isEnabled).count) active").monospacedDigit()
            }
            .font(.system(size: 10)).foregroundStyle(.secondary)
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.canvas)
        .background {
            Button("Search Library") { searchFocused = true }
                .keyboardShortcut("f", modifiers: .command).hidden()
        }
        .onChange(of: visibleItems.map(\.id)) { _, ids in
            if let selected = appState.selectedItemId, ids.contains(selected) { return }
            appState.selectedItemId = ids.first
        }
        .alert("Delete component?", isPresented: Binding(
            get: { itemToDelete != nil }, set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { itemToDelete = nil }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete { appState.deleteItem(item) }
                itemToDelete = nil
            }
        } message: {
            Text("“\(itemToDelete?.name ?? "")” and its files will be permanently deleted. This cannot be undone.")
        }
    }

    private var hasFilters: Bool { appState.statusFilter != .all || appState.triggerFilter != nil }
}
