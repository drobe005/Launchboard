import Foundation

struct AppItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var bundleID: String
    var iconData: Data?
    var category: AppCategory
    var isFavorite: Bool
    var hasBadge: Bool
    var gradientKey: String
    var dateAdded: Date
    var lastUsed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        bundleID: String,
        iconData: Data? = nil,
        category: AppCategory,
        isFavorite: Bool = false,
        hasBadge: Bool = false,
        gradientKey: String = "c0",
        dateAdded: Date = .now,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.iconData = iconData
        self.category = category
        self.isFavorite = isFavorite
        self.hasBadge = hasBadge
        self.gradientKey = gradientKey
        self.dateAdded = dateAdded
        self.lastUsed = lastUsed
    }
}

enum AppCategory: String, CaseIterable, Codable, Identifiable {
    case all           = "All"
    case design        = "Design"
    case development   = "Development"
    case communication = "Communication"
    case media         = "Media"
    case productivity  = "Productivity"
    case utilities     = "Utilities"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .all:           return "square.grid.2x2"
        case .design:        return "paintbrush"
        case .development:   return "chevron.left.forwardslash.chevron.right"
        case .communication: return "bubble.left.and.bubble.right"
        case .media:         return "play.rectangle"
        case .productivity:  return "checkmark.circle"
        case .utilities:     return "wrench.and.screwdriver"
        }
    }
}
