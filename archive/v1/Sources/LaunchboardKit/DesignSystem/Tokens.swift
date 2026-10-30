/// Design token namespaces — colors, typography, spacing, radii, shadows, and animation constants.
import SwiftUI

public enum LBColor {
    // Accent — respects user accent override
    public static let accent = Color.accentColor
    public static let newBadge = Color.accentColor

    // HiFi dark glass palette
    /// Deep navy base — fills the window before any material
    public static let windowBase = Color(red: 0.051, green: 0.051, blue: 0.078)       // #0d0d14
    /// Frosted dark glass — main content area background (semi-transparent)
    public static let glassPanel = Color(red: 0.071, green: 0.071, blue: 0.125).opacity(0.55) // rgba(18,18,32,0.55)
    /// Sidebar column background
    public static let sidebarBg = Color.white.opacity(0.03)
    /// Subtle border for glass panels
    public static let glassBorder = Color.white.opacity(0.10)
    /// Dividers and section borders
    public static let separator = Color.white.opacity(0.06)
    /// Active / selected sidebar item fill
    public static let sidebarActiveFill = Color(red: 0.353, green: 0.510, blue: 1.0).opacity(0.22)
    /// Active / selected sidebar item border
    public static let sidebarActiveBorder = Color(red: 0.353, green: 0.510, blue: 1.0).opacity(0.30)
    /// Tile hover / pressed background
    public static let tileHoverBg = Color.white.opacity(0.08)
    /// Tile selection background
    public static let tileSelectedBg = Color(red: 0.353, green: 0.510, blue: 1.0).opacity(0.18)
    /// Tile selection border
    public static let tileSelectedBorder = Color(red: 0.353, green: 0.510, blue: 1.0).opacity(0.35)
    /// General control / button background
    public static let controlBg = Color.white.opacity(0.07)
    /// Control hover background
    public static let controlHoverBg = Color.white.opacity(0.10)
    /// Favorites bar background
    public static let favBarBg = Color.white.opacity(0.015)
    /// Drop-target accent fill
    public static let dropFill = Color(red: 0.353, green: 0.510, blue: 1.0).opacity(0.10)

    // Adaptive text — still adapts with color scheme
    public static let primaryText = Color(.labelColor)
    public static let secondaryText = Color(.secondaryLabelColor)
    public static let tertiaryText = Color(.tertiaryLabelColor)

    // Legacy aliases kept so nothing else breaks
    public static let background = Color(.windowBackgroundColor)
    public static let tileBackground = Color(.controlBackgroundColor)
}

public enum LBFont {
    public static let sectionHeader = Font.system(size: 15, weight: .semibold)
    public static let body = Font.system(size: 13, weight: .regular)
    public static let caption = Font.system(size: 11, weight: .regular).uppercaseSmallCaps()
    public static let tileLabel = Font.system(size: 11, weight: .regular)
}

public enum LBSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let sidebarWidth: CGFloat = 220
    public static let tileIconSize: CGFloat = 64
    public static let tilePadding: CGFloat = 10
}

public enum LBRadius {
    public static let window: CGFloat = 10
    public static let container: CGFloat = 8
    public static let button: CGFloat = 6
    public static let modal: CGFloat = 12
    public static let tile: CGFloat = 8
}

public enum LBShadow {
    public static let tile  = Shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 6)
    public static let modal = Shadow(color: Color.black.opacity(0.70), radius: 40, x: 0, y: 20)

    public struct Shadow {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
    }
}

public enum LBAnimation {
    public static let standard = Animation.spring(response: 0.2, dampingFraction: 0.8)
    public static let hoverScale: CGFloat = 1.04
}
