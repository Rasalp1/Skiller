import SwiftUI

public struct SkillRowView: View {
    public let item: StackItem
    public let onToggle: () -> Void

    public init(skill: Skill, onToggle: @escaping () -> Void) {
        self.item = StackItem(
            id: skill.id,
            kind: .skill,
            name: skill.name,
            description: skill.description,
            sourceId: skill.sourceId,
            sourceKind: skill.sourceKind,
            sourceName: skill.sourceName,
            isEnabled: skill.isEnabled,
            fileURL: skill.skillFileURL,
            directoryURL: skill.directoryURL,
            content: skill.markdownBody,
            frontmatter: skill.frontmatter,
            metadata: ["origin": skill.origin ?? ""],
            invocationType: .auto,
            lastModified: skill.lastModified,
            files: skill.files
        )
        self.onToggle = onToggle
    }

    public init(item: StackItem, onToggle: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Toggle Switch
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .scaleEffect(0.8)
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if item.kind == .command {
                        Text("/\(item.name)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(item.isEnabled ? .blue : .secondary)
                    } else {
                        Text(item.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(item.isEnabled ? .primary : .secondary)
                    }

                    Spacer()

                    KindBadge(kind: item.kind)
                    SourceBadge(kind: item.sourceKind)
                }

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    if item.kind == .skill || item.kind == .command {
                        InvocationModeBadge(kind: item.kind)
                    }

                    if let origin = item.origin, !origin.isEmpty {
                        Text(origin)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.12))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                    }

                    if let model = item.model, !model.isEmpty {
                        Text("Model: \(model)")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.12))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    }

                    if !item.files.isEmpty && item.files.count > 1 {
                        HStack(spacing: 2) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 8))
                            Text("\(item.files.count) files")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .opacity(item.isEnabled ? 1.0 : 0.65)
    }
}
