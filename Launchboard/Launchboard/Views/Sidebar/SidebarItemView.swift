import SwiftUI

struct SidebarItemView: View {
    let icon: String        // SF Symbol name
    let iconColor: Color
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: LB.spaceMD) {
                iconView
                Text(label)
                    .font(LB.fontBodyMed)
                    .foregroundStyle(isActive || isHovered ? LB.textPrimary : LB.textSecondary)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, LB.spaceMD)
            .background(itemBackground)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, LB.spaceSM)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }

    private var iconView: some View {
        Group {
            // Try SF Symbol; if the name contains non-ASCII it's an emoji
            if icon.unicodeScalars.allSatisfy({ $0.isASCII || $0.value == 0x2E }) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? LB.accent : iconColor)
            } else {
                Text(icon)
                    .font(.system(size: 11))
            }
        }
        .frame(width: 20, height: 20)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(iconColor.opacity(isActive ? 0.22 : 0.13))
        )
    }

    private var itemBackground: some View {
        RoundedRectangle(cornerRadius: LB.radiusMD)
            .fill(
                isActive
                    ? LB.accentDim
                    : isHovered
                        ? Color.white.opacity(0.07)
                        : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: LB.radiusMD)
                    .strokeBorder(
                        isActive ? LB.accent.opacity(0.30) : Color.clear,
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
