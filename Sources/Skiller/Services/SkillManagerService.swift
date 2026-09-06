import Foundation

public enum SkillManagerError: LocalizedError, Sendable {
    case directoryNotFound(String)
    case destinationAlreadyExists(String)
    case fileWriteFailed(String)
    case sourceNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let msg): return "Directory not found: \(msg)"
        case .destinationAlreadyExists(let msg): return "Destination already exists: \(msg)"
        case .fileWriteFailed(let msg): return "Failed to write file: \(msg)"
        case .sourceNotFound(let msg): return "Source not found: \(msg)"
        }
    }
}

public final class SkillManagerService: Sendable {
    private var fileManager: FileManager { FileManager.default }

    public init() {}

    public func toggleSkill(skill: Skill, source: SkillSource) throws -> Skill {
        let currentURL = skill.directoryURL
        let targetParentURL = skill.isEnabled ? source.disabledDirectoryURL : source.activeDirectoryURL

        // Create target parent directory if it does not exist
        if !fileManager.fileExists(atPath: targetParentURL.path) {
            try fileManager.createDirectory(at: targetParentURL, withIntermediateDirectories: true)
        }

        let destinationURL = targetParentURL.appendingPathComponent(skill.directoryName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            // If already exists at destination, generate a backup timestamp or error
            let backupName = "\(skill.directoryName)-\(Int(Date().timeIntervalSince1970))"
            let altURL = targetParentURL.appendingPathComponent(backupName)
            try fileManager.moveItem(at: currentURL, to: altURL)
            guard let updated = Skill.load(from: altURL, source: source, isEnabled: !skill.isEnabled) else {
                throw SkillManagerError.directoryNotFound(altURL.path)
            }
            return updated
        }

        try fileManager.moveItem(at: currentURL, to: destinationURL)

        guard let updated = Skill.load(from: destinationURL, source: source, isEnabled: !skill.isEnabled) else {
            throw SkillManagerError.directoryNotFound(destinationURL.path)
        }
        return updated
    }

    public func saveSkill(
        skill: Skill,
        frontmatter: [String: String],
        markdownBody: String
    ) throws -> Skill {
        let serialized = FrontmatterParser.serialize(frontmatter: frontmatter, body: markdownBody)
        try serialized.write(to: skill.skillFileURL, atomically: true, encoding: .utf8)

        let parsed = FrontmatterParser.parse(serialized)
        let skillName = parsed.name ?? skill.directoryName
        let triggerAnalysis = SkillTriggerAnalysis.analyze(
            name: skillName,
            frontmatter: parsed.attributes,
            markdownBody: parsed.body
        )

        var updated = skill
        updated.name = skillName
        updated.rawContent = serialized
        updated.frontmatter = parsed.attributes
        updated.markdownBody = parsed.body
        updated.triggerAnalysis = triggerAnalysis
        updated.lastModified = Date()

        return updated
    }

    public func cloneSkill(
        skill: Skill,
        to targetSource: SkillSource,
        as newName: String? = nil
    ) throws -> Skill {
        let targetDirectoryName = newName ?? skill.directoryName
        let targetDir = targetSource.activeDirectoryURL.appendingPathComponent(targetDirectoryName)

        if !fileManager.fileExists(atPath: targetSource.activeDirectoryURL.path) {
            try fileManager.createDirectory(at: targetSource.activeDirectoryURL, withIntermediateDirectories: true)
        }

        if fileManager.fileExists(atPath: targetDir.path) {
            throw SkillManagerError.destinationAlreadyExists(targetDir.path)
        }

        try fileManager.copyItem(at: skill.directoryURL, to: targetDir)

        // If new name was supplied, update SKILL.md name attribute
        let skillMdURL = targetDir.appendingPathComponent("SKILL.md")
        if fileManager.fileExists(atPath: skillMdURL.path), let content = try? String(contentsOf: skillMdURL, encoding: .utf8) {
            var parsed = FrontmatterParser.parse(content)
            if let customName = newName {
                parsed.attributes["name"] = customName
                let serialized = FrontmatterParser.serialize(frontmatter: parsed.attributes, body: parsed.body)
                try? serialized.write(to: skillMdURL, atomically: true, encoding: .utf8)
            }
        }

        guard let loaded = Skill.load(from: targetDir, source: targetSource, isEnabled: true) else {
            throw SkillManagerError.directoryNotFound(targetDir.path)
        }
        return loaded
    }

    public func createNewSkill(
        in source: SkillSource,
        name: String,
        description: String,
        origin: String = "Custom",
        initialBody: String? = nil
    ) throws -> Skill {
        let dirName = name.lowercased().replacingOccurrences(of: " ", with: "-")
        let targetDir = source.activeDirectoryURL.appendingPathComponent(dirName)

        if !fileManager.fileExists(atPath: source.activeDirectoryURL.path) {
            try fileManager.createDirectory(at: source.activeDirectoryURL, withIntermediateDirectories: true)
        }

        if fileManager.fileExists(atPath: targetDir.path) {
            throw SkillManagerError.destinationAlreadyExists(targetDir.path)
        }

        try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let body = initialBody ?? """
        # \(name)

        ## Overview
        \(description)

        ## When to use
        - Use when the user asks for \(name).
        - Trigger when working on related tasks.

        ## Instructions
        1. Step 1
        2. Step 2
        """

        let frontmatter: [String: String] = [
            "name": name,
            "description": description,
            "origin": origin
        ]

        let serialized = FrontmatterParser.serialize(frontmatter: frontmatter, body: body)
        let skillMdURL = targetDir.appendingPathComponent("SKILL.md")
        try serialized.write(to: skillMdURL, atomically: true, encoding: .utf8)

        guard let skill = Skill.load(from: targetDir, source: source, isEnabled: true) else {
            throw SkillManagerError.directoryNotFound(targetDir.path)
        }
        return skill
    }

    public func deleteSkill(skill: Skill) throws {
        if fileManager.fileExists(atPath: skill.directoryURL.path) {
            try fileManager.removeItem(at: skill.directoryURL)
        }
    }
}
