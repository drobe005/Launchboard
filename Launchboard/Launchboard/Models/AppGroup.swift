import Foundation

struct AppGroup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var appIDs: [UUID]
    var isSmartGroup: Bool
    var smartRules: [SmartRule]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        appIDs: [UUID] = [],
        isSmartGroup: Bool = false,
        smartRules: [SmartRule] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.appIDs = appIDs
        self.isSmartGroup = isSmartGroup
        self.smartRules = smartRules
    }
}

struct SmartRule: Codable, Equatable {
    var condition: SmartCondition
    var op: SmartOperator
    var value: String

    enum SmartCondition: String, Codable, CaseIterable {
        case category = "Category"
        case lastUsed = "Last used"
        case name     = "Name"
    }

    enum SmartOperator: String, Codable, CaseIterable {
        case `is`       = "is"
        case isNot      = "is not"
        case contains   = "contains"
        case isMoreThan = "is more than"
    }
}
