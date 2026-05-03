import SwiftUI

struct KbdChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(LB.fontCaption)
            .foregroundStyle(LB.textTertiary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusXS)
                    .fill(LB.windowFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusXS)
                            .strokeBorder(LB.borderMid, lineWidth: 1)
                    )
            )
    }
}
