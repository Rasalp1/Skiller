import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupAppIcon()
        
        // Keep app quietly in menu bar on startup unless explicitly opened
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows where window.canBecomeMain {
                window.close()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                let hasVisibleMainWindows = NSApplication.shared.windows.contains { window in
                    window.isVisible && window.canBecomeMain
                }
                if !hasVisibleMainWindows {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }

    @MainActor
    private func setupAppIcon() {
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        } else if let mainPngURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
                  let iconImage = NSImage(contentsOf: mainPngURL) {
            NSApplication.shared.applicationIconImage = iconImage
        } else if let fallbackURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let iconImage = NSImage(contentsOf: fallbackURL) {
            NSApplication.shared.applicationIconImage = iconImage
        }
    }
}

@main
struct SkillsManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        Window("Skiller", id: "library") {
            MainView(appState: appState)
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1240, height: 820)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Refresh Library") {
                    Task {
                        await appState.refreshSkills()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra("Skiller", systemImage: "square.stack.3d.up") {
            MenuBarPopoverView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}
