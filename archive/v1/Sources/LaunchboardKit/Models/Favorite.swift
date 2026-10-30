/// SwiftData model representing a pinned app in the favorites row; soft cap of 12 enforced at VM layer.
import Foundation
import SwiftData

@Model
public final class Favorite {
    public var bundleIdentifier: String
    public var sortIndex: Int

    public init(bundleIdentifier: String, sortIndex: Int = 0) {
        self.bundleIdentifier = bundleIdentifier
        self.sortIndex = sortIndex
    }
}
