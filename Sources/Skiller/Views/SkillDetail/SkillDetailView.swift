import SwiftUI
import AppKit

public enum StackDetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case instructions = "Instructions"
    case files = "Files"
    case metadata = "Info"
    public var id: String { rawValue }
}

public struct SkillDetailView: View {
    @Bindable var appState: AppState
    public let item: StackItem
    @State private var selectedTab: StackDetailTab = .overview
    @State private var isEditing = false
    @State private var copiedPrompt = false
    @State private var copyResetTask: Task<Void, Never>?

    public init(appState: AppState, item: StackItem) {
        self.appState = appState
        self.item = item
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            HStack(spacing: 24) {
                ForEach(availableTabs) { tab in
                    Button { selectedTab = tab } label: {
                        VStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Text(tab.rawValue)
                                if tab == .files {
                                    Text("\(item.files.count)")
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }
                            .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? Theme.accent : .secondary)
                            Rectangle().fill(selectedTab == tab ? Theme.accent : .clear).frame(height: 2)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.pageInset).padding(.top, 16)
            Divider()
            Group {
                switch selectedTab {
                case .overview: overview
                case .instructions:
                    if item.isEditableDocument {
                        MarkdownDocumentView(content: item.content)
                    } else {
                        MacTextView(text: .constant(item.content), isEditable: false)
                    }
                case .files: PackageFilesView(files: item.files, directoryURL: item.directoryURL)
                case .metadata: information
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                Text(item.fileURL?.lastPathComponent ?? "Configuration").lineLimit(1)
                Spacer()
                Text("Modified \(item.lastModified.formatted(date: .abbreviated, time: .omitted))")
            }
            .font(.system(size: 10)).foregroundStyle(.secondary)
            .padding(.horizontal, Theme.pageInset).padding(.vertical, 12)
        }
        .background(Theme.canvas)
        .sheet(isPresented: $isEditing) {
            ComponentEditorView(appState: appState, item: item)
        }
        .onDisappear { copyResetTask?.cancel() }
        .onChange(of: item.files.isEmpty) { _, isEmpty in
            if isEmpty && selectedTab == .files { selectedTab = .overview }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label(item.sourceName, systemImage: item.sourceKind.icon)
                Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                Text(item.kind.singularName)
                Spacer()
                Menu {
                    Button("Copy Name") { ShellLauncher.copyToClipboard(item.name) }
                    if let url = item.fileURL ?? item.directoryURL {
                        Button("Copy Path") { ShellLauncher.copyToClipboard(url.path) }
                        Button("Reveal in Finder") { ShellLauncher.revealInFinder(url: url) }
                        Button("Open in Default App") { NSWorkspace.shared.open(url) }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 16))
                }
                .menuStyle(.borderlessButton).fixedSize().help("Component actions")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 14) {
                ComponentIcon(kind: item.kind, size: 48)
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.kind == .command ? "/\(item.name)" : item.name)
                        .font(.system(size: 25, weight: .bold)).textSelection(.enabled)
                        // Unbounded wrapping inflates NavigationSplitView's minimum height
                        // when AppKit measures the title at a narrow proposed width.
                        .lineLimit(2).truncationMode(.middle)
                        .help(item.name)
                    HStack(spacing: 6) {
                        Circle().fill(item.isEnabled ? Color.green : Color.secondary).frame(width: 6, height: 6)
                        Text(item.isEnabled ? "Active" : "Disabled")
                        Text("·")
                        Text(item.kind.singularName)
                    }
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button(action: copyInvocation) {
                    Label(copiedPrompt ? "Copied" : "Copy prompt", systemImage: copiedPrompt ? "checkmark" : "doc.on.clipboard")
                }
                .buttonStyle(.borderedProminent)
                if item.isEditableDocument {
                    Button { isEditing = true } label: { Label("Edit", systemImage: "pencil") }
                        .buttonStyle(.bordered).keyboardShortcut("e", modifiers: .command)
                }
                Spacer(minLength: 6)
                if item.kind != .hook {
                    Toggle("Enabled", isOn: Binding(
                        get: { item.isEnabled }, set: { _ in appState.toggleItem(item) }
                    ))
                    .toggleStyle(.switch).controlSize(.small)
                    .font(.system(size: 11)).help("Enable or disable this component")
                }
            }
            .controlSize(.regular)
        }
        .padding(Theme.pageInset).padding(.bottom, 2)
    }

    private var overview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeading("About")
                    Text(item.description.isEmpty ? "This component doesn’t include a description. Open its instructions to learn more." : item.description)
                        .font(.system(size: 14)).lineSpacing(5).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if item.kind == .skill || item.kind == .command {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: item.invocationType == .manual ? "hand.tap" : "bolt")
                                .foregroundStyle(Theme.accent)
                            Text(invocationTitle).font(.system(size: 13, weight: .semibold))
                        }
                        Text(invocationExplanation).font(.system(size: 12)).foregroundStyle(.secondary).lineSpacing(4)
                        Divider()
                        HStack(alignment: .top, spacing: 12) {
                            Text(invocationPrompt).font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            Button(action: copyInvocation) {
                                Image(systemName: copiedPrompt ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.borderless).help("Copy invocation prompt")
                        }
                    }
                    .padding(18)
                    .background(Theme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.subtleBorder))
                }
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeading("At a glance")
                    propertyRow("Source", value: item.sourceName)
                    Divider()
                    propertyRow("Component", value: item.kind.singularName)
                    if let model = item.model, !model.isEmpty {
                        Divider()
                        propertyRow("Model", value: model)
                    }
                    if !item.files.isEmpty {
                        Divider()
                        propertyRow("Package", value: "\(item.files.count) files and folders")
                    }
                    if let origin = item.origin, !origin.isEmpty {
                        Divider()
                        propertyRow("Origin", value: origin)
                    }
                }
                if let url = item.fileURL ?? item.directoryURL {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeading("Location")
                        Button { ShellLauncher.revealInFinder(url: url) } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "folder").foregroundStyle(Theme.accent)
                                Text((url.path as NSString).abbreviatingWithTildeInPath)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain).help("Reveal in Finder")
                    }
                }
            }
            .padding(Theme.pageInset).frame(maxWidth: 780, alignment: .leading).frame(maxWidth: .infinity)
        }
    }

    private var information: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                metadataSection("Frontmatter", values: item.frontmatter)
                metadataSection("Configuration", values: item.metadata)
                if item.frontmatter.isEmpty && item.metadata.isEmpty {
                    EmptyLibraryView(icon: "info.circle", title: "No additional information",
                                     message: "This component doesn’t define any metadata.")
                }
            }
            .padding(Theme.pageInset)
        }
    }

    @ViewBuilder private func metadataSection(_ title: String, values: [String: String]) -> some View {
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(title)
                ForEach(values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(key).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                        Text(value).font(.system(size: 13)).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                }
            }
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title).font(.system(size: 13, weight: .semibold))
    }

    private func propertyRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            Text(title).foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
            Text(value).textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.system(size: 12))
    }

    private var availableTabs: [StackDetailTab] {
        item.files.isEmpty ? [.overview, .instructions, .metadata] : StackDetailTab.allCases
    }

    private var invocationTitle: String {
        if item.kind == .command { return "Ready when you call it" }
        switch item.invocationType {
        case .auto: return "Available for automatic invocation"
        case .manual: return "Invoked on request"
        case .hybrid: return "Automatic or on request"
        }
    }

    private var invocationExplanation: String {
        if item.kind == .command { return "Paste this slash command into your agent’s chat to invoke it." }
        switch item.invocationType {
        case .auto: return "Your agent can use this skill when your request matches its description. You can also ask for it directly."
        case .manual: return "Ask your agent to use this skill explicitly. Its metadata marks it for manual invocation."
        case .hybrid: return "Your agent may select this skill from context, or you can request it explicitly."
        }
    }

    private var invocationPrompt: String {
        item.kind == .command ? "/\(item.name)" : "Use \(item.name): \(item.description)"
    }

    private func copyInvocation() {
        ShellLauncher.copyToClipboard(invocationPrompt)
        copiedPrompt = true
        copyResetTask?.cancel()
        copyResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            copiedPrompt = false
        }
    }
}
