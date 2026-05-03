import SwiftUI

/// Multi-option segmented control styled to the Launchboard design language.
struct LBSegmentedControl<T: Hashable & CustomStringConvertible>: View {
    @Binding var selection: T
    let options: [T]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let active = selection == option
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = option }
                } label: {
                    Text(option.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(active ? .white : LB.textSecondary)
                        .padding(.horizontal, LB.spaceMD)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: LB.radiusXS)
                                .fill(active ? LB.accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: LB.radiusSM)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .strokeBorder(LB.borderSubtle, lineWidth: 1)
                )
        )
    }
}

// Let enums with rawValue String automatically satisfy CustomStringConvertible
extension CustomStringConvertible where Self: RawRepresentable, RawValue == String {
    var description: String { rawValue }
}
