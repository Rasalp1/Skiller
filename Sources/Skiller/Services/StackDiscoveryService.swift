import Foundation

public final class StackDiscoveryService: Sendable {
    private var fileManager: FileManager { FileManager.default }

    public init() {}

    public func discoverAll(in sources: [SkillSource]) async -> [StackItem] {
        var allItems: [StackItem] = []

        for source in sources {
            let baseDir = source.activeDirectoryURL.deletingLastPathComponent()

            // 1. Skills
            allItems.append(contentsOf: discoverSkills(source: source))

            // 2. Agents
            allItems.append(contentsOf: discoverAgents(baseDir: baseDir, source: source))

            // 3. Commands
            allItems.append(contentsOf: discoverCommands(baseDir: baseDir, source: source))

            // 4. Rules
            allItems.append(contentsOf: discoverRules(baseDir: baseDir, source: source))

            // 5. MCP Servers
            allItems.append(contentsOf: discoverMCPServers(baseDir: baseDir, source: source))

            // 6. Hooks & Plugins
            allItems.append(contentsOf: discoverHooksAndPlugins(baseDir: baseDir, source: source))
        }

        return allItems.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - 1. Skills
    private func discoverSkills(source: SkillSource) -> [StackItem] {
        var list: [StackItem] = []
        let activeURL = source.activeDirectoryURL
        let disabledURL = source.disabledDirectoryURL

        list.append(contentsOf: loadSkillsFromDir(url: activeURL, source: source, isEnabled: true))
        list.append(contentsOf: loadSkillsFromDir(url: disabledURL, source: source, isEnabled: false))
        return list
    }

    private func loadSkillsFromDir(url: URL, source: SkillSource, isEnabled: Bool) -> [StackItem] {
        guard fileManager.fileExists(atPath: url.path),
              let entries = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        var results: [StackItem] = []
        for entry in entries {
            if let skill = Skill.load(from: entry, source: source, isEnabled: isEnabled) {
                let isExplicitManual = skill.frontmatter["invocation"] == "manual" || skill.frontmatter["auto_trigger"] == "false"
                let invocType: InvocationTriggerType = isExplicitManual ? .manual : skill.triggerAnalysis.triggerType

                results.append(StackItem(
                    id: skill.id,
                    kind: .skill,
                    name: skill.name,
                    description: skill.description,
                    sourceId: source.id,
                    sourceKind: source.kind,
                    sourceName: source.name,
                    isEnabled: isEnabled,
                    fileURL: skill.skillFileURL,
                    directoryURL: skill.directoryURL,
                    content: skill.markdownBody,
                    frontmatter: skill.frontmatter,
                    metadata: ["origin": skill.origin ?? ""],
                    invocationType: invocType,
                    lastModified: skill.lastModified,
                    files: skill.files
                ))
            }
        }
        return results
    }

    // MARK: - 2. Agents
    private func discoverAgents(baseDir: URL, source: SkillSource) -> [StackItem] {
        var list: [StackItem] = []
        let activeDir = baseDir.appendingPathComponent("agents")
        let disabledDir = baseDir.appendingPathComponent("agents-disabled")

        list.append(contentsOf: loadMarkdownItems(url: activeDir, kind: .agent, source: source, isEnabled: true))
        list.append(contentsOf: loadMarkdownItems(url: disabledDir, kind: .agent, source: source, isEnabled: false))
        return list
    }

    // MARK: - 3. Commands
    private func discoverCommands(baseDir: URL, source: SkillSource) -> [StackItem] {
        var list: [StackItem] = []
        let activeDir = baseDir.appendingPathComponent("commands")
        let disabledDir = baseDir.appendingPathComponent("commands-disabled")

        list.append(contentsOf: loadMarkdownItems(url: activeDir, kind: .command, source: source, isEnabled: true))
        list.append(contentsOf: loadMarkdownItems(url: disabledDir, kind: .command, source: source, isEnabled: false))
        return list
    }

    // MARK: - 4. Rules
    private func discoverRules(baseDir: URL, source: SkillSource) -> [StackItem] {
        var list: [StackItem] = []
        let activeDir = baseDir.appendingPathComponent("rules")
        let disabledDir = baseDir.appendingPathComponent("rules-disabled")

        list.append(contentsOf: loadMarkdownItems(url: activeDir, kind: .rule, source: source, isEnabled: true))
        list.append(contentsOf: loadMarkdownItems(url: disabledDir, kind: .rule, source: source, isEnabled: false))

        // Check for standalone GEMINI.md or AGENTS.md
        let standaloneNames = ["GEMINI.md", "AGENTS.md", "CLAUDE.md"]
        for name in standaloneNames {
            let u = baseDir.appendingPathComponent(name)
            if fileManager.fileExists(atPath: u.path), let content = try? String(contentsOf: u, encoding: .utf8) {
                let parsed = FrontmatterParser.parse(content)
                list.append(StackItem(
                    id: "\(source.id):rule:\(name)",
                    kind: .rule,
                    name: name,
                    description: "Global instructions and project behavioral rules.",
                    sourceId: source.id,
                    sourceKind: source.kind,
                    sourceName: source.name,
                    isEnabled: true,
                    fileURL: u,
                    directoryURL: baseDir,
                    content: parsed.body,
                    frontmatter: parsed.attributes,
                    metadata: ["file": name],
                    invocationType: .auto,
                    lastModified: (try? fileManager.attributesOfItem(atPath: u.path)[.modificationDate] as? Date) ?? Date()
                ))
            }
        }

        return list
    }

    // MARK: - 5. MCP Servers
    private func discoverMCPServers(baseDir: URL, source: SkillSource) -> [StackItem] {
        var list: [StackItem] = []
        let candidates = [
            baseDir.appendingPathComponent("mcp-configs/mcp-servers.json"),
            baseDir.appendingPathComponent("mcp.json"),
            baseDir.appendingPathComponent("mcp_config.json")
        ]

        for fileURL in candidates {
            guard fileManager.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            let servers = (json["mcpServers"] as? [String: [String: Any]]) ?? (json["servers"] as? [String: [String: Any]]) ?? [:]

            for (serverName, config) in servers {
                let cmd = config["command"] as? String ?? ""
                let args = (config["args"] as? [String])?.joined(separator: " ") ?? ""
                let desc = config["description"] as? String ?? "MCP Tool Server (\(cmd) \(args))"
                let isDisabled = (config["disabled"] as? Bool) ?? false

                var meta: [String: String] = [
                    "command": cmd,
                    "args": args,
                    "configFile": fileURL.lastPathComponent
                ]
                if let env = config["env"] as? [String: String] {
                    meta["envKeys"] = env.keys.joined(separator: ", ")
                }

                var safeConfig = config
                if let env = config["env"] as? [String: Any] {
                    safeConfig["env"] = Dictionary(uniqueKeysWithValues: env.keys.map { ($0, "<redacted>") })
                }
                let contentFormatted = (try? String(data: JSONSerialization.data(withJSONObject: safeConfig, options: .prettyPrinted), encoding: .utf8)) ?? "{}"

                list.append(StackItem(
                    id: "\(source.id):mcp:\(serverName)",
                    kind: .mcpServer,
                    name: serverName,
                    description: desc,
                    sourceId: source.id,
                    sourceKind: source.kind,
                    sourceName: source.name,
                    isEnabled: !isDisabled,
                    fileURL: fileURL,
                    directoryURL: fileURL.deletingLastPathComponent(),
                    content: contentFormatted,
                    frontmatter: [:],
                    metadata: meta,
                    invocationType: .auto,
                    lastModified: (try? fileManager.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date) ?? Date()
                ))
            }
        }
        return list
    }

    // MARK: - 6. Hooks & Plugins
    private func discoverHooksAndPlugins(baseDir: URL, source: SkillSource) -> [StackItem] {
        var list: [StackItem] = []

        // Hooks
        let hooksJSONURL = baseDir.appendingPathComponent("hooks/hooks.json")
        if fileManager.fileExists(atPath: hooksJSONURL.path),
           let data = try? Data(contentsOf: hooksJSONURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let hooks = json["hooks"] as? [String: Any] {

            for (eventName, hookEntries) in hooks {
                if let arr = hookEntries as? [[String: Any]] {
                    for (idx, entry) in arr.enumerated() {
                        let idStr = (entry["id"] as? String) ?? "\(eventName)-\(idx + 1)"
                        let desc = (entry["description"] as? String) ?? "Hook for event '\(eventName)'"
                        let matcher = (entry["matcher"] as? String) ?? "Any"
                        let entryContent = (try? String(data: JSONSerialization.data(withJSONObject: entry, options: .prettyPrinted), encoding: .utf8)) ?? "{}"

                        list.append(StackItem(
                            id: "\(source.id):hook:\(idStr)",
                            kind: .hook,
                            name: idStr,
                            description: desc,
                            sourceId: source.id,
                            sourceKind: source.kind,
                            sourceName: source.name,
                            isEnabled: true,
                            fileURL: hooksJSONURL,
                            directoryURL: hooksJSONURL.deletingLastPathComponent(),
                            content: entryContent,
                            frontmatter: [:],
                            metadata: ["event": eventName, "matcher": matcher, "type": "Hook"],
                            invocationType: .auto,
                            lastModified: (try? fileManager.attributesOfItem(atPath: hooksJSONURL.path)[.modificationDate] as? Date) ?? Date()
                        ))
                    }
                }
            }
        }

        // Plugins
        let pluginsDir = baseDir.appendingPathComponent("plugins")
        if fileManager.fileExists(atPath: pluginsDir.path),
           let entries = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {

            for pURL in entries {
                let pName = pURL.lastPathComponent
                if pName == "cache" || pName == "data" || pName.hasPrefix(".") { continue }

                let pluginJsonURL = pURL.appendingPathComponent("plugin.json")
                var desc = "Plugin package '\(pName)'"
                var version = "1.0.0"
                if let pData = try? Data(contentsOf: pluginJsonURL),
                   let pJson = try? JSONSerialization.jsonObject(with: pData) as? [String: Any] {
                    desc = (pJson["description"] as? String) ?? desc
                    version = (pJson["version"] as? String) ?? version
                }

                list.append(StackItem(
                    id: "\(source.id):plugin:\(pName)",
                    kind: .hook,
                    name: pName,
                    description: desc,
                    sourceId: source.id,
                    sourceKind: source.kind,
                    sourceName: source.name,
                    isEnabled: true,
                    fileURL: fileManager.fileExists(atPath: pluginJsonURL.path) ? pluginJsonURL : nil,
                    directoryURL: pURL,
                    content: (try? String(contentsOf: pluginJsonURL, encoding: .utf8)) ?? "# Plugin \(pName)",
                    frontmatter: [:],
                    metadata: ["version": version, "type": "Plugin"],
                    invocationType: .auto,
                    lastModified: (try? fileManager.attributesOfItem(atPath: pURL.path)[.modificationDate] as? Date) ?? Date()
                ))
            }
        }

        return list
    }

    // Helper for loading .md files in directory
    private func loadMarkdownItems(url: URL, kind: ComponentKind, source: SkillSource, isEnabled: Bool) -> [StackItem] {
        guard fileManager.fileExists(atPath: url.path),
              let entries = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }

        var results: [StackItem] = []
        for fileURL in entries {
            let filename = fileURL.lastPathComponent
            let itemName = (filename as NSString).deletingPathExtension

            guard let rawContent = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            let parsed = FrontmatterParser.parse(rawContent)
            let name = parsed.name ?? itemName
            let desc = parsed.description ?? "Custom \(kind.singularName)"

            var meta = parsed.attributes
            if let tools = parsed.attributes["tools"] { meta["tools"] = tools }
            if let model = parsed.attributes["model"] { meta["model"] = model }

            let modDate = (try? fileManager.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date) ?? Date()

            let isExplicitManual = parsed.attributes["invocation"] == "manual" || parsed.attributes["auto_trigger"] == "false" || kind == .command
            let invocType: InvocationTriggerType = isExplicitManual ? .manual : .auto

            results.append(StackItem(
                id: "\(source.id):\(kind.rawValue):\(isEnabled ? "active" : "disabled"):\(filename)",
                kind: kind,
                name: name,
                description: desc,
                sourceId: source.id,
                sourceKind: source.kind,
                sourceName: source.name,
                isEnabled: isEnabled,
                fileURL: fileURL,
                directoryURL: fileURL.deletingLastPathComponent(),
                content: parsed.body,
                frontmatter: parsed.attributes,
                metadata: meta,
                invocationType: invocType,
                lastModified: modDate
            ))
        }
        return results
    }
}
