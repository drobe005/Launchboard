import SwiftUI

/// 38×22pt pill toggle that matches the Launchboard design spec.
struct GlassToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? LB.accent : Color.white.opacity(0.12))
                .overlay(Capsule().strokeBorder(LB.borderSubtle, lineWidth: 1))
                .frame(width: 38, height: 22)

            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
                .padding(3)
                .shadow(color: .black.opacity(0.30), radius: 2, x: 0, y: 1)
        }
        .frame(width: 38, height: 22)
        .animation(.spring(response: 0.25, dampingFraction: 0.80), value: isOn)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) { isOn.toggle() }
        }
    }
}
