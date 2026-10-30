/// Singleton-row accessor for AppSettings; fetches or creates the single persisted row.
import Foundation
import SwiftData

public enum SettingsStore {
    /// Default scan locations: /Applications and ~/Applications.
    public static var defaultScanLocations: [URL] {
        var locations = [URL(fileURLWithPath: "/Applications")]
        let home = FileManager.default.homeDirectoryForCurrentUser
        let userApps = home.appendingPathComponent("Applications")
        if FileManager.default.fileExists(atPath: userApps.path) {
            locations.append(userApps)
        }
        return locations
    }

    /// Returns the single AppSettings row, creating it with defaults if absent.
    public static func current(in context: ModelContext) throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let rows = try context.fetch(descriptor)

        if let existing = rows.first {
            return existing
        }

        let settings = AppSettings(
            launchAtLogin: false,
            showMenuBarIcon: true,
            recentlyAddedTimeframe: 14,
            defaultView: .grid,
            defaultSort: .alphabetical,
            theme: .auto,
            accentColorOverride: nil,
            iconSize: 64,
            showAppNames: true,
            reduceMotionMode: .auto,
            scanLocations: defaultScanLocations,
            hiddenAppBundleIDs: [],
            globalShortcutKeyCode: 49,
            globalShortcutModifiers: 524288,
            shortcutNewGroupKeyCode: 45,
            shortcutNewGroupModifiers: 1048576,
            shortcutFavoriteKeyCode: 2,
            shortcutFavoriteModifiers: 1048576,
            shortcutToggleViewKeyCode: 42,
            shortcutToggleViewModifiers: 1048576,
            shortcutFocusSearchKeyCode: 3,
            shortcutFocusSearchModifiers: 1048576,
            shortcutOpenSettingsKeyCode: 43,
            shortcutOpenSettingsModifiers: 1048576,
            shortcutQuitKeyCode: 12,
            shortcutQuitModifiers: 1048576,
            launchOnEnter: true,
            showFavoritesRow: true,
            onboardingCompleted: false
        )
        context.insert(settings)
        try context.save()
        return settings
    }
}
