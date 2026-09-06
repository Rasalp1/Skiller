import SwiftUI

public struct ActionIconButton: View {
    public let icon: String
    public let title: String
    public let action: () -> Void
    public var tint: Color = .accentColor

    public init(icon: String, title: String, tint: Color = .accentColor, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundColor(tint)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
