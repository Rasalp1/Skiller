import SwiftUI

public struct FilterSectionView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status filter buttons
            Picker("Status", selection: $appState.statusFilter) {
                ForEach(FilterStatus.allCases) { st in
                    Text(st.rawValue).tag(st)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Trigger type filters
            VStack(alignment: .leading, spacing: 4) {
                Text("Invocation Type")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 6) {
                    filterChip(title: "All", isSelected: appState.triggerFilter == nil) {
                        appState.triggerFilter = nil
                    }

                    filterChip(title: "Auto", isSelected: appState.triggerFilter == .auto) {
                        appState.triggerFilter = (appState.triggerFilter == .auto) ? nil : .auto
                    }

                    filterChip(title: "Manual", isSelected: appState.triggerFilter == .manual) {
                        appState.triggerFilter = (appState.triggerFilter == .manual) ? nil : .manual
                    }

                    filterChip(title: "Hybrid", isSelected: appState.triggerFilter == .hybrid) {
                        appState.triggerFilter = (appState.triggerFilter == .hybrid) ? nil : .hybrid
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
