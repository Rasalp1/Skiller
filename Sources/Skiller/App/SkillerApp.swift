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

    private static let menuBarIcon: NSImage = {
        let pointSize: CGFloat = 18.0
        // 1. Try MenuBarIcon.png from main bundle or module bundle
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png") ??
                     Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.size = NSSize(width: pointSize, height: pointSize)
            img.isTemplate = true
            return img
        }
        // 2. Try AppIcon.png
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png") ??
                     Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            let resized = NSImage(size: NSSize(width: pointSize, height: pointSize))
            resized.lockFocus()
            img.draw(in: NSRect(x: 0, y: 0, width: pointSize, height: pointSize), from: .zero, operation: .sourceOver, fraction: 1.0)
            resized.unlockFocus()
            resized.isTemplate = true
            return resized
        }
        // 3. Fallback to system symbol
        let fallback = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "Skiller") ?? NSImage()
        fallback.isTemplate = true
        return fallback
    }()

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

        MenuBarExtra {
            MenuBarPopoverView(appState: appState)
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
