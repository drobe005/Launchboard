import SwiftUI

// MARK: – Root

struct SettingsView: View {
    @Environment(LibraryViewModel.self)  private var library
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        @Bindable var settingsVM = settingsVM

        HStack(spacing: 0) {
            settingsSidebar(selection: $settingsVM.selectedTab)

            Rectangle().fill(LB.borderSubtle).frame(width: 1)

            ScrollView(.vertical, showsIndicators: false) {
                tabContent(settingsVM.selectedTab)
                    .padding(LB.spaceXL)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .animation(.easeInOut(duration: 0.18), value: settingsVM.selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Inner sidebar

    @ViewBuilder
    private func settingsSidebar(selection: Binding<SettingsViewModel.SettingsTab>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsViewModel.SettingsTab.allCases) { tab in
                let active = selection.wrappedValue == tab
                Button { selection.wrappedValue = tab } label: {
                    HStack(spacing: LB.spaceSM) {
                        Image(systemName: tab.sfSymbol)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(active ? LB.accent : LB.textTertiary)
                            .frame(width: 20)
                        Text(tab.rawValue)
                            .font(LB.fontBodyMed)
                            .foregroundStyle(active ? LB.textPrimary : LB.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, LB.spaceMD)
                    .background(
                        RoundedRectangle(cornerRadius: LB.radiusMD)
                            .fill(active ? LB.accentDim : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: LB.radiusMD)
                                    .strokeBorder(active ? LB.accent.opacity(0.30) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, LB.spaceSM)
                .animation(.easeInOut(duration: 0.15), value: active)
            }
            Spacer()
        }
        .padding(.top, LB.spaceMD)
        .frame(width: 160)
        .background(LB.sidebarFill)
    }

    // MARK: – Tab routing

    @ViewBuilder
    private func tabContent(_ tab: SettingsViewModel.SettingsTab) -> some View {
        switch tab {
        case .general:    GeneralTab()
        case .appearance: AppearanceTab()
        case .library:    LibraryTab()
        case .shortcuts:  ShortcutsTab()
        case .about:      AboutTab()
        }
    }
}

// MARK: – Shared row builder

private struct SettingRow<Control: View>: View {
    let label: String
    var caption: String? = nil
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(LB.fontBody)
                    .foregroundStyle(LB.textPrimary)
                if let caption {
                    Text(caption)
                        .font(LB.fontCaption)
                        .foregroundStyle(LB.textTertiary)
                }
            }
            Spacer()
            control()
        }
        .padding(.vertical, LB.spaceMD)
        .overlay(alignment: .bottom) {
            Rectangle().fill(LB.borderSubtle).frame(height: 1)
        }
    }
}

private func sectionHeader(_ title: String) -> some View {
    Text(title.uppercased())
        .font(LB.fontLabel)
        .foregroundStyle(LB.textTertiary)
        .tracking(0.8)
        .padding(.top, LB.spaceLG)
        .padding(.bottom, LB.spaceXS)
        .frame(maxWidth: .infinity, alignment: .leading)
}

// MARK: – General Tab

private struct GeneralTab: View {
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        @Bindable var library = library

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Behavior")

            SettingRow(label: "Hide window after launching app") {
                GlassToggle(isOn: $library.settings.hideWindowAfterLaunch)
            }
            SettingRow(
                label: "Show menu bar icon",
                caption: "Keep Launchboard accessible from the menu bar"
            ) {
                GlassToggle(isOn: $library.settings.showMenuBarIcon)
            }
            SettingRow(label: "Launch at login") {
                GlassToggle(isOn: $library.settings.launchAtLogin)
            }

            sectionHeader("Library")

            SettingRow(
                label: "Recently added window",
                caption: "Apps added within this many days appear in Recently Added"
            ) {
                Menu("\(library.settings.recentlyAddedDays) days") {
                    ForEach([7, 14, 30, 60], id: \.self) { days in
                        Button("\(days) days") { library.settings.recentlyAddedDays = days }
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .padding(.horizontal, LB.spaceSM)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .fill(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: LB.radiusSM)
                            .strokeBorder(LB.borderSubtle, lineWidth: 1))
                )
            }

            SettingRow(label: "Default view") {
                LBSegmentedControl(
                    selection: $library.settings.defaultView,
                    options: ViewMode.allCases
                )
            }

            SettingRow(label: "Default sort") {
                Menu(library.settings.defaultSort.rawValue) {
                    ForEach(SortMode.allCases) { mode in
                        Button(mode.rawValue) { library.settings.defaultSort = mode }
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .padding(.horizontal, LB.spaceSM)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .fill(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: LB.radiusSM)
                            .strokeBorder(LB.borderSubtle, lineWidth: 1))
                )
            }
        }
        .onChange(of: library.settings) { library.save() }
    }
}

// MARK: – Appearance Tab

private struct AppearanceTab: View {
    @Environment(LibraryViewModel.self) private var library

    private let accentPresets = [
        "#5a82ff", "#a78bfa", "#34d399", "#fbbf24",
        "#f43f5e", "#fb923c",
    ]

    var body: some View {
        @Bindable var library = library

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Theme")

            SettingRow(label: "Appearance") {
                LBSegmentedControl(
                    selection: $library.settings.theme,
                    options: AppTheme.allCases
                )
            }

            sectionHeader("Accent Color")

            // Swatch row
            HStack(spacing: LB.spaceSM) {
                ForEach(accentPresets, id: \.self) { hex in
                    let selected = library.settings.accentColorHex == hex
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(selected ? 0.9 : 0), lineWidth: 2)
                                .padding(-3)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color(hex: hex).opacity(selected ? 0.6 : 0), lineWidth: 4)
                                .padding(-6)
                        )
                        .onTapGesture {
                            withAnimation { library.settings.accentColorHex = hex }
                        }
                }
                Spacer()
            }
            .padding(.vertical, LB.spaceMD)
            .overlay(alignment: .bottom) {
                Rectangle().fill(LB.borderSubtle).frame(height: 1)
            }

            sectionHeader("Icons")

            SettingRow(
                label: "Icon size",
                caption: "\(Int(library.settings.iconSize)) pt"
            ) {
                AccentSlider(value: $library.settings.iconSize, range: 40...80, step: 4)
                    .frame(width: 140)
            }

            SettingRow(label: "Show app names") {
                GlassToggle(isOn: $library.settings.showAppNames)
            }

            sectionHeader("Motion")

            SettingRow(
                label: "Reduce motion",
                caption: "Disables spring animations and transitions"
            ) {
                GlassToggle(isOn: $library.settings.reduceMotion)
            }
        }
        .onChange(of: library.settings) { library.save() }
    }
}

// MARK: – Library Tab

private struct LibraryTab: View {
    @Environment(LibraryViewModel.self) private var library
    @State private var isScanning = false

    private let defaultLocations = [
        "/Applications",
        "/System/Applications",
        (NSHomeDirectory() as NSString).appendingPathComponent("Applications"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Scan Locations")

            VStack(spacing: 0) {
                ForEach(defaultLocations, id: \.self) { path in
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(LB.accent)
                        Text(path)
                            .font(LB.fontMono)
                            .foregroundStyle(LB.textSecondary)
                        Spacer()
                        Button("Remove") {}
                            .font(LB.fontCaption)
                            .foregroundStyle(LB.danger)
                            .buttonStyle(.plain)
                    }
                    .padding(.vertical, LB.spaceSM)
                    .padding(.horizontal, LB.spaceMD)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(LB.borderSubtle).frame(height: 1)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: LB.radiusLG)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: LB.radiusLG)
                        .strokeBorder(LB.borderSubtle, lineWidth: 1))
            )
            .padding(.vertical, LB.spaceSM)

            Button("+ Add Location\u{2026}") {}
                .buttonStyle(SecondaryButtonStyle())
                .padding(.bottom, LB.spaceMD)

            // Hint callout
            HStack(spacing: LB.spaceSM) {
                Text("💡")
                Text("Launchboard scans these folders at launch and when you tap Rescan. Apps in subdirectories are included one level deep.")
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textSecondary)
                    .lineSpacing(3)
            }
            .padding(LB.spaceMD)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusLG)
                    .fill(LB.accent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: LB.radiusLG)
                        .strokeBorder(LB.borderActive, lineWidth: 1))
            )
            .padding(.bottom, LB.spaceLG)

            sectionHeader("Hidden Apps")

            if library.hiddenApps.isEmpty {
                Text("No hidden apps")
                    .font(LB.fontBody)
                    .foregroundStyle(LB.textDisabled)
                    .padding(.vertical, LB.spaceMD)
            } else {
                VStack(spacing: 0) {
                    ForEach(library.hiddenApps) { app in
                        HStack {
                            AppIconView(item: app, size: 28, cornerRadius: 7)
                            Text(app.name)
                                .font(LB.fontBody)
                                .foregroundStyle(LB.textSecondary)
                            Spacer()
                            Button("Restore") {
                                withAnimation { library.restoreApp(app.id) }
                            }
                            .font(LB.fontCaption)
                            .foregroundStyle(LB.accent)
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, LB.spaceSM)
                        .padding(.horizontal, LB.spaceMD)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(LB.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: LB.radiusLG)
                        .fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: LB.radiusLG)
                            .strokeBorder(LB.borderSubtle, lineWidth: 1))
                )
                .padding(.vertical, LB.spaceSM)
            }

            Divider().overlay(LB.borderSubtle).padding(.vertical, LB.spaceMD)

            HStack {
                Button {
                    Task {
                        isScanning = true
                        await library.refreshFromSystem()
                        isScanning = false
                    }
                } label: {
                    HStack(spacing: LB.spaceSM) {
                        if isScanning {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                        }
                        Text(isScanning ? "Scanning\u{2026}" : "\u{21BA} Rescan Now")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isScanning)

                Spacer()
            }
        }
    }
}

// MARK: – Shortcuts Tab

private struct ShortcutsTab: View {
    @Environment(LibraryViewModel.self) private var library
    @State private var isRecording = false

    var body: some View {
        @Bindable var library = library

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Global Shortcut")

            SettingRow(
                label: "Show / hide Launchboard",
                caption: "Works system-wide, even when another app is focused"
            ) {
                HStack(spacing: LB.spaceSM) {
                    KbdChip(label: library.settings.globalShortcut)
                    Button(isRecording ? "Recording\u{2026}" : "Record") {
                        withAnimation { isRecording = true }
                        // Full wiring in Step 14 (HotkeyService)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isRecording = false }
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isRecording)
                }
            }

            // Conflict banner — shown when another app owns the shortcut
            if isRecording {
                HStack(spacing: LB.spaceSM) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(LB.warning)
                        .font(.system(size: 13))
                    Text("Press your desired key combination now. Press Esc to cancel.")
                        .font(.system(size: 12))
                        .foregroundStyle(LB.textSecondary)
                }
                .padding(LB.spaceMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: LB.radiusLG)
                        .fill(LB.warning.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: LB.radiusLG)
                            .strokeBorder(LB.warning.opacity(0.30), lineWidth: 1))
                )
                .padding(.vertical, LB.spaceSM)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            sectionHeader("In-App Shortcuts")

            let shortcuts: [(keys: [String], action: String)] = [
                (["⌘", "F"],  "Focus search"),
                (["↵"],       "Launch selected app"),
                (["Esc"],     "Clear search / close modal"),
                (["⌘", "N"],  "New group"),
                (["⌘", "D"],  "Toggle favorite"),
                (["↑↓←→"],   "Navigate grid"),
                (["⌘", ","],  "Open Settings"),
            ]

            VStack(spacing: 0) {
                ForEach(shortcuts, id: \.action) { row in
                    HStack {
                        HStack(spacing: 4) {
                            ForEach(row.keys, id: \.self) { KbdChip(label: $0) }
                        }
                        Text(row.action)
                            .font(LB.fontBody)
                            .foregroundStyle(LB.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal, LB.spaceMD)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(LB.borderSubtle).frame(height: 1)
                            .padding(.horizontal, LB.spaceMD)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: LB.radiusLG)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: LB.radiusLG)
                        .strokeBorder(LB.borderSubtle, lineWidth: 1))
            )
            .padding(.top, LB.spaceSM)
        }
    }
}

// MARK: – About Tab

private struct AboutTab: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: LB.spaceXL) {
            Spacer().frame(height: LB.spaceLG)

            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LB.gradient("c0"))
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.45), radius: 20, x: 0, y: 8)

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white.opacity(0.90))
            }

            VStack(spacing: 6) {
                Text("Launchboard")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LB.textPrimary)

                Text("Version \(version) (\(build))")
                    .font(LB.fontBody)
                    .foregroundStyle(LB.textTertiary)
            }

            Text("A fast, beautiful macOS app launcher. Organize your apps into groups, pin favorites, and launch anything with a keystroke.")
                .font(LB.fontBody)
                .foregroundStyle(LB.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 320)

            Button("Check for Updates") {}
                .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Text("Built with Swift + SwiftUI · macOS 14+")
                .font(LB.fontCaption)
                .foregroundStyle(LB.textDisabled)
        }
        .frame(maxWidth: .infinity)
    }
}
