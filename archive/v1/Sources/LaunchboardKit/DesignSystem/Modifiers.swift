/// Reusable ViewModifiers implementing the Launchboard design system tile, sidebar, and modal surfaces.
import SwiftUI

public struct AppTileStyleModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .background(LBColor.tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: LBRadius.tile))
    }
}

public struct SidebarItemStyleModifier: ViewModifier {
    let isSelected: Bool
    public init(isSelected: Bool) { self.isSelected = isSelected }
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, LBSpacing.sm)
            .padding(.vertical, LBSpacing.xs)
            .background(isSelected ? LBColor.accent.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: LBRadius.button))
    }
}

public struct ModalSheetStyleModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .padding(LBSpacing.xl)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: LBRadius.modal))
            .shadow(
                color: LBShadow.modal.color,
                radius: LBShadow.modal.radius,
                x: LBShadow.modal.x,
                y: LBShadow.modal.y
            )
    }
}

/// Dark frosted-glass modal surface matching the HiFi design.
public struct GlassModalStyleModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Dark glass fill
                    RoundedRectangle(cornerRadius: LBRadius.modal)
                        .fill(Color(red: 0.086, green: 0.086, blue: 0.157).opacity(0.85))
                    // Subtle border
                    RoundedRectangle(cornerRadius: LBRadius.modal)
                        .strokeBorder(LBColor.glassBorder, lineWidth: 1)
                    // Inner top highlight
                    RoundedRectangle(cornerRadius: LBRadius.modal)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.clear],
                                startPoint: .top, endPoint: .center
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: LBRadius.modal))
            .shadow(
                color: LBShadow.modal.color,
                radius: LBShadow.modal.radius,
                x: LBShadow.modal.x,
                y: LBShadow.modal.y
            )
    }
}

public extension View {
    func appTileStyle() -> some View {
        modifier(AppTileStyleModifier())
    }

    func sidebarItemStyle(isSelected: Bool) -> some View {
        modifier(SidebarItemStyleModifier(isSelected: isSelected))
    }

    func modalSheetStyle() -> some View {
        modifier(ModalSheetStyleModifier())
    }

    func glassModalStyle() -> some View {
        modifier(GlassModalStyleModifier())
    }
}
