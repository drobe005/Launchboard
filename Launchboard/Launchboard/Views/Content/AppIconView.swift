import SwiftUI
import AppKit

struct AppIconView: View {
    let item: AppItem
    var size: CGFloat = 56
    var cornerRadius: CGFloat = LB.radiusIcon

    var body: some View {
        ZStack(alignment: .topTrailing) {
            iconBody

            if item.hasBadge {
                Circle()
                    .fill(LB.accent)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 2))
                    .shadow(color: LB.accentGlow, radius: 4)
                    .offset(x: 3, y: -3)
            }
        }
    }

    private var iconBody: some View {
        ZStack {
            // Gradient base
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LB.gradient(item.gradientKey))

            // Real app icon if cached, otherwise first-letter monogram
            if let data = item.iconData, let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.12)
            } else {
                Text(String(item.name.prefix(1)))
                    .font(.system(size: size * 0.40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 6)
    }
}

#Preview {
    HStack(spacing: 16) {
        AppIconView(item: SeedData.apps[0])
        AppIconView(item: SeedData.apps[2])   // has badge
        AppIconView(item: SeedData.apps[5], size: 44, cornerRadius: 11)
    }
    .padding(24)
    .background(LB.bgBase)
}
