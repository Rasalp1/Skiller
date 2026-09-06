import Foundation

public final class SkillDiscoveryService: Sendable {
    private var fileManager: FileManager { FileManager.default }

    public init() {}

    public func discoverSkills(in sources: [SkillSource]) async -> [Skill] {
        var allSkills: [Skill] = []

        for source in sources {
            let activeSkills = discoverInDirectory(url: source.activeDirectoryURL, source: source, isEnabled: true)
            let disabledSkills = discoverInDirectory(url: source.disabledDirectoryURL, source: source, isEnabled: false)
            allSkills.append(contentsOf: activeSkills)
            allSkills.append(contentsOf: disabledSkills)
        }

        // Sort by name alphabetically by default
        return allSkills.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func discoverInDirectory(url: URL, source: SkillSource, isEnabled: Bool) -> [Skill] {
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var skills: [Skill] = []
        for itemURL in contents {
            if let skill = Skill.load(from: itemURL, source: source, isEnabled: isEnabled) {
                skills.append(skill)
            }
        }
        return skills
    }
}
