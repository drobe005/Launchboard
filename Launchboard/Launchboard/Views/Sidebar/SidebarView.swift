import SwiftUI

struct SidebarView: View {
    @Environment(LibraryViewModel.self) private var library
    @State private var showAddGroupSheet = false

    var body: some View {
        @Bindable var library = library

        VStack(spacing: 0) {
            // Scrollable nav items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Library")

                    SidebarItemView(
                        icon: "star.fill",
                        iconColor: Color(hex: "#fbbf24"),
                        label: "Favorites",
                        isActive: library.selectedSidebarItem == .favorites,
                        action: { library.selectedSidebarItem = .favorites }
                    )

                    SidebarItemView(
                        icon: "clock.fill",
                        iconColor: LB.accent,
                        label: "Recently Added",
                        isActive: library.selectedSidebarItem == .recentlyAdded,
                        action: { library.selectedSidebarItem = .recentlyAdded }
                    )

                    SidebarItemView(
                        icon: "square.grid.2x2.fill",
                        iconColor: Color(hex: "#8b5cf6"),
                        label: "All Apps",
                        isActive: library.selectedSidebarItem == .allApps,
                        action: { library.selectedSidebarItem = .allApps }
                    )

                    sidebarDivider()

                    sectionLabel("Groups")

                    ForEach(library.groups) { group in
                        SidebarItemView(
                            icon: group.icon,
                            iconColor: Color(hex: group.colorHex),
                            label: group.name,
                            isActive: library.selectedSidebarItem == .group(group.id),
                            action: { library.selectedSidebarItem = .group(group.id) }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation { library.deleteGroup(group.id) }
                            } label: {
                                Label("Delete Group", systemImage: "trash")
                            }
                        }
                    }

                    addGroupButton {
                        showAddGroupSheet = true
                    }
                }
                .padding(.top, LB.spaceSM)
                .padding(.bottom, LB.spaceMD)
            }

            // Pinned settings row
            Divider()
                .overlay(LB.borderSubtle)

            SidebarItemView(
                icon: "gearshape.fill",
                iconColor: Color.white.opacity(0.35),
                label: "Settings",
                isActive: library.showSettings,
                action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        library.showSettings.toggle()
                    }
                }
            )
            .padding(.vertical, LB.spaceSM)
        }
        .frame(width: 210)
        .background(LB.sidebarFill)
        .onReceive(NotificationCenter.default.publisher(for: .showAddGroup)) { _ in
            showAddGroupSheet = true
        }
        .sheet(isPresented: $showAddGroupSheet) {
            AddGroupSheet { newGroup in
                withAnimation { library.addGroup(newGroup) }
            }
        }
    }

    // MARK: – Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(LB.fontLabel)
            .foregroundStyle(LB.textTertiary)
            .tracking(0.8)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .padding(.leading, LB.spaceLG)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sidebarDivider() -> some View {
        Rectangle()
            .fill(LB.borderSubtle)
            .frame(height: 1)
            .padding(.horizontal, LB.spaceMD)
            .padding(.vertical, LB.spaceSM)
    }

    @ViewBuilder
    private func addGroupButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: LB.spaceMD) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LB.accent)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(LB.accent.opacity(0.13))
                    )

                Text("Add Group…")
                    .font(LB.fontBodyMed)
                    .foregroundStyle(LB.accent)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, LB.spaceMD)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, LB.spaceSM)
    }
}

// MARK: – Add Group inline sheet

private struct AddGroupSheet: View {
    let onCreate: (AppGroup) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var colorHex: String = "#5a82ff"
    @State private var icon: String = "folder.fill"

    private let iconOptions = [
        "folder.fill", "paintbrush.fill", "chevron.left.forwardslash.chevron.right",
        "bubble.left.and.bubble.right.fill", "play.rectangle.fill", "checkmark.circle.fill",
        "wrench.and.screwdriver.fill", "doc.fill", "star.fill", "bolt.fill",
    ]
    private let colorOptions = [
        "#5a82ff", "#a78bfa", "#38bdf8", "#fb923c",
        "#f43f5e", "#34d399", "#fbbf24", "#94a3b8",
    ]

    var body: some View {
        VStack(spacing: LB.spaceXL) {
            Text("New Group")
                .font(LB.fontTitle)
                .foregroundStyle(LB.textPrimary)

            VStack(alignment: .leading, spacing: LB.spaceSM) {
                fieldLabel("Name")
                TextField("Group name", text: $name)
                    .textFieldStyle(.plain)
                    .font(LB.fontBody)
                    .foregroundStyle(LB.textPrimary)
                    .padding(LB.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LB.radiusSM)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: LB.radiusSM)
                                    .strokeBorder(LB.borderMid, lineWidth: 1)
                            )
                    )
            }

            VStack(alignment: .leading, spacing: LB.spaceSM) {
                fieldLabel("Color")
                HStack(spacing: LB.spaceSM) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle().strokeBorder(
                                    hex == colorHex ? Color.white.opacity(0.9) : Color.clear,
                                    lineWidth: 2
                                )
                            )
                            .onTapGesture { colorHex = hex }
                    }
                }
            }

            VStack(alignment: .leading, spacing: LB.spaceSM) {
                fieldLabel("Icon")
                LazyVGrid(columns: Array(repeating: .init(.fixed(36)), count: 5), spacing: LB.spaceSM) {
                    ForEach(iconOptions, id: \.self) { sym in
                        Image(systemName: sym)
                            .font(.system(size: 14))
                            .foregroundStyle(sym == icon ? LB.accent : LB.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: LB.radiusSM)
                                    .fill(sym == icon ? LB.accentDim : Color.white.opacity(0.05))
                            )
                            .onTapGesture { icon = sym }
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())

                Spacer()

                Button("Create Group") {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onCreate(AppGroup(name: name.trimmingCharacters(in: .whitespaces), icon: icon, colorHex: colorHex))
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(LB.space2XL)
        .frame(width: 360)
        .glassCard()
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(LB.fontLabel)
            .foregroundStyle(LB.textTertiary)
            .tracking(0.8)
    }
}

// MARK: – Reusable button styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LB.fontBodyMed)
            .foregroundStyle(isEnabled ? .white : LB.textDisabled)
            .padding(.vertical, 7)
            .padding(.horizontal, LB.spaceLG)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusSM)
                    .fill(isEnabled ? LB.accent : LB.accent.opacity(0.3))
                    .shadow(color: isEnabled ? LB.accentGlow : .clear, radius: 12, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LB.fontBodyMed)
            .foregroundStyle(LB.textSecondary)
            .padding(.vertical, 7)
            .padding(.horizontal, LB.spaceLG)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusSM)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusSM)
                            .strokeBorder(LB.borderMid, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
