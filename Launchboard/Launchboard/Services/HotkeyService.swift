import AppKit
import KeyboardShortcuts

// MARK: – Shortcut name declaration

extension KeyboardShortcuts.Name {
    /// Global show/hide toggle. Default: ⌥Space.
    static let toggleLaunchboard = Self(
        "toggleLaunchboard",
        default: .init(.space, modifiers: .option)
    )
}

// MARK: – Service

/// Registers and handles the global ⌥Space hotkey.
/// Call `setup()` once from AppDelegate after the window is ready.
final class HotkeyService: @unchecked Sendable {

    static let shared = HotkeyService()
    private init() {}

    func setup() {
        KeyboardShortcuts.onKeyUp(for: .toggleLaunchboard) {
            DispatchQueue.main.async { HotkeyService.shared.toggleWindow() }
        }
    }

    func toggleWindow() {
        guard let window = NSApp.windows.first else { return }

        if window.isVisible && NSApp.isActive {
            // Hide — user toggled while Launchboard was in front
            NSApp.hide(nil)
        } else {
            // Show and focus
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Re-register when the user records a new shortcut in Settings.
    func updateShortcut(to shortcutString: String) {
        // KeyboardShortcuts handles persistence automatically via UserDefaults.
        // The Settings "Record" button will be wired to the built-in
        // KeyboardShortcuts.Recorder in a future polish pass.
        _ = shortcutString // placeholder until recorder UI is wired
    }
}
