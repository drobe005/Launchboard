/// SwiftData model representing an application discovered on disk.
import Foundation
import SwiftData

@Model
public final class AppEntry {
    public var id: UUID
    public var bundleIdentifier: String
    public var displayName: String
    public var iconData: Data?
    public var bundleURL: URL
    public var lastOpenedAt: Date?
    public var installedAt: Date
    public var fileSize: Int64
    public var version: String
    public var isHidden: Bool
    public var isAppleBuiltIn: Bool
    /// Set when the entry is first inserted; cleared when the user dismisses the badge or the timeframe elapses.
    public var recentlyAddedAt: Date?
    /// LSApplicationCategoryType from the app's Info.plist (e.g. "public.app-category.productivity").
    public var category: String?

    public init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        displayName: String,
        iconData: Data? = nil,
        bundleURL: URL,
        lastOpenedAt: Date? = nil,
        installedAt: Date = Date(),
        fileSize: Int64 = 0,
        version: String = "",
        isHidden: Bool = false,
        isAppleBuiltIn: Bool = false,
        recentlyAddedAt: Date? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.iconData = iconData
        self.bundleURL = bundleURL
        self.lastOpenedAt = lastOpenedAt
        self.installedAt = installedAt
        self.fileSize = fileSize
        self.version = version
        self.isHidden = isHidden
        self.isAppleBuiltIn = isAppleBuiltIn
        self.recentlyAddedAt = recentlyAddedAt
        self.category = category
    }
}
