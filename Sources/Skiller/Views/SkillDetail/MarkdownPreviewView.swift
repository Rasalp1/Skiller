import SwiftUI

/// Lightweight document blocks; inline formatting is rendered by Foundation.
enum MarkdownBlock: Equatable {
    case heading(Int, String)
    case paragraph(String)
    case code(String)
    case bullet(String, String)
    case quote(String)
    case divider

    static func parse(_ content: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var code: [String] = []
        var fence: String?
        func flushParagraph() {
            if !paragraph.isEmpty {
                blocks.append(.paragraph(paragraph.joined(separator: "\n")))
                paragraph = []
            }
        }
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let activeFence = fence {
                if trimmed.hasPrefix(activeFence) {
                    blocks.append(.code(code.joined(separator: "\n")))
                    code = []
                    fence = nil
                } else { code.append(line) }
                continue
            }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                flushParagraph()
                fence = String(trimmed.prefix(3))
            } else if trimmed.isEmpty {
                flushParagraph()
            } else if ["---", "***", "___"].contains(trimmed) {
                flushParagraph()
                blocks.append(.divider)
            } else if trimmed.hasPrefix("#"),
                      let space = trimmed.firstIndex(of: " "),
                      trimmed[..<space].allSatisfy({ $0 == "#" }),
                      trimmed.distance(from: trimmed.startIndex, to: space) <= 6 {
                flushParagraph()
                blocks.append(.heading(trimmed.distance(from: trimmed.startIndex, to: space),
                                       String(trimmed[trimmed.index(after: space)...])))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                flushParagraph()
                blocks.append(.bullet("•", String(trimmed.dropFirst(2))))
            } else if let dot = trimmed.firstIndex(of: "."),
                      !trimmed[..<dot].isEmpty,
                      trimmed[..<dot].allSatisfy(\.isNumber),
                      trimmed[trimmed.index(after: dot)...].hasPrefix(" ") {
                flushParagraph()
                blocks.append(.bullet(String(trimmed[...dot]), String(trimmed[trimmed.index(after: dot)...]).trimmingCharacters(in: .whitespaces)))
            } else if trimmed.hasPrefix("> ") {
                flushParagraph()
                blocks.append(.quote(String(trimmed.dropFirst(2))))
            } else { paragraph.append(line) }
        }
        flushParagraph()
        if fence != nil { blocks.append(.code(code.joined(separator: "\n"))) }
        return blocks
    }
}

struct MarkdownDocumentView: View {
    let content: String

    var body: some View {
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            EmptyLibraryView(icon: "doc.text", title: "No instructions yet",
                             message: "Edit this component to add its instructions.")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(MarkdownBlock.parse(content).enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
                .font(.system(size: 13)).lineSpacing(5).textSelection(.enabled)
                .padding(Theme.pageInset).frame(maxWidth: 780, alignment: .leading).frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            inline(text).font(.system(size: level == 1 ? 24 : level == 2 ? 19 : 15, weight: .semibold))
                .padding(.top, level <= 2 ? 12 : 4)
        case .paragraph(let text):
            inline(text).frame(maxWidth: .infinity, alignment: .leading)
        case .code(let text):
            ScrollView(.horizontal) {
                Text(text).font(.system(size: 12, design: .monospaced)).lineSpacing(4)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.secondarySurface, in: RoundedRectangle(cornerRadius: 8))
        case .bullet(let marker, let text):
            HStack(alignment: .top, spacing: 10) {
                Text(marker).foregroundStyle(.secondary).frame(minWidth: 14, alignment: .trailing)
                inline(text).frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 4)
        case .quote(let text):
            HStack(spacing: 14) {
                Rectangle().fill(Theme.accent.opacity(0.4)).frame(width: 3)
                inline(text).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)
        case .divider: Divider().padding(.vertical, 6)
        }
    }

    private func inline(_ text: String) -> Text {
        Text((try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text))
    }
}
