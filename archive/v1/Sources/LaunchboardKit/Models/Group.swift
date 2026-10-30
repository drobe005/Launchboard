/// SwiftData model representing a manual or smart app group (named AppGroup to avoid SwiftUI.Group conflict).
import Foundation
import SwiftData

@Model
public final class AppGroup {
    public var id: UUID
    public var name: String
    public var emoji: String?
    public var sortIndex: Int
    public var isSmartGroup: Bool
    /// true = all rules must match (AND); false = any rule matches (OR).
    public var matchAll: Bool
    @Relationship(deleteRule: .cascade) public var smartRules: [SmartGroupRule]
    public var appBundleIDs: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        emoji: String? = nil,
        sortIndex: Int = 0,
        isSmartGroup: Bool = false,
        matchAll: Bool = true,
        smartRules: [SmartGroupRule] = [],
        appBundleIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortIndex = sortIndex
        self.isSmartGroup = isSmartGroup
        self.matchAll = matchAll
        self.smartRules = smartRules
        self.appBundleIDs = appBundleIDs
    }
}
