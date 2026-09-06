import SwiftUI
import AppKit

@main
struct SkillsManagerApp: App {
    @State private var appState = AppState()

    init() {
        setupAppIcon()
    }

    private func setupAppIcon() {
        // Attempt loading from SPM module bundle or main bundle
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        } else if let fallbackURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let iconImage = NSImage(contentsOf: fallbackURL) {
            NSApplication.shared.applicationIconImage = iconImage
        }
    }

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

        MenuBarExtra("Skills", systemImage: "fountainpen.nib") {
            MenuBarPopoverView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}
