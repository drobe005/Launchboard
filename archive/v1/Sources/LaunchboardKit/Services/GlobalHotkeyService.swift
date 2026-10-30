/// Global hotkey registration via Carbon RegisterEventHotKey.
import AppKit
import Carbon

// MARK: - Public types

public struct GlobalShortcut: Sendable, Equatable {
    public let keyCode: Int
    /// NSEvent.ModifierFlags raw value stored as Int (avoids AppKit type in public API).
    public let modifiers: Int

    public init(keyCode: Int, modifiers: Int) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

public enum HotkeyError: Error, Equatable {
    case registrationFailed(OSStatus)
    case noEventDispatcher
}

// MARK: - Carbon callback (file-scope C-compatible function)

/// Receives kEventHotKeyPressed from Carbon. Dispatches to the main actor.
private func globalHotkeyEventHandler(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    Task { @MainActor in GlobalHotkeyService.shared.triggerAction() }
    return noErr
}

// MARK: - Service

@MainActor
public final class GlobalHotkeyService {
    public static let shared = GlobalHotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: (() -> Void)?

    public private(set) var isRegistered: Bool = false
    public private(set) var currentShortcut: GlobalShortcut?

    private init() {
        installCarbonHandler()
    }

    // MARK: - Public API

    public func setAction(_ action: @escaping () -> Void) {
        self.action = action
    }

    public func register(shortcut: GlobalShortcut) async throws {
        unregisterSync()

        guard let dispatcher = GetEventDispatcherTarget() else {
            throw HotkeyError.noEventDispatcher
        }

        let id = EventHotKeyID(signature: fourCC("LBHK"), id: 1)
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            carbonModifiers(from: shortcut.modifiers),
            id,
            dispatcher,
            0,
            &hotKeyRef
        )
        guard status == noErr else { throw HotkeyError.registrationFailed(status) }
        isRegistered = true
        currentShortcut = shortcut
    }

    public func unregister() async {
        unregisterSync()
    }

    /// Fires the stored action. Called by the Carbon callback; also available for testing.
    public func triggerAction() {
        action?()
    }

    // MARK: - Internal helpers

    private func unregisterSync() {
        guard let ref = hotKeyRef else { return }
        UnregisterEventHotKey(ref)
        hotKeyRef = nil
        isRegistered = false
        currentShortcut = nil
    }

    private func installCarbonHandler() {
        guard eventHandlerRef == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetEventDispatcherTarget(),
            globalHotkeyEventHandler,
            1,
            &spec,
            nil,
            &eventHandlerRef
        )
    }

    private func carbonModifiers(from nsRaw: Int) -> UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(bitPattern: nsRaw))
        var carbon: UInt32 = 0
        if flags.contains(NSEvent.ModifierFlags.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(NSEvent.ModifierFlags.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(NSEvent.ModifierFlags.control) { carbon |= UInt32(controlKey) }
        if flags.contains(NSEvent.ModifierFlags.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }

    private func fourCC(_ s: String) -> FourCharCode {
        var result: FourCharCode = 0
        for byte in s.utf8.prefix(4) {
            result = (result << 8) | FourCharCode(byte)
        }
        return result
    }
}
