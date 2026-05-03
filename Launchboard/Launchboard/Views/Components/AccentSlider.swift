import SwiftUI

/// Accent-colored range slider with a pill track and glowing thumb.
struct AccentSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - thumbDiameter
            let pct    = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbX = max(0, min(usable, pct * usable))

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 4)

                // Fill
                Capsule()
                    .fill(LB.accent)
                    .frame(width: thumbX + thumbDiameter / 2, height: 4)

                // Thumb
                Circle()
                    .fill(LB.accent)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .shadow(color: LB.accentGlow, radius: 6)
                    .offset(x: thumbX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let raw = Double(drag.location.x / usable)
                                    * (range.upperBound - range.lowerBound)
                                    + range.lowerBound
                                let stepped = (raw / step).rounded() * step
                                value = max(range.lowerBound, min(range.upperBound, stepped))
                            }
                    )
            }
        }
        .frame(height: thumbDiameter)
    }

    private let thumbDiameter: CGFloat = 14
}
