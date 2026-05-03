import SwiftUI

struct MainWindowView: View {
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        ZStack {
            LB.bgBase.ignoresSafeArea()
            BackgroundOrbsView().ignoresSafeArea()

            // Window border + glow
            RoundedRectangle(cornerRadius: LB.radius2XL)
                .fill(LB.windowFill)
                .overlay(
                    RoundedRectangle(cornerRadius: LB.radius2XL)
                        .strokeBorder(LB.borderMid, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.60), radius: 80, x: 0, y: 40)

            // Chrome
            VStack(spacing: 0) {
                TitleBarView()

                Rectangle()
                    .fill(LB.borderSubtle)
                    .frame(height: 1)

                HStack(spacing: 0) {
                    SidebarView()

                    Rectangle()
                        .fill(LB.borderSubtle)
                        .frame(width: 1)

                    if library.showSettings {
                        SettingsView()
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 0) {
                            TopBarView()
                            FavoritesBarView()
                            AppGridView()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                    }
                }

                Rectangle()
                    .fill(LB.borderSubtle)
                    .frame(height: 1)

                BottomTabBar()
            }
            .clipShape(RoundedRectangle(cornerRadius: LB.radius2XL))

            // Modals — layered above chrome, inside window clip
            AppSelectModalOverlay()
            SetupModalOverlay()
        }
        .frame(width: 960, height: 668)
        .preferredColorScheme(.dark)
        .onAppear {
            library.checkFirstLaunch()
        }
        .alert(
            "App Not Found",
            isPresented: Binding(
                get: { library.launchErrorApp != nil },
                set: { if !$0 { library.launchErrorApp = nil } }
            ),
            presenting: library.launchErrorApp
        ) { app in
            Button("OK", role: .cancel) { library.launchErrorApp = nil }
        } message: { app in
            Text("\u{201C}\(app.name)\u{201D} could not be found on this Mac.\nCheck that it is installed and try again.")
        }
    }
}

// MARK: – Bottom tab bar

private struct BottomTabBar: View {
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        HStack(spacing: LB.spaceXS) {
            tab(label: "Home", isActive: !library.showSettings) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    library.showSettings = false
                    library.selectedSidebarItem = .allApps
                }
            }
            tab(label: "Setup", isActive: library.showSetupModal) {
                library.showSettings = false
                library.showSetupModal = true
            }
            tab(label: "Settings", isActive: library.showSettings) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    library.showSettings = true
                }
            }
            tab(label: "+ App Select",
                isActive: library.showAppSelectModal,
                isAction: true) {
                library.showSettings = false
                library.showAppSelectModal = true
            }
        }
        .padding(.horizontal, LB.spaceLG)
        .frame(height: 48)
        .background(Color.white.opacity(0.015))
    }

    @ViewBuilder
    private func tab(
        label: String,
        isActive: Bool,
        isAction: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                .foregroundStyle(
                    isActive   ? LB.textPrimary :
                    isAction   ? LB.accent       :
                                 LB.textTertiary
                )
                .padding(.horizontal, LB.spaceMD)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActive ? Color.white.opacity(0.10) : Color.clear)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isActive ? LB.borderMid : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isActive)
    }
}

// MARK: – Title bar

private struct TitleBarView: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 72)
            Spacer()
            Text("Launchboard")
                .font(LB.fontBodyMed)
                .foregroundStyle(LB.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                KbdChip(label: "⌥")
                KbdChip(label: "Space")
            }
            .padding(.trailing, LB.spaceLG)
        }
        .frame(height: 40)
    }
}

#Preview {
    MainWindowView()
        .environment(LibraryViewModel())
        .environment(SettingsViewModel())
}
