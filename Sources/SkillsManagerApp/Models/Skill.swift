import Foundation

public struct SkillFileItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let relativePath: String
    public let url: URL
    public let isDirectory: Bool
    public let sizeInBytes: Int64
}

public struct Skill: Identifiable, Hashable, Sendable {
    public let id: String
    public let directoryName: String
    public var name: String
    public let sourceId: String
    public let sourceKind: SkillSourceKind
    public let sourceName: String
    public var directoryURL: URL
    public var skillFileURL: URL
    public var isEnabled: Bool
    public var rawContent: String
    public var frontmatter: [String: String]
    public var markdownBody: String
    public var triggerAnalysis: SkillTriggerAnalysis
    public var lastModified: Date
    public var files: [SkillFileItem]

    public var description: String {
        frontmatter["description"] ?? ""
    }

    public var origin: String? {
        frontmatter["origin"]
    }

    public var version: String? {
        frontmatter["version"]
    }

    public var author: String? {
        frontmatter["author"]
    }

    public init(
        id: String,
        directoryName: String,
        name: String,
        sourceId: String,
        sourceKind: SkillSourceKind,
        sourceName: String,
        directoryURL: URL,
        skillFileURL: URL,
        isEnabled: Bool,
        rawContent: String,
        frontmatter: [String: String],
        markdownBody: String,
        triggerAnalysis: SkillTriggerAnalysis,
        lastModified: Date,
        files: [SkillFileItem] = []
    ) {
        self.id = id
        self.directoryName = directoryName
        self.name = name
        self.sourceId = sourceId
        self.sourceKind = sourceKind
        self.sourceName = sourceName
        self.directoryURL = directoryURL
        self.skillFileURL = skillFileURL
        self.isEnabled = isEnabled
        self.rawContent = rawContent
        self.frontmatter = frontmatter
        self.markdownBody = markdownBody
        self.triggerAnalysis = triggerAnalysis
        self.lastModified = lastModified
        self.files = files
    }

    public static func load(from directoryURL: URL, source: SkillSource, isEnabled: Bool) -> Skill? {
        let fileManager = FileManager.default
        let directoryName = directoryURL.lastPathComponent

        // Check if directory exists
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }

        // Look for SKILL.md or skill.md or README.md
        let candidates = ["SKILL.md", "skill.md", "README.md"]
        var targetFileURL: URL?
        for candidate in candidates {
            let u = directoryURL.appendingPathComponent(candidate)
            if fileManager.fileExists(atPath: u.path) {
                targetFileURL = u
                break
            }
        }

        guard let skillFileURL = targetFileURL else {
            return nil
        }

        guard let rawContent = try? String(contentsOf: skillFileURL, encoding: .utf8) else {
            return nil
        }

        let parsed = FrontmatterParser.parse(rawContent)
        let skillName = parsed.name ?? directoryName
        let triggerAnalysis = SkillTriggerAnalysis.analyze(
            name: skillName,
            frontmatter: parsed.attributes,
            markdownBody: parsed.body
        )

        let attributes = try? fileManager.attributesOfItem(atPath: skillFileURL.path)
        let modDate = (attributes?[.modificationDate] as? Date) ?? Date()

        // Scan children files (scripts, examples, etc.)
        var fileItems: [SkillFileItem] = []
        if let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let rel = fileURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
                let isSubDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                fileItems.append(SkillFileItem(
                    id: rel,
                    name: fileURL.lastPathComponent,
                    relativePath: rel,
                    url: fileURL,
                    isDirectory: isSubDir,
                    sizeInBytes: Int64(size)
                ))
            }
        }

        let uniqueId = "\(source.id):\(isEnabled ? "active" : "disabled"):\(directoryName)"

        return Skill(
            id: uniqueId,
            directoryName: directoryName,
            name: skillName,
            sourceId: source.id,
            sourceKind: source.kind,
            sourceName: source.name,
            directoryURL: directoryURL,
            skillFileURL: skillFileURL,
            isEnabled: isEnabled,
            rawContent: rawContent,
            frontmatter: parsed.attributes,
            markdownBody: parsed.body,
            triggerAnalysis: triggerAnalysis,
            lastModified: modDate,
            files: fileItems
        )
    }
}
