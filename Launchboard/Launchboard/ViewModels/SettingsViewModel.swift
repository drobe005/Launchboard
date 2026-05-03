import SwiftUI
import Observation

@Observable
final class SettingsViewModel {
    var settings: AppSettings = AppSettings()
    var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general    = "General"
        case appearance = "Appearance"
        case library    = "Library"
        case shortcuts  = "Shortcuts"
        case about      = "About"

        var id: String { rawValue }

        var sfSymbol: String {
            switch self {
            case .general:    return "gearshape"
            case .appearance: return "paintpalette"
            case .library:    return "books.vertical"
            case .shortcuts:  return "keyboard"
            case .about:      return "info.circle"
            }
        }
    }
}
