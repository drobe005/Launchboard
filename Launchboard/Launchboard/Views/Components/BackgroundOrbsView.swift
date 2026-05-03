import SwiftUI

struct BackgroundOrbsView: View {
    @State private var floating = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Orb 1 — top-left, blue-purple
                Ellipse()
                    .fill(Color(hex: "#5a30ff").opacity(0.35))
                    .frame(width: 500, height: 500)
                    .blur(radius: 80)
                    .offset(x: -80, y: floating ? -130 : -100)

                // Orb 2 — bottom-right, violet
                Ellipse()
                    .fill(Color(hex: "#9030cc").opacity(0.35))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(
                        x: geo.size.width - 340 + 60,
                        y: geo.size.height - 340 + (floating ? 50 : 80)
                    )

                // Orb 3 — center-low, indigo
                Ellipse()
                    .fill(Color(hex: "#3050cc").opacity(0.35))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(
                        x: geo.size.width * 0.3 - 150,
                        y: geo.size.height * 0.8 - 150 + (floating ? -30 : 0)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }
}
