import Foundation

struct AppSettings: Codable, Equatable {
    var theme: AppTheme             = .dark
    var accentColorHex: String      = "#5a82ff"
    var iconSize: Double            = 56
    var showAppNames: Bool          = true
    var reduceMotion: Bool          = false
    var launchAtLogin: Bool         = false
    var showMenuBarIcon: Bool       = true
    var recentlyAddedDays: Int      = 14
    var defaultView: ViewMode       = .grid
    var defaultSort: SortMode       = .alphabetical
    var globalShortcut: String      = "⌥Space"
    var hideWindowAfterLaunch: Bool = true
}

enum AppTheme: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case light, dark, auto
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var description: String { rawValue.capitalized }
}

enum ViewMode: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case grid, list
    var id: String { rawValue }
    var description: String { rawValue.capitalized }
}

enum SortMode: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case alphabetical = "A–Z"
    case recentlyUsed = "Recently Used"
    case mostUsed     = "Most Used"
    case dateAdded    = "Date Added"
    var id: String { rawValue }
    var description: String { rawValue }
}
