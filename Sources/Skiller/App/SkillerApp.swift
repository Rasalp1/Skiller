import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the app icon from the ICNS in our bundle so the Dock tile
        // renders the transparent silhouette (no squircle added).
        if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: icnsURL) {
            NSApplication.shared.applicationIconImage = icon
        }

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
}

@main
struct SkillerApp: App {
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
