import SwiftUI
import KeyboardShortcuts

@main
struct LaunchboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var library    = LibraryViewModel()
    @State private var settingsVM = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(library)
                .environment(settingsVM)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 960, height: 620)
        .commands {
            // Remove default File/Edit/Help items that don't apply
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Library") {
                Button("New Group") {
                    // Trigger the Add Group sheet via a notification the sidebar observes
                    NotificationCenter.default.post(name: .showAddGroup, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Toggle Favorite") {
                    guard let id  = library.selectedAppIDs.first ?? library.focusedAppID,
                          let app = library.apps.first(where: { $0.id == id })
                    else { return }
                    library.toggleFavorite(app)
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("Launch Selected") {
                    library.launchFocusedApp()
                }
                .keyboardShortcut(.return, modifiers: [])
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings\u{2026}") {
                    withAnimation { library.showSettings = true }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

// MARK: – Notification names

extension Notification.Name {
    static let showAddGroup = Notification.Name("com.launchboard.showAddGroup")
}

// MARK: – AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMainWindow()
        HotkeyService.shared.setup()
    }

    private func configureMainWindow() {
        guard let window = NSApp.windows.first else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.hasShadow = true
        window.styleMask.insert(.fullSizeContentView)
        window.minSize = NSSize(width: 800, height: 500)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Re-show window if user clicks the Dock icon (won't appear usually but guards against it)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { HotkeyService.shared.toggleWindow() }
        return false
    }
}
