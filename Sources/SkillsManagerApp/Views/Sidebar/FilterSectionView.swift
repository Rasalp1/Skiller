import SwiftUI

public struct FilterSectionView: View {
    @Bindable var appState: AppState
    public init(appState: AppState) { self.appState = appState }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filter library").font(.headline)
                Spacer()
                Button("Reset") {
                    appState.statusFilter = .all
                    appState.triggerFilter = nil
                }
                .buttonStyle(.borderless)
            }
            Picker("Status", selection: $appState.statusFilter) {
                Text("All").tag(FilterStatus.all)
                Text("Active").tag(FilterStatus.active)
                Text("Disabled").tag(FilterStatus.disabled)
            }
            .pickerStyle(.segmented)
            Picker("Invocation", selection: $appState.triggerFilter) {
                Text("Any invocation").tag(nil as InvocationTriggerType?)
                Text("Automatic").tag(InvocationTriggerType.auto as InvocationTriggerType?)
                Text("Manual").tag(InvocationTriggerType.manual as InvocationTriggerType?)
                Text("Hybrid").tag(InvocationTriggerType.hybrid as InvocationTriggerType?)
            }
        }
        .padding(20).frame(width: 300)
    }
}
