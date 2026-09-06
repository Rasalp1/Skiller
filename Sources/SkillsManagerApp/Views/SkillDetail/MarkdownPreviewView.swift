import SwiftUI

public struct MarkdownPreviewView: View {
    public let skill: Skill

    public init(skill: Skill) {
        self.skill = skill
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Frontmatter Card
                if !skill.frontmatter.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("YAML Frontmatter", systemImage: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                            ForEach(skill.frontmatter.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                GridRow {
                                    Text(key)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text(value)
                                        .font(.system(size: 12, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .cardContainer()
                }

                // Rendered Markdown Content
                VStack(alignment: .leading, spacing: 12) {
                    if let attr = try? AttributedString(markdown: skill.markdownBody, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attr)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    } else {
                        Text(skill.markdownBody)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.subtleBorder, lineWidth: 1)
                )
            }
            .padding(16)
        }
    }
}
