import SwiftUI

public enum StackDetailTab: String, CaseIterable, Identifiable {
    case editor = "Instructions & Content"
    case metadata = "Metadata & Attributes"
    case files = "Package Files"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .editor: return "pencil.line"
        case .metadata: return "slider.horizontal.3"
        case .files: return "folder"
        }
    }
}

public struct SkillDetailView: View {
    @Bindable var appState: AppState
    public let item: StackItem

    @State private var selectedTab: StackDetailTab = .editor
    @State private var editName: String = ""
    @State private var editDescription: String = ""
    @State private var editContent: String = ""
    @State private var copiedPromptToast = false
    @State private var showSavedNotification = false

    public init(appState: AppState, item: StackItem) {
        self.appState = appState
        self.item = item
    }

    public init(appState: AppState, skill: Skill) {
        self.appState = appState
        self.item = StackItem(
            id: skill.id,
            kind: .skill,
            name: skill.name,
            description: skill.description,
            sourceId: skill.sourceId,
            sourceKind: skill.sourceKind,
            sourceName: skill.sourceName,
            isEnabled: skill.isEnabled,
            fileURL: skill.skillFileURL,
            directoryURL: skill.directoryURL,
            content: skill.markdownBody,
            frontmatter: skill.frontmatter,
            metadata: ["origin": skill.origin ?? ""],
            invocationType: .auto,
            lastModified: skill.lastModified,
            files: skill.files
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Header Bar
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            if item.kind == .command {
                                Text("/\(item.name)")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                            } else {
                                Text(item.name)
                                    .font(.system(size: 20, weight: .bold))
                            }

                            KindBadge(kind: item.kind)
                            SourceBadge(kind: item.sourceKind)
                            StatusPill(isEnabled: item.isEnabled)
                        }

                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Quick Toggle Switch
                    HStack(spacing: 8) {
                        Text(item.isEnabled ? "Active" : "Disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle("", isOn: Binding(
                            get: { item.isEnabled },
                            set: { _ in appState.toggleItem(item) }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                }

                // Action Bar
                HStack(spacing: 12) {
                    if item.kind == .command {
                        ActionIconButton(
                            icon: copiedPromptToast ? "checkmark" : "terminal",
                            title: copiedPromptToast ? "Copied!" : "Copy /\(item.name)",
                            tint: copiedPromptToast ? .green : .blue
                        ) {
                            ShellLauncher.copyToClipboard("/\(item.name)")
                            copiedPromptToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedPromptToast = false
                            }
                        }
                    } else {
                        ActionIconButton(
                            icon: copiedPromptToast ? "checkmark" : "doc.on.clipboard",
                            title: copiedPromptToast ? "Copied!" : "Copy Name / Prompt",
                            tint: copiedPromptToast ? .green : .accentColor
                        ) {
                            let prompt = "Use \(item.name): \(item.description)"
                            ShellLauncher.copyToClipboard(prompt)
                            copiedPromptToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedPromptToast = false
                            }
                        }
                    }

                    if let targetURL = item.fileURL ?? item.directoryURL {
                        ActionIconButton(icon: "folder", title: "Finder", tint: .secondary) {
                            ShellLauncher.revealInFinder(url: targetURL)
                        }
                    }

                    Spacer()

                    Button {
                        performSave()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showSavedNotification ? "checkmark.circle.fill" : "square.and.arrow.down")
                            Text(showSavedNotification ? "Saved!" : "Save Changes")
                        }
                        .frame(minWidth: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(showSavedNotification ? .green : .accentColor)
                }
            }
            .padding(16)
            .background(Theme.sidebarBackground)

            Divider()

            // Nature Callout Banner
            if item.kind == .command {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.blue)
                    Text("Slash Command: Manually invoked in chat using")
                        .font(.caption)
                    Text("/\(item.name)")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.08))
            } else if item.kind == .skill {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.automatic.fill")
                        .foregroundColor(.green)
                    Text("Autonomous Skill: Automatically loaded by Claude/Codex when your prompt matches the skill description.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.08))
            }

            Divider()

            // Custom Segmented Tab Bar
            HStack(spacing: 12) {
                ForEach(availableTabs) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                            if tab == .files && !item.files.isEmpty {
                                Text("(\(item.files.count))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Tab Content
            switch selectedTab {
            case .editor:
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("Name", text: $editName)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("Description", text: $editDescription)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

                    Divider()

                    MacTextView(text: $editContent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

            case .metadata:
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if !item.frontmatter.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("YAML Frontmatter")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)

                                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                                    ForEach(item.frontmatter.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                                        GridRow {
                                            Text(k)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                            Text(v)
                                                .font(.system(size: 12, design: .monospaced))
                                                .textSelection(.enabled)
                                        }
                                    }
                                }
                            }
                            .cardContainer()
                        }

                        if !item.metadata.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Component Configuration")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)

                                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                                    ForEach(item.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                                        GridRow {
                                            Text(k)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                            Text(v)
                                                .font(.system(size: 12, design: .monospaced))
                                                .textSelection(.enabled)
                                        }
                                    }
                                }
                            }
                            .cardContainer()
                        }
                    }
                    .padding(16)
                }

            case .files:
                if let dir = item.directoryURL {
                    SkillFilesView(skill: Skill(
                        id: item.id,
                        directoryName: dir.lastPathComponent,
                        name: item.name,
                        sourceId: item.sourceId,
                        sourceKind: item.sourceKind,
                        sourceName: item.sourceName,
                        directoryURL: dir,
                        skillFileURL: item.fileURL ?? dir.appendingPathComponent("SKILL.md"),
                        isEnabled: item.isEnabled,
                        rawContent: item.content,
                        frontmatter: item.frontmatter,
                        markdownBody: item.content,
                        triggerAnalysis: SkillTriggerAnalysis.analyze(name: item.name, frontmatter: item.frontmatter, markdownBody: item.content),
                        lastModified: item.lastModified,
                        files: item.files
                    ))
                } else {
                    Text("No file bundle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadItemData()
        }
        .onChange(of: item.id) { _, _ in
            loadItemData()
        }
    }

    private var availableTabs: [StackDetailTab] {
        if !item.files.isEmpty && item.files.count > 1 {
            return StackDetailTab.allCases
        }
        return [.editor, .metadata]
    }

    private func loadItemData() {
        editName = item.name
        editDescription = item.description
        editContent = item.content
    }

    private func performSave() {
        appState.saveItem(item, name: editName, description: editDescription, frontmatter: item.frontmatter, content: editContent)
        withAnimation {
            showSavedNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedNotification = false
            }
        }
    }
}
