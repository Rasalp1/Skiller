import Foundation

public final class StackManagerService: Sendable {
    private var fileManager: FileManager { FileManager.default }

    public init() {}

    public func toggleItem(item: StackItem, source: SkillSource) throws -> StackItem {
        let baseDir = source.activeDirectoryURL.deletingLastPathComponent()

        switch item.kind {
        case .skill:
            let activeDir = source.activeDirectoryURL
            let disabledDir = source.disabledDirectoryURL
            guard let dirURL = item.directoryURL else { throw SkillManagerError.directoryNotFound("No directory") }
            let targetParent = item.isEnabled ? disabledDir : activeDir

            if !fileManager.fileExists(atPath: targetParent.path) {
                try fileManager.createDirectory(at: targetParent, withIntermediateDirectories: true)
            }
            let destURL = targetParent.appendingPathComponent(dirURL.lastPathComponent)
            try fileManager.moveItem(at: dirURL, to: destURL)

            var updated = item
            updated.isEnabled = !item.isEnabled
            updated.directoryURL = destURL
            updated.fileURL = destURL.appendingPathComponent("SKILL.md")
            return updated

        case .agent, .command, .rule:
            let folderName = item.kind == .agent ? "agents" : (item.kind == .command ? "commands" : "rules")
            let activeDir = baseDir.appendingPathComponent(folderName)
            let disabledDir = baseDir.appendingPathComponent("\(folderName)-disabled")
            let targetParent = item.isEnabled ? disabledDir : activeDir

            if !fileManager.fileExists(atPath: targetParent.path) {
                try fileManager.createDirectory(at: targetParent, withIntermediateDirectories: true)
            }

            guard let fileURL = item.fileURL else { throw SkillManagerError.directoryNotFound("No file") }
            let destURL = targetParent.appendingPathComponent(fileURL.lastPathComponent)
            try fileManager.moveItem(at: fileURL, to: destURL)

            var updated = item
            updated.isEnabled = !item.isEnabled
            updated.fileURL = destURL
            return updated

        case .mcpServer:
            // Toggle disabled flag in JSON configuration
            if let fileURL = item.fileURL,
               let data = try? Data(contentsOf: fileURL),
               var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               var servers = json["mcpServers"] as? [String: [String: Any]] ?? json["servers"] as? [String: [String: Any]] {

                if var srv = servers[item.name] {
                    let newDisabled = item.isEnabled // if currently enabled, disable it
                    srv["disabled"] = newDisabled
                    servers[item.name] = srv
                    if json["mcpServers"] != nil { json["mcpServers"] = servers }
                    if json["servers"] != nil { json["servers"] = servers }

                    let outputData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
                    try outputData.write(to: fileURL)

                    var updated = item
                    updated.isEnabled = !item.isEnabled
                    return updated
                }
            }
            var updated = item
            updated.isEnabled = !item.isEnabled
            return updated

        case .hook:
            var updated = item
            updated.isEnabled = !item.isEnabled
            return updated
        }
    }

    public func saveItem(
        item: StackItem,
        name: String,
        description: String,
        frontmatter: [String: String],
        content: String
    ) throws -> StackItem {
        var updatedFrontmatter = frontmatter
        updatedFrontmatter["name"] = name
        updatedFrontmatter["description"] = description

        let serialized = FrontmatterParser.serialize(frontmatter: updatedFrontmatter, body: content)

        if let fileURL = item.fileURL {
            try serialized.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        var updated = item
        updated.name = name
        updated.description = description
        updated.frontmatter = updatedFrontmatter
        updated.content = content
        updated.lastModified = Date()
        return updated
    }

    public func deleteItem(item: StackItem) throws {
        if item.kind == .skill, let dir = item.directoryURL, fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        } else if let file = item.fileURL, fileManager.fileExists(atPath: file.path) {
            try fileManager.removeItem(at: file)
        }
    }
}
