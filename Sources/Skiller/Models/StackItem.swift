import Foundation

public struct StackItem: Identifiable, Hashable, Sendable {
    public let id: String
    public var kind: ComponentKind
    public var name: String
    public var description: String
    public let sourceId: String
    public let sourceKind: SkillSourceKind
    public let sourceName: String
    public var isEnabled: Bool
    public var fileURL: URL?
    public var directoryURL: URL?
    public var content: String
    public var frontmatter: [String: String]
    public var metadata: [String: String]
    public var invocationType: InvocationTriggerType
    public var lastModified: Date
    public var files: [SkillFileItem]

    public var origin: String? {
        frontmatter["origin"] ?? metadata["origin"]
    }

    public var model: String? {
        frontmatter["model"] ?? metadata["model"]
    }

    public var tools: String? {
        frontmatter["tools"] ?? metadata["tools"]
    }

    public init(
        id: String,
        kind: ComponentKind,
        name: String,
        description: String,
        sourceId: String,
        sourceKind: SkillSourceKind,
        sourceName: String,
        isEnabled: Bool,
        fileURL: URL? = nil,
        directoryURL: URL? = nil,
        content: String,
        frontmatter: [String: String] = [:],
        metadata: [String: String] = [:],
        invocationType: InvocationTriggerType = .auto,
        lastModified: Date = Date(),
        files: [SkillFileItem] = []
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.description = description
        self.sourceId = sourceId
        self.sourceKind = sourceKind
        self.sourceName = sourceName
        self.isEnabled = isEnabled
        self.fileURL = fileURL
        self.directoryURL = directoryURL
        self.content = content
        self.frontmatter = frontmatter
        self.metadata = metadata
        self.invocationType = invocationType
        self.lastModified = lastModified
        self.files = files
    }

    /// Shared provider configuration files must not be serialized as Markdown documents.
    public var isEditableDocument: Bool {
        [.skill, .agent, .command, .rule].contains(kind) && fileURL?.pathExtension.lowercased() == "md"
    }

    /// Matches component content, excluding provider names and parent directory paths.
    public func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        let terms = trimmed.split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return true }

        return terms.allSatisfy { term in
            matchesSingleTerm(term)
        }
    }

    private func matchesSingleTerm(_ term: String) -> Bool {
        // 1. Name
        if name.localizedCaseInsensitiveContains(term) { return true }

        // 2. Description
        if description.localizedCaseInsensitiveContains(term) { return true }

        // 3. Kind (e.g. "Skills", "Skill", "Agents", "Agent", etc.)
        if kind.rawValue.localizedCaseInsensitiveContains(term) ||
           kind.singularName.localizedCaseInsensitiveContains(term) {
            return true
        }

        // 4. Invocation trigger type (e.g. "Auto-Trigger", "Manual Only", "Hybrid")
        if invocationType.rawValue.localizedCaseInsensitiveContains(term) {
            return true
        }

        // 5. Content (instructions, markdown, script, config body)
        if content.localizedCaseInsensitiveContains(term) { return true }

        // 6. Frontmatter keys and values
        for (key, val) in frontmatter {
            if key.localizedCaseInsensitiveContains(term) || val.localizedCaseInsensitiveContains(term) {
                return true
            }
        }

        // 7. Metadata keys and values
        for (key, val) in metadata {
            if key.localizedCaseInsensitiveContains(term) || val.localizedCaseInsensitiveContains(term) {
                return true
            }
        }

        // 8. Attached files (file name and relative path)
        for file in files {
            if file.name.localizedCaseInsensitiveContains(term) ||
               file.relativePath.localizedCaseInsensitiveContains(term) {
                return true
            }
        }

        // 9. File name / directory name component (only the last component to avoid matching provider directories like ~/.claude/ or ~/.codex/)
        if let fileURL = fileURL, fileURL.lastPathComponent.localizedCaseInsensitiveContains(term) {
            return true
        }
        if let dirURL = directoryURL, dirURL.lastPathComponent.localizedCaseInsensitiveContains(term) {
            return true
        }

        return false
    }
}
