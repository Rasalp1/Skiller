import Foundation

public enum InvocationTriggerType: String, Codable, CaseIterable, Identifiable, Sendable {
    case auto = "Auto-Trigger"
    case manual = "Manual Only"
    case hybrid = "Hybrid (Auto & Manual)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .auto: return "bolt.badge.automatic.fill"
        case .manual: return "hand.tap.fill"
        case .hybrid: return "arrow.triangle.merge"
        }
    }

    public var colorName: String {
        switch self {
        case .auto: return "green"
        case .manual: return "blue"
        case .hybrid: return "purple"
        }
    }
}

public struct TriggerCriterion: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let phrase: String
    public let sourceLocation: String // e.g. "Description", "Heading 'When to use'", etc.
    public let confidence: Double
}

public struct SkillTriggerAnalysis: Hashable, Sendable {
    public let triggerType: InvocationTriggerType
    public let score: Double // 0.0 (Pure Manual) to 1.0 (Pure Auto)
    public let criteria: [TriggerCriterion]
    public let manualSlashCommands: [String]
    public let summaryReason: String
    public let suggestedTriggerPrompt: String

    public static func analyze(
        name: String,
        frontmatter: [String: String],
        markdownBody: String
    ) -> SkillTriggerAnalysis {
        var autoSignals: [TriggerCriterion] = []
        var manualSignals: [String] = []

        let desc = frontmatter["description"] ?? ""
        let fullText = desc + "\n" + markdownBody
        let lowerDesc = desc.lowercased()
        let lowerFull = fullText.lowercased()

        // 1. Analyze description for auto-trigger phrases
        let autoPhrases = [
            "use when",
            "trigger when",
            "automatically",
            "activates when",
            "use this skill when",
            "when the user asks",
            "when the user says",
            "when working on",
            "when encountering",
            "when debugging",
            "when modifying",
            "when creating",
            "whenever"
        ]

        for phrase in autoPhrases {
            if lowerDesc.contains(phrase) {
                // Extract sentence containing phrase
                if let sentence = extractSentence(containing: phrase, in: desc) {
                    autoSignals.append(TriggerCriterion(
                        phrase: sentence,
                        sourceLocation: "Frontmatter Description",
                        confidence: 0.95
                    ))
                }
            }
        }

        // 2. Check for explicit trigger headings in markdown body
        let lines = markdownBody.components(separatedBy: .newlines)
        var captureNextLines = false
        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: "#") {
                let lowerHeading = trimmed.lowercased()
                if lowerHeading.contains("when to use") ||
                   lowerHeading.contains("triggers") ||
                   lowerHeading.contains("activation") ||
                   lowerHeading.contains("prerequisites") {
                    captureNextLines = true
                    currentSection = trimmed.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                } else {
                    captureNextLines = false
                }
            } else if captureNextLines && !trimmed.isEmpty && (trimmed.starts(with: "-") || trimmed.starts(with: "*") || trimmed.starts(with: "1.")) {
                autoSignals.append(TriggerCriterion(
                    phrase: trimmed,
                    sourceLocation: "Section '\(currentSection)'",
                    confidence: 0.85
                ))
            }

            // Check for slash commands (e.g. `/diagnose`, `/skill-name`)
            if trimmed.contains("/\(name)") || trimmed.contains("/goal") || trimmed.contains("/grill-me") || trimmed.contains("/learn") {
                manualSignals.append(trimmed)
            }
        }

        // 3. Deduce slash commands
        if manualSignals.isEmpty {
            manualSignals.append("/\(name)")
        }

        // 4. Calculate score & trigger type
        let hasExplicitAutoInDesc = !autoSignals.isEmpty
        let hasExplicitManualTag = lowerFull.contains("manual only") || lowerFull.contains("slash command only") || lowerFull.contains("user invoked only")

        let triggerType: InvocationTriggerType
        let score: Double
        let summaryReason: String

        if hasExplicitManualTag {
            triggerType = .manual
            score = 0.1
            summaryReason = "Explicitly designated for manual or slash command invocation only."
        } else if hasExplicitAutoInDesc && autoSignals.count >= 2 {
            triggerType = .auto
            score = 0.9
            summaryReason = "Strong auto-trigger conditions detected in description and usage guidelines."
        } else if hasExplicitAutoInDesc {
            triggerType = .hybrid
            score = 0.65
            summaryReason = "Auto-invoked when trigger patterns match, but also commonly called via slash command or direct request."
        } else {
            triggerType = .manual
            score = 0.3
            summaryReason = "No explicit auto-invocation conditions specified; typically invoked on user request."
        }

        let primaryPhrase = autoSignals.first?.phrase ?? "Help me with \(name)"
        let suggestedPrompt = "Using the `\(name)` skill: \(primaryPhrase)"

        return SkillTriggerAnalysis(
            triggerType: triggerType,
            score: score,
            criteria: Array(autoSignals.prefix(6)),
            manualSlashCommands: Array(Set(manualSignals)).prefix(3).map { String($0) },
            summaryReason: summaryReason,
            suggestedTriggerPrompt: suggestedPrompt
        )
    }

    private static func extractSentence(containing phrase: String, in text: String) -> String? {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!\n"))
        for s in sentences {
            if s.lowercased().contains(phrase) {
                return s.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}
