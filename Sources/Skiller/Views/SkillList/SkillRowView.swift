import SwiftUI

public struct SkillRowView: View {
    public let item: StackItem
    public init(item: StackItem) { self.item = item }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ComponentIcon(kind: item.kind).padding(.top, 2)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(item.kind == .command ? "/\(item.name)" : item.name)
                        .font(.system(size: 13, weight: .semibold)).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 0)
                    if !item.isEnabled {
                        Image(systemName: "pause.circle").font(.system(size: 11))
                            .foregroundStyle(.secondary).accessibilityLabel("Disabled")
                    }
                }
                Text(item.description.isEmpty ? "No description provided." : item.description)
                    .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2).lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 5) {
                    Text(item.sourceKind.rawValue)
                    Text("·")
                    Text(item.kind.singularName)
                }
                .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 11).contentShape(Rectangle()).accessibilityElement(children: .combine)
    }
}
