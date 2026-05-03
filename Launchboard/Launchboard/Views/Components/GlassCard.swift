import SwiftUI

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = LB.radius2XL

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    Color(hex: "#16162a").opacity(0.65)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LB.borderMid, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = LB.radius2XL) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
