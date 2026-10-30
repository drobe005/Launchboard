/// Tests for GlobalHotkeyService — register/unregister lifecycle, modifier conversion, action dispatch.
import XCTest
@testable import LaunchboardKit

/// All tests run on the main actor because GlobalHotkeyService is @MainActor.
@MainActor
final class GlobalHotkeyServiceTests: XCTestCase {

    override func tearDown() async throws {
        await GlobalHotkeyService.shared.unregister()
        GlobalHotkeyService.shared.setAction({})
    }

    // MARK: - Unregister

    func testUnregisterWithoutRegistrationIsNoop() async {
        await GlobalHotkeyService.shared.unregister()
        XCTAssertFalse(GlobalHotkeyService.shared.isRegistered)
        XCTAssertNil(GlobalHotkeyService.shared.currentShortcut)
    }

    func testDoubleUnregisterIsNoop() async throws {
        let s = GlobalShortcut(keyCode: 5, modifiers: 524288) // ⌥G
        try await GlobalHotkeyService.shared.register(shortcut: s)
        await GlobalHotkeyService.shared.unregister()
        await GlobalHotkeyService.shared.unregister() // second call — must not crash
        XCTAssertFalse(GlobalHotkeyService.shared.isRegistered)
    }

    // MARK: - Register

    func testRegisterSetsIsRegistered() async throws {
        let s = GlobalShortcut(keyCode: 5, modifiers: 524288) // ⌥G
        try await GlobalHotkeyService.shared.register(shortcut: s)
        XCTAssertTrue(GlobalHotkeyService.shared.isRegistered)
    }

    func testRegisterStoresCurrentShortcut() async throws {
        let s = GlobalShortcut(keyCode: 5, modifiers: 524288)
        try await GlobalHotkeyService.shared.register(shortcut: s)
        XCTAssertEqual(GlobalHotkeyService.shared.currentShortcut, s)
    }

    func testUnregisterClearsState() async throws {
        let s = GlobalShortcut(keyCode: 5, modifiers: 524288)
        try await GlobalHotkeyService.shared.register(shortcut: s)
        await GlobalHotkeyService.shared.unregister()
        XCTAssertFalse(GlobalHotkeyService.shared.isRegistered)
        XCTAssertNil(GlobalHotkeyService.shared.currentShortcut)
    }

    // MARK: - Re-registration (unbinds previous before binding new)

    func testDoubleRegisterUnbindsFirst() async throws {
        let s1 = GlobalShortcut(keyCode: 5, modifiers: 524288)  // ⌥G
        let s2 = GlobalShortcut(keyCode: 3, modifiers: 524288)  // ⌥F
        try await GlobalHotkeyService.shared.register(shortcut: s1)
        try await GlobalHotkeyService.shared.register(shortcut: s2)
        XCTAssertTrue(GlobalHotkeyService.shared.isRegistered)
        XCTAssertEqual(GlobalHotkeyService.shared.currentShortcut, s2)
    }

    func testRegisterAfterUnregisterSucceeds() async throws {
        let s = GlobalShortcut(keyCode: 5, modifiers: 524288)
        try await GlobalHotkeyService.shared.register(shortcut: s)
        await GlobalHotkeyService.shared.unregister()
        try await GlobalHotkeyService.shared.register(shortcut: s)
        XCTAssertTrue(GlobalHotkeyService.shared.isRegistered)
    }

    // MARK: - Conflict detection (RegistrationFailed for system-reserved shortcuts)

    func testRegisteringSpotlightShortcutFailsOrSucceeds() async {
        // ⌘Space (keyCode 49, modifiers 1048576) is reserved by Spotlight.
        // Behaviour depends on system settings — we only assert it doesn't crash.
        let spotlight = GlobalShortcut(keyCode: 49, modifiers: 1048576)
        do {
            try await GlobalHotkeyService.shared.register(shortcut: spotlight)
        } catch HotkeyError.registrationFailed {
            // Expected on most systems; pass.
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHotkeyErrorEquality() {
        XCTAssertEqual(HotkeyError.registrationFailed(-1), HotkeyError.registrationFailed(-1))
        XCTAssertNotEqual(HotkeyError.registrationFailed(-1), HotkeyError.registrationFailed(-2))
        XCTAssertEqual(HotkeyError.noEventDispatcher, HotkeyError.noEventDispatcher)
    }

    // MARK: - Action dispatch

    func testTriggerActionCallsHandler() {
        var called = false
        GlobalHotkeyService.shared.setAction { called = true }
        GlobalHotkeyService.shared.triggerAction()
        XCTAssertTrue(called)
    }

    func testSetActionReplacesOldAction() {
        var count = 0
        GlobalHotkeyService.shared.setAction { count += 1 }
        GlobalHotkeyService.shared.setAction { count += 10 }
        GlobalHotkeyService.shared.triggerAction()
        XCTAssertEqual(count, 10)
    }

    func testTriggerActionWithNoHandlerIsNoop() {
        GlobalHotkeyService.shared.setAction({})
        // Should not crash with empty action
        GlobalHotkeyService.shared.triggerAction()
    }

    func testActionIsCalledOnEachTrigger() {
        var count = 0
        GlobalHotkeyService.shared.setAction { count += 1 }
        GlobalHotkeyService.shared.triggerAction()
        GlobalHotkeyService.shared.triggerAction()
        GlobalHotkeyService.shared.triggerAction()
        XCTAssertEqual(count, 3)
    }

    // MARK: - GlobalShortcut type

    func testGlobalShortcutEquality() {
        let a = GlobalShortcut(keyCode: 49, modifiers: 524288)
        let b = GlobalShortcut(keyCode: 49, modifiers: 524288)
        XCTAssertEqual(a, b)
    }

    func testGlobalShortcutInequalityByKeyCode() {
        let a = GlobalShortcut(keyCode: 49, modifiers: 524288)
        let b = GlobalShortcut(keyCode: 48, modifiers: 524288)
        XCTAssertNotEqual(a, b)
    }

    func testGlobalShortcutInequalityByModifiers() {
        let a = GlobalShortcut(keyCode: 49, modifiers: 524288)
        let b = GlobalShortcut(keyCode: 49, modifiers: 1048576)
        XCTAssertNotEqual(a, b)
    }

    func testGlobalShortcutStoredFields() {
        let s = GlobalShortcut(keyCode: 36, modifiers: 262144)
        XCTAssertEqual(s.keyCode, 36)
        XCTAssertEqual(s.modifiers, 262144)
    }
}
