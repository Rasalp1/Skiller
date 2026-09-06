import SwiftUI
import Observation
import Foundation

public enum FilterStatus: String, CaseIterable, Identifiable, Sendable {
    case all = "All Status"
    case active = "Active Only"
    case disabled = "Disabled Only"

    public var id: String { rawValue }
}

public enum SortOrder: String, CaseIterable, Identifiable, Sendable {
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case recentlyModified = "Recently Modified"
    case triggerType = "Category"

    public var id: String { rawValue }
}

@Observable
@MainActor
public final class AppState {
    public var sources: [SkillSource] = []
    public var items: [StackItem] = []
    public var selectedItemId: String?

    // Category & Filters
    public var selectedKind: ComponentKind? = nil // nil = "All Categories"
    public var selectedSourceId: String? = nil    // nil = "All Sources"
    public var statusFilter: FilterStatus = .all
    public var triggerFilter: InvocationTriggerType? = nil
    public var searchText: String = ""
    public var sortOrder: SortOrder = .nameAsc

    // UI state
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var customWorkspacePaths: [String] = []

    private let stackDiscoveryService = StackDiscoveryService()
    private let stackManagerService = StackManagerService()
    private let watcherService = FileWatcherService()

    private let workspaceDefaultsKey = "Skiller.CustomWorkspaces"
    private let legacyWorkspaceDefaultsKey = "Skiller.CustomWorkspaces"

    public init() {
        loadSavedWorkspaces()
        reloadSources()
    }

    public var selectedItem: StackItem? {
        get {
            items.first(where: { $0.id == selectedItemId })
        }
        set {
            selectedItemId = newValue?.id
        }
    }

    public var filteredItems: [StackItem] {
        var list = items

        if let kind = selectedKind {
            list = list.filter { $0.kind == kind }
        }

        if let sourceId = selectedSourceId {
            list = list.filter { $0.sourceId == sourceId }
        }

        switch statusFilter {
        case .all: break
        case .active:
            list = list.filter { $0.isEnabled }
        case .disabled:
            list = list.filter { !$0.isEnabled }
        }

        if let trig = triggerFilter {
            list = list.filter { $0.invocationType == trig }
        }

        if !searchText.isEmpty {
            list = list.filter { $0.matches(query: searchText) }
        }

        switch sortOrder {
        case .nameAsc:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .recentlyModified:
            return list.sorted { $0.lastModified > $1.lastModified }
        case .triggerType:
            return list.sorted { $0.kind.rawValue < $1.kind.rawValue }
        }
    }

    // Counts per category
    public var totalItemsCount: Int { items.count }
    public func count(for kind: ComponentKind) -> Int {
        items.filter { $0.kind == kind }.count
    }

    public var activeCount: Int { items.filter { $0.isEnabled }.count }
    public var disabledCount: Int { items.filter { !$0.isEnabled }.count }

    public func reloadSources() {
        var baseSources = SkillSource.defaultSources()
        for path in customWorkspacePaths {
            let url = URL(fileURLWithPath: path)
            baseSources.append(contentsOf: SkillSource.workspaceSource(for: url))
        }
        self.sources = baseSources
        updateFileWatcher()
    }

    public func refreshSkills() async {
        isLoading = true
        let discovered = await stackDiscoveryService.discoverAll(in: sources)
        self.items = discovered

        if let currentId = selectedItemId, !items.contains(where: { $0.id == currentId }) {
            selectedItemId = items.first?.id
        } else if selectedItemId == nil {
            selectedItemId = items.first?.id
        }

        isLoading = false
    }

    public func toggleItem(_ item: StackItem) {
        guard let source = sources.first(where: { $0.id == item.sourceId }) else {
            errorMessage = "Source '\(item.sourceName)' could not be found."
            return
        }

        do {
            let updated = try stackManagerService.toggleItem(item: item, source: source)
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
                selectedItemId = updated.id
            }
        } catch {
            errorMessage = "Failed to toggle item: \(error.localizedDescription)"
        }
    }

    @discardableResult
    public func saveItem(_ item: StackItem, name: String, description: String, frontmatter: [String: String], content: String) -> Bool {
        do {
            let updated = try stackManagerService.saveItem(
                item: item,
                name: name,
                description: description,
                frontmatter: frontmatter,
                content: content
            )
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
            return true
        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
            return false
        }
    }

    public func resetFilters() {
        searchText = ""
        selectedKind = nil
        selectedSourceId = nil
        statusFilter = .all
        triggerFilter = nil
    }

    public func toggleInvocationMode(_ item: StackItem) {
        var fm = item.frontmatter
        let newType: InvocationTriggerType = (item.invocationType == .auto) ? .manual : .auto
        if newType == .manual {
            fm["invocation"] = "manual"
            fm["auto_trigger"] = "false"
        } else {
            fm.removeValue(forKey: "invocation")
            fm.removeValue(forKey: "auto_trigger")
        }

        saveItem(item, name: item.name, description: item.description, frontmatter: fm, content: item.content)
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].invocationType = newType
        }
    }

    public func deleteItem(_ item: StackItem) {
        do {
            try stackManagerService.deleteItem(item: item)
            items.removeAll(where: { $0.id == item.id })
            if selectedItemId == item.id {
                selectedItemId = items.first?.id
            }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    public func addWorkspaceFolder(url: URL) {
        let path = url.path
        if !customWorkspacePaths.contains(path) {
            customWorkspacePaths.append(path)
            UserDefaults.standard.set(customWorkspacePaths, forKey: workspaceDefaultsKey)
            reloadSources()
            Task {
                await refreshSkills()
            }
        }
    }

    public func removeWorkspace(path: String) {
        customWorkspacePaths.removeAll(where: { $0 == path })
        UserDefaults.standard.set(customWorkspacePaths, forKey: workspaceDefaultsKey)
        reloadSources()
        Task {
            await refreshSkills()
        }
    }

    private func loadSavedWorkspaces() {
        if let saved = UserDefaults.standard.stringArray(forKey: workspaceDefaultsKey) {
            self.customWorkspacePaths = saved
        } else if let legacy = UserDefaults.standard.stringArray(forKey: legacyWorkspaceDefaultsKey) {
            self.customWorkspacePaths = legacy
        }
    }

    private func updateFileWatcher() {
        var pathsToWatch: [String] = []
        for src in sources {
            let base = src.activeDirectoryURL.deletingLastPathComponent()
            pathsToWatch.append(base.path)
        }
        watcherService.startWatching(paths: pathsToWatch) { [weak self] in
            Task { @MainActor in
                await self?.refreshSkills()
            }
        }
    }
}
