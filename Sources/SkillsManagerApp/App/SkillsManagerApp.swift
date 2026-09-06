import SwiftUI

@main
struct Skiller: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView(appState: appState)
                .frame(minWidth: 850, minHeight: 520)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // Update check hook
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("Reload Skills") {
                    Task {
                        await appState.refreshSkills()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra("Skills", systemImage: "sparkles") {
            MenuBarPopoverView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}
