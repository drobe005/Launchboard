import SwiftUI

enum LB {
    // MARK: – Colors
    static let bgBase        = Color(hex: "#0d0d14")
    static let windowFill    = Color.white.opacity(0.04)
    static let sidebarFill   = Color.white.opacity(0.03)

    static let accent        = Color(red: 0.353, green: 0.510, blue: 1.0)
    static let accentDim     = accent.opacity(0.22)
    static let accentGlow    = accent.opacity(0.35)

    static let textPrimary   = Color.white.opacity(0.85)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary  = Color.white.opacity(0.28)
    static let textDisabled  = Color.white.opacity(0.18)

    static let borderSubtle  = Color.white.opacity(0.06)
    static let borderMid     = Color.white.opacity(0.10)
    static let borderActive  = Color(hex: "#5a82ff").opacity(0.50)

    static let danger        = Color(hex: "#ff6b6b")
    static let success       = Color(hex: "#34d399")
    static let warning       = Color(hex: "#fbbf24")

    // MARK: – Spacing
    static let spaceXS:  CGFloat =  4
    static let spaceSM:  CGFloat =  8
    static let spaceMD:  CGFloat = 12
    static let spaceLG:  CGFloat = 16
    static let spaceXL:  CGFloat = 24
    static let space2XL: CGFloat = 32

    // MARK: – Corner radii
    static let radiusXS:   CGFloat =  5
    static let radiusSM:   CGFloat =  7
    static let radiusMD:   CGFloat =  8
    static let radiusLG:   CGFloat = 10
    static let radiusXL:   CGFloat = 12
    static let radius2XL:  CGFloat = 16
    static let radiusIcon: CGFloat = 13

    // MARK: – Typography
    static let fontTitle   = Font.system(size: 19, weight: .semibold)
    static let fontBody    = Font.system(size: 13, weight: .regular)
    static let fontBodyMed = Font.system(size: 13, weight: .medium)
    static let fontCaption = Font.system(size: 11, weight: .regular)
    static let fontLabel   = Font.system(size: 10, weight: .semibold)
    static let fontAppName = Font.system(size: 11, weight: .medium)
    static let fontMono    = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: – App icon gradients
    static let gradients: [String: [Color]] = [
        "c0":  [Color(hex: "#5a82ff"), Color(hex: "#8b5cf6")],
        "c1":  [Color(hex: "#f59e0b"), Color(hex: "#ef4444")],
        "c2":  [Color(hex: "#10b981"), Color(hex: "#059669")],
        "c3":  [Color(hex: "#06b6d4"), Color(hex: "#3b82f6")],
        "c4":  [Color(hex: "#ec4899"), Color(hex: "#a855f7")],
        "c5":  [Color(hex: "#f97316"), Color(hex: "#eab308")],
        "c6":  [Color(hex: "#14b8a6"), Color(hex: "#0ea5e9")],
        "c7":  [Color(hex: "#8b5cf6"), Color(hex: "#ec4899")],
        "c8":  [Color(hex: "#22d3ee"), Color(hex: "#4ade80")],
        "c9":  [Color(hex: "#fb7185"), Color(hex: "#f43f5e")],
        "c10": [Color(hex: "#a78bfa"), Color(hex: "#818cf8")],
        "c11": [Color(hex: "#34d399"), Color(hex: "#059669")],
        "c12": [Color(hex: "#fbbf24"), Color(hex: "#f59e0b")],
        "c13": [Color(hex: "#60a5fa"), Color(hex: "#2563eb")],
        "c14": [Color(hex: "#e879f9"), Color(hex: "#a21caf")],
    ]

    static func gradient(_ key: String) -> LinearGradient {
        let colors = gradients[key] ?? [.gray, Color.gray.opacity(0.5)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
