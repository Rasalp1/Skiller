import Foundation

public struct ParsedFrontmatter: Sendable {
    public var attributes: [String: String]
    public var body: String

    public var name: String? { attributes["name"] }
    public var description: String? { attributes["description"] }
    public var origin: String? { attributes["origin"] }
    public var author: String? { attributes["author"] }
    public var version: String? { attributes["version"] }

    public init(attributes: [String: String] = [:], body: String = "") {
        self.attributes = attributes
        self.body = body
    }
}

public enum FrontmatterParser {
    public static func parse(_ content: String) -> ParsedFrontmatter {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 0 else {
            return ParsedFrontmatter(attributes: [:], body: "")
        }

        // Check if first line begins frontmatter
        let trimmedFirst = lines[0].trimmingCharacters(in: .whitespaces)
        guard trimmedFirst == "---" else {
            return ParsedFrontmatter(attributes: [:], body: content)
        }

        var inFrontmatter = true
        var frontmatterLines: [String] = []
        var bodyLines: [String] = []

        for lineIndex in 1..<lines.count {
            let line = lines[lineIndex]
            if inFrontmatter {
                if line.trimmingCharacters(in: .whitespaces) == "---" {
                    inFrontmatter = false
                } else {
                    frontmatterLines.append(line)
                }
            } else {
                bodyLines.append(line)
            }
        }

        var attributes: [String: String] = [:]
        var currentKey: String?
        var currentValue = ""

        for line in frontmatterLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.starts(with: "#") {
                continue
            }

            if let colonIndex = line.firstIndex(of: ":") {
                // If we were processing a multiline string before, save it
                if let key = currentKey {
                    attributes[key] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
                }

                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                currentKey = key
                currentValue = stripQuotes(value)
            } else if currentKey != nil {
                // Continuation line (e.g. multi-line description)
                currentValue += "\n" + trimmed
            }
        }

        if let key = currentKey {
            attributes[key] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ParsedFrontmatter(
            attributes: attributes,
            body: bodyLines.joined(separator: "\n")
        )
    }

    public static func serialize(frontmatter: [String: String], body: String) -> String {
        guard !frontmatter.isEmpty else {
            return body
        }

        var output = "---\n"
        // Common keys first in nice order
        let keyOrder = ["name", "description", "origin", "author", "version"]
        var handledKeys = Set<String>()

        for key in keyOrder {
            if let val = frontmatter[key] {
                output += "\(key): \(formatValue(val))\n"
                handledKeys.insert(key)
            }
        }

        for (key, val) in frontmatter.sorted(by: { $0.key < $1.key }) {
            if !handledKeys.contains(key) {
                output += "\(key): \(formatValue(val))\n"
            }
        }

        output += "---\n\n"
        output += body.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        return output
    }

    private static func stripQuotes(_ str: String) -> String {
        var s = str
        if (s.hasPrefix("\"") && s.hasSuffix("\"")) || (s.hasPrefix("'") && s.hasSuffix("'")) {
            if s.count >= 2 {
                s.removeFirst()
                s.removeLast()
            }
        }
        return s
    }

    private static func formatValue(_ str: String) -> String {
        if str.contains("\n") || str.contains(":") || str.contains("#") {
            let escaped = str.replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        return str
    }
}
