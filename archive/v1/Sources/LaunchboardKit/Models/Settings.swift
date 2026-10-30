/// SwiftData singleton-row model storing all user preferences (named AppSettings to avoid namespace clashes).
import Foundation
import SwiftData

public enum DefaultView: String, Codable, CaseIterable {
    case grid, list
}

public enum DefaultSort: String, Codable, CaseIterable {
    case alphabetical, lastOpened, recentlyAdded, mostUsed, fileSize

    public var label: String {
        switch self {
        case .alphabetical:  return "A–Z"
        case .lastOpened:    return "Last Used"
        case .recentlyAdded: return "Recently Added"
        case .mostUsed:      return "Most Used"
        case .fileSize:      return "File Size"
        }
    }
}

public enum AppTheme: String, Codable, CaseIterable {
    case auto, light, dark
}

public enum ReduceMotionMode: String, Codable, CaseIterable {
    /// Follow the system Accessibility → Reduce Motion setting.
    case auto
    /// Always reduce motion regardless of system preference.
    case always
    /// Never reduce motion regardless of system preference.
    case never
}

@Model
public final class AppSettings {
    public var launchAtLogin: Bool
    public var showMenuBarIcon: Bool
    public var recentlyAddedTimeframe: Int
    public var defaultView: DefaultView
    public var defaultSort: DefaultSort
    public var theme: AppTheme
    public var accentColorOverride: String?
    public var iconSize: Int
    public var showAppNames: Bool
    public var reduceMotionMode: ReduceMotionMode
    public var scanLocations: [URL]
    public var hiddenAppBundleIDs: [String]

    // MARK: - Global shortcut (stored as raw NSEvent values)
    /// Key code for the global shortcut (default: 49 = Space).
    public var globalShortcutKeyCode: Int
    /// NSEvent.ModifierFlags raw value (default: 524288 = option).
    public var globalShortcutModifiers: Int

    // MARK: - In-app shortcut overrides (keyCode + NSEvent.ModifierFlags raw value)
    /// (0, 0) means "no shortcut assigned". Valid shortcuts require modifiers != 0.
    public var shortcutNewGroupKeyCode: Int
    public var shortcutNewGroupModifiers: Int
    public var shortcutFavoriteKeyCode: Int
    public var shortcutFavoriteModifiers: Int
    public var shortcutToggleViewKeyCode: Int
    public var shortcutToggleViewModifiers: Int
    public var shortcutFocusSearchKeyCode: Int
    public var shortcutFocusSearchModifiers: Int
    public var shortcutOpenSettingsKeyCode: Int
    public var shortcutOpenSettingsModifiers: Int
    public var shortcutQuitKeyCode: Int
    public var shortcutQuitModifiers: Int

    // MARK: - Behavior flags
    public var launchOnEnter: Bool
    public var showFavoritesRow: Bool
    public var onboardingCompleted: Bool

    public init(
        launchAtLogin: Bool = false,
        showMenuBarIcon: Bool = true,
        recentlyAddedTimeframe: Int = 14,
        defaultView: DefaultView = .grid,
        defaultSort: DefaultSort = .alphabetical,
        theme: AppTheme = .dark,
        accentColorOverride: String? = nil,
        iconSize: Int = 64,
        showAppNames: Bool = true,
        reduceMotionMode: ReduceMotionMode = .auto,
        scanLocations: [URL] = [],
        hiddenAppBundleIDs: [String] = [],
        globalShortcutKeyCode: Int = 49,
        globalShortcutModifiers: Int = 524288,
        shortcutNewGroupKeyCode: Int = 45,       // N
        shortcutNewGroupModifiers: Int = 1048576, // ⌘
        shortcutFavoriteKeyCode: Int = 2,         // D
        shortcutFavoriteModifiers: Int = 1048576,
        shortcutToggleViewKeyCode: Int = 42,      // backslash
        shortcutToggleViewModifiers: Int = 1048576,
        shortcutFocusSearchKeyCode: Int = 3,      // F
        shortcutFocusSearchModifiers: Int = 1048576,
        shortcutOpenSettingsKeyCode: Int = 43,    // comma
        shortcutOpenSettingsModifiers: Int = 1048576,
        shortcutQuitKeyCode: Int = 12,            // Q
        shortcutQuitModifiers: Int = 1048576,
        launchOnEnter: Bool = true,
        showFavoritesRow: Bool = true,
        onboardingCompleted: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.recentlyAddedTimeframe = recentlyAddedTimeframe
        self.defaultView = defaultView
        self.defaultSort = defaultSort
        self.theme = theme
        self.accentColorOverride = accentColorOverride
        self.iconSize = iconSize
        self.showAppNames = showAppNames
        self.reduceMotionMode = reduceMotionMode
        self.scanLocations = scanLocations
        self.hiddenAppBundleIDs = hiddenAppBundleIDs
        self.globalShortcutKeyCode = globalShortcutKeyCode
        self.globalShortcutModifiers = globalShortcutModifiers
        self.shortcutNewGroupKeyCode = shortcutNewGroupKeyCode
        self.shortcutNewGroupModifiers = shortcutNewGroupModifiers
        self.shortcutFavoriteKeyCode = shortcutFavoriteKeyCode
        self.shortcutFavoriteModifiers = shortcutFavoriteModifiers
        self.shortcutToggleViewKeyCode = shortcutToggleViewKeyCode
        self.shortcutToggleViewModifiers = shortcutToggleViewModifiers
        self.shortcutFocusSearchKeyCode = shortcutFocusSearchKeyCode
        self.shortcutFocusSearchModifiers = shortcutFocusSearchModifiers
        self.shortcutOpenSettingsKeyCode = shortcutOpenSettingsKeyCode
        self.shortcutOpenSettingsModifiers = shortcutOpenSettingsModifiers
        self.shortcutQuitKeyCode = shortcutQuitKeyCode
        self.shortcutQuitModifiers = shortcutQuitModifiers
        self.launchOnEnter = launchOnEnter
        self.showFavoritesRow = showFavoritesRow
        self.onboardingCompleted = onboardingCompleted
    }
}
