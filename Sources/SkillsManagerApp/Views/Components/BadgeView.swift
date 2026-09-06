import SwiftUI

public struct KindBadge: View {
    public let kind: ComponentKind

    public init(kind: ComponentKind) {
        self.kind = kind
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.icon)
                .font(.system(size: 9, weight: .bold))
            Text(kind.singularName)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(kind.color.opacity(0.15))
        .foregroundColor(kind.color)
        .clipShape(Capsule())
    }
}

public struct SourceBadge: View {
    public let kind: SkillSourceKind

    public init(kind: SkillSourceKind) {
        self.kind = kind
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.icon)
                .font(.system(size: 9, weight: .bold))
            Text(kind.rawValue)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Theme.colorForSource(kind).opacity(0.15))
        .foregroundColor(Theme.colorForSource(kind))
        .clipShape(Capsule())
    }
}

public struct InvocationModeBadge: View {
    public let kind: ComponentKind

    public init(kind: ComponentKind) {
        self.kind = kind
    }

    public var body: some View {
        if kind == .command {
            HStack(spacing: 4) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("Slash Command (/)")
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .clipShape(Capsule())
        } else if kind == .skill {
            HStack(spacing: 4) {
                Image(systemName: "bolt.badge.automatic.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("Autonomous Skill")
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.15))
            .foregroundColor(.green)
            .clipShape(Capsule())
        }
    }
}

public struct StatusPill: View {
    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isEnabled ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 6, height: 6)
            Text(isEnabled ? "Active" : "Disabled")
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(isEnabled ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
        .foregroundColor(isEnabled ? .green : .secondary)
        .clipShape(Capsule())
    }
}
