import SwiftUI

// MARK: – Overlay wrapper

struct SetupModalOverlay: View {
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        if library.showSetupModal {
            ZStack {
                Color.black.opacity(0.60)
                    .ignoresSafeArea()

                SetupModal()
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal:   .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: library.showSetupModal)
        }
    }
}

// MARK: – Modal

private struct SetupModal: View {
    @Environment(LibraryViewModel.self) private var library

    @State private var step: Int = 0
    @State private var slideForward = true

    // Step 1 state — which suggested groups to keep
    @State private var keepGroupIDs: Set<UUID> = Set(SeedData.groups.map(\.id))

    // Step 2 state — which apps to favorite (pre-seeded with current favorites)
    @State private var favoriteIDs: Set<UUID>

    // Step 3 state — global shortcut
    @State private var shortcut: String = "⌥Space"
    @State private var isRecording: Bool = false

    init() {
        _favoriteIDs = State(initialValue: Set(SeedData.apps.filter(\.isFavorite).map(\.id)))
    }

    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            stepContent
                .frame(minHeight: 340)
            footerBar
        }
        .frame(width: 560)
        .fixedSize(horizontal: true, vertical: true)
        .background(glassBackground)
        .shadow(color: .black.opacity(0.70), radius: 80, x: 0, y: 40)
        .shadow(color: LB.accent.opacity(0.08), radius: 120)
    }

    // MARK: – Header

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set up Launchboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LB.textPrimary)

                Text("Step \(step + 1) of \(totalSteps)")
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textTertiary)
            }

            Spacer()

            // Step indicator dots
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i == step ? LB.accent : LB.borderMid)
                        .frame(width: i == step ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: step)
                }
            }
        }
        .padding(.horizontal, LB.space2XL)
        .padding(.top, LB.space2XL)
        .padding(.bottom, LB.spaceLG)
    }

    // MARK: – Step content with slide transition

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            switch step {
            case 0:
                Step1View(keepGroupIDs: $keepGroupIDs)
                    .id("step0")
                    .transition(stepTransition)
            case 1:
                Step2View(favoriteIDs: $favoriteIDs)
                    .id("step1")
                    .transition(stepTransition)
            default:
                Step3View(shortcut: $shortcut, isRecording: $isRecording)
                    .id("step2")
                    .transition(stepTransition)
            }
        }
        .padding(.horizontal, LB.space2XL)
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideForward ? .trailing : .leading).combined(with: .opacity),
            removal:   .move(edge: slideForward ? .leading  : .trailing).combined(with: .opacity)
        )
    }

    // MARK: – Footer

    private var footerBar: some View {
        HStack {
            // Back / Skip
            if step > 0 {
                Button("Back") { navigate(forward: false) }
                    .buttonStyle(SecondaryButtonStyle())
            } else {
                Button("Skip Setup") {
                    library.completeSetup(
                        keepGroupIDs: keepGroupIDs,
                        favoriteIDs: favoriteIDs,
                        shortcut: shortcut
                    )
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Spacer()

            // Continue / Done
            if step < totalSteps - 1 {
                Button("Continue") { navigate(forward: true) }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Done") {
                    library.completeSetup(
                        keepGroupIDs: keepGroupIDs,
                        favoriteIDs: favoriteIDs,
                        shortcut: shortcut
                    )
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, LB.space2XL)
        .padding(.vertical, LB.spaceLG)
        .overlay(alignment: .top) {
            Rectangle().fill(LB.borderSubtle).frame(height: 1)
        }
    }

    private func navigate(forward: Bool) {
        slideForward = forward
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            step = forward ? step + 1 : step - 1
        }
    }

    // MARK: – Glass background

    private var glassBackground: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
            Color(hex: "#16162a").opacity(0.65)
        }
        .clipShape(RoundedRectangle(cornerRadius: LB.radius2XL))
        .overlay(
            RoundedRectangle(cornerRadius: LB.radius2XL)
                .strokeBorder(LB.borderMid, lineWidth: 1)
        )
    }
}

// MARK: – Step 1: Suggested Groups

private struct Step1View: View {
    @Binding var keepGroupIDs: Set<UUID>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: LB.spaceLG) {
            stepHeader(
                icon: "square.grid.2x2.fill",
                iconColor: LB.accent,
                title: "Suggested Groups",
                body: "We\u{2019}ve created groups based on common workflows. Toggle the ones you want to keep \u{2014} you can always add more later."
            )

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(SeedData.groups) { group in
                    GroupCard(
                        group: group,
                        isSelected: keepGroupIDs.contains(group.id)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if keepGroupIDs.contains(group.id) {
                                keepGroupIDs.remove(group.id)
                            } else {
                                keepGroupIDs.insert(group.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct GroupCard: View {
    let group: AppGroup
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    private var appNames: [String] {
        SeedData.apps
            .filter { group.appIDs.contains($0.id) }
            .map(\.name)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LB.spaceSM) {
                HStack {
                    Image(systemName: group.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? Color(hex: group.colorHex) : LB.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: group.colorHex).opacity(isSelected ? 0.20 : 0.08))
                        )

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? LB.accent : LB.textDisabled)
                }

                Text(group.name)
                    .font(LB.fontBodyMed)
                    .foregroundStyle(isSelected ? LB.textPrimary : LB.textSecondary)

                Text(appNames.joined(separator: "\n"))
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textTertiary)
                    .lineSpacing(3)
                    .lineLimit(4)
            }
            .padding(LB.spaceMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusLG)
                    .fill(isSelected
                          ? LB.accentDim
                          : isHovered
                            ? Color.white.opacity(0.06)
                            : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusLG)
                            .strokeBorder(
                                isSelected ? LB.accent.opacity(0.30) : LB.borderMid,
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: – Step 2: Pin Favorites

private struct Step2View: View {
    @Binding var favoriteIDs: Set<UUID>

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]
    private let maxFavorites = 12

    var body: some View {
        VStack(alignment: .leading, spacing: LB.spaceLG) {
            stepHeader(
                icon: "star.fill",
                iconColor: Color(hex: "#fbbf24"),
                title: "Pin Favorites",
                body: "Tap apps to pin them to the Favorites bar at the top of your library. You can pin up to \(maxFavorites)."
            )

            // Count hint
            HStack {
                Text("\(favoriteIDs.count) of \(maxFavorites) pinned")
                    .font(LB.fontCaption)
                    .foregroundStyle(favoriteIDs.count == maxFavorites ? LB.warning : LB.textTertiary)
                    .animation(.easeInOut(duration: 0.15), value: favoriteIDs.count)
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(SeedData.apps.sorted { $0.name < $1.name }) { app in
                    FavoritePinTile(
                        item: app,
                        isSelected: favoriteIDs.contains(app.id),
                        isDisabled: !favoriteIDs.contains(app.id) && favoriteIDs.count >= maxFavorites
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if favoriteIDs.contains(app.id) {
                                favoriteIDs.remove(app.id)
                            } else if favoriteIDs.count < maxFavorites {
                                favoriteIDs.insert(app.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct FavoritePinTile: View {
    let item: AppItem
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    AppIconView(item: item, size: 48, cornerRadius: 12)
                        .opacity(isDisabled ? 0.30 : (isSelected ? 1.0 : 0.50))

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(LB.accent)
                                .frame(width: 16, height: 16)
                                .shadow(color: LB.accentGlow, radius: 4)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 4, y: -4)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(item.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? LB.textPrimary : LB.textTertiary)
                    .lineLimit(1)
                    .frame(maxWidth: 64)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusSM)
                    .fill(isSelected
                          ? LB.accentDim
                          : isHovered && !isDisabled
                            ? Color.white.opacity(0.06)
                            : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusSM)
                            .strokeBorder(isSelected ? LB.accent.opacity(0.40) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

// MARK: – Step 3: Global Shortcut

private struct Step3View: View {
    @Binding var shortcut: String
    @Binding var isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LB.spaceLG) {
            stepHeader(
                icon: "command",
                iconColor: LB.success,
                title: "Global Shortcut",
                body: "Press this shortcut anywhere on your Mac to instantly show or hide Launchboard, even when another app is in the foreground."
            )

            // Shortcut display
            VStack(spacing: LB.spaceMD) {
                HStack(spacing: LB.spaceSM) {
                    ForEach(shortcutParts, id: \.self) { part in
                        Text(part)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(LB.textPrimary)
                            .padding(.horizontal, LB.spaceLG)
                            .padding(.vertical, LB.spaceSM)
                            .background(
                                RoundedRectangle(cornerRadius: LB.radiusSM)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LB.radiusSM)
                                            .strokeBorder(LB.borderMid, lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(LB.spaceLG)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: LB.radiusLG)
                        .fill(isRecording ? LB.accentDim : Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: LB.radiusLG)
                                .strokeBorder(
                                    isRecording ? LB.borderActive : LB.borderSubtle,
                                    lineWidth: 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isRecording)

                if isRecording {
                    Text("Press your key combination now\u{2026}")
                        .font(LB.fontCaption)
                        .foregroundStyle(LB.accent)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Button("Record New Shortcut") {
                        withAnimation { isRecording = true }
                        // Full hotkey recording wired in Step 14 (HotkeyService)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isRecording = false }
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            // In-app shortcuts reference
            VStack(spacing: 0) {
                shortcutRow(keys: ["⌘", "F"],    action: "Focus search")
                shortcutRow(keys: ["↵"],          action: "Launch selected app")
                shortcutRow(keys: ["Esc"],        action: "Clear search / close")
                shortcutRow(keys: ["⌘", "N"],    action: "New group")
                shortcutRow(keys: ["⌘", "D"],    action: "Add to favorites")
            }
            .background(
                RoundedRectangle(cornerRadius: LB.radiusLG)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusLG)
                            .strokeBorder(LB.borderSubtle, lineWidth: 1)
                    )
            )
        }
    }

    private var shortcutParts: [String] {
        // Split "⌥Space" → ["⌥", "Space"]
        var parts: [String] = []
        var current = ""
        for ch in shortcut {
            if ch.unicodeScalars.allSatisfy({ $0.value > 127 }) {
                // modifier symbol
                if !current.isEmpty { parts.append(current); current = "" }
                parts.append(String(ch))
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { parts.append(current) }
        return parts.isEmpty ? [shortcut] : parts
    }

    @ViewBuilder
    private func shortcutRow(keys: [String], action: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { KbdChip(label: $0) }
            }
            Text(action)
                .font(LB.fontBody)
                .foregroundStyle(LB.textSecondary)
            Spacer()
        }
        .padding(.horizontal, LB.spaceMD)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(LB.borderSubtle).frame(height: 1)
                .padding(.horizontal, LB.spaceMD)
        }
    }
}

// MARK: – Shared step header

@ViewBuilder
private func stepHeader(
    icon: String,
    iconColor: Color,
    title: String,
    body: String
) -> some View {
    HStack(alignment: .top, spacing: LB.spaceMD) {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(iconColor)
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusMD)
                    .fill(iconColor.opacity(0.15))
            )

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LB.fontBodyMed)
                .foregroundStyle(LB.textPrimary)

            Text(body)
                .font(LB.fontBody)
                .foregroundStyle(LB.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
