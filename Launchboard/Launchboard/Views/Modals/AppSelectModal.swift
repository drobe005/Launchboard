import SwiftUI

// MARK: – Public entry point

/// Full-screen overlay modal for selecting apps to add to a group.
/// Present by setting `library.showAppSelectModal = true` while
/// `library.selectedSidebarItem` is `.group(id)`.
struct AppSelectModalOverlay: View {
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        if library.showAppSelectModal {
            ZStack {
                // Backdrop
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { close() }

                AppSelectModal(onDismiss: close)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal:   .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: library.showAppSelectModal)
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            library.showAppSelectModal = false
        }
    }
}

// MARK: – Modal body

private struct AppSelectModal: View {
    let onDismiss: () -> Void

    @Environment(LibraryViewModel.self) private var library

    @State private var query: String        = ""
    @State private var activeCategory: AppCategory = .all
    @State private var selectedIDs: Set<UUID> = []
    @FocusState private var searchFocused: Bool

    // Apps already in the target group (so we can pre-exclude them)
    private var existingIDs: Set<UUID> {
        guard case .group(let id) = library.selectedSidebarItem,
              let group = library.groups.first(where: { $0.id == id })
        else { return [] }
        return Set(group.appIDs)
    }

    private var availableApps: [AppItem] {
        library.apps
            .filter { !existingIDs.contains($0.id) }
            .filter { activeCategory == .all || $0.category == activeCategory }
            .filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
            .sorted { $0.name < $1.name }
    }

    private var groupName: String {
        guard case .group(let id) = library.selectedSidebarItem,
              let group = library.groups.first(where: { $0.id == id })
        else { return "Group" }
        return group.name
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            searchRow
            categoryTabs
            appGrid
            footerBar
        }
        .frame(width: 560)
        .fixedSize(horizontal: true, vertical: true)
        .background(glassBackground)
        .shadow(color: .black.opacity(0.70), radius: 80, x: 0, y: 40)
        .shadow(color: LB.accent.opacity(0.08), radius: 120, x: 0, y: 0)
        .onAppear { searchFocused = true }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    // MARK: – Header

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add to \u{201C}\(groupName)\u{201D}")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LB.textPrimary)

                Text(selectedIDs.isEmpty
                     ? "Select apps to add"
                     : "\(selectedIDs.count) selected")
                    .font(LB.fontCaption)
                    .foregroundStyle(selectedIDs.isEmpty ? LB.textTertiary : LB.accent)
                    .animation(.easeInOut(duration: 0.15), value: selectedIDs.count)
            }

            Spacer()

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LB.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().strokeBorder(LB.borderMid, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LB.space2XL)
        .padding(.top, LB.space2XL)
        .padding(.bottom, LB.spaceLG)
    }

    // MARK: – Search

    private var searchRow: some View {
        HStack(spacing: LB.spaceSM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LB.textTertiary)

            TextField("Search apps\u{2026}", text: $query)
                .textFieldStyle(.plain)
                .font(LB.fontBody)
                .foregroundStyle(LB.textPrimary)
                .focused($searchFocused)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(LB.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, LB.spaceMD)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: LB.radiusSM)
                .fill(searchFocused ? Color.white.opacity(0.10) : Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .strokeBorder(searchFocused ? LB.borderActive : LB.borderMid, lineWidth: 1)
                )
                .shadow(color: searchFocused ? LB.accent.opacity(0.25) : .clear, radius: 6)
        )
        .padding(.horizontal, LB.space2XL)
        .animation(.easeInOut(duration: 0.2), value: searchFocused)
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
    }

    // MARK: – Category tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(AppCategory.allCases) { cat in
                    categoryTab(cat)
                }
            }
            .padding(.horizontal, LB.space2XL)
        }
        .padding(.top, LB.spaceMD)
        .padding(.bottom, LB.spaceSM)
    }

    @ViewBuilder
    private func categoryTab(_ cat: AppCategory) -> some View {
        let isActive = activeCategory == cat
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { activeCategory = cat }
        } label: {
            Text(cat.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? .white : LB.textTertiary)
                .fixedSize()
                .padding(.vertical, 4)
                .padding(.horizontal, LB.spaceMD)
                .background(
                    Capsule()
                        .fill(isActive ? LB.accent.opacity(0.25) : Color.white.opacity(0.04))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isActive ? LB.accent.opacity(0.35) : LB.borderMid,
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: – App grid

    private var appGrid: some View {
        Group {
            if availableApps.isEmpty {
                emptyState
                    .frame(height: 200)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 72), spacing: 4)],
                        spacing: 4
                    ) {
                        ForEach(availableApps) { app in
                            ModalAppTile(
                                item: app,
                                isSelected: selectedIDs.contains(app.id)
                            ) {
                                toggleSelection(app.id)
                            }
                        }
                    }
                    .padding(.horizontal, LB.space2XL)
                    .padding(.vertical, LB.spaceSM)
                }
                .frame(maxHeight: 280)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: availableApps.map(\.id))
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: LB.spaceSM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(LB.textTertiary)
            Text("No apps match your search")
                .font(LB.fontBody)
                .foregroundStyle(LB.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Footer

    private var footerBar: some View {
        HStack {
            // Esc hint
            HStack(spacing: 4) {
                KbdChip(label: "Esc")
                Text("to cancel")
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textDisabled)
            }

            Spacer()

            Button("Cancel", action: onDismiss)
                .buttonStyle(SecondaryButtonStyle())

            Button(addButtonLabel) {
                commitSelection()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedIDs.isEmpty)
        }
        .padding(.horizontal, LB.space2XL)
        .padding(.vertical, LB.spaceLG)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(LB.borderSubtle)
                .frame(height: 1)
        }
    }

    private var addButtonLabel: String {
        selectedIDs.isEmpty
            ? "Add Apps"
            : "Add \(selectedIDs.count) App\(selectedIDs.count == 1 ? "" : "s")"
    }

    // MARK: – Actions

    private func toggleSelection(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.12)) {
            if selectedIDs.contains(id) {
                selectedIDs.remove(id)
            } else {
                selectedIDs.insert(id)
            }
        }
    }

    private func commitSelection() {
        guard case .group(let groupID) = library.selectedSidebarItem else { return }
        library.addApps(Array(selectedIDs), toGroup: groupID)
        onDismiss()
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

// MARK: – Individual modal tile

private struct ModalAppTile: View {
    let item: AppItem
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    AppIconView(item: item, size: 48, cornerRadius: 12)

                    if isSelected {
                        checkmark
                            .offset(x: 4, y: -4)
                    }
                }

                Text(item.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? LB.textPrimary : LB.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: 64)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusSM)
                    .fill(
                        isSelected
                            ? LB.accent.opacity(0.18)
                            : isHovered
                                ? Color.white.opacity(0.08)
                                : Color.clear
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusSM)
                            .strokeBorder(
                                isSelected ? LB.accent.opacity(0.40) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.12), value: isSelected)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .fill(LB.accent)
                .frame(width: 16, height: 16)
                .shadow(color: LB.accentGlow, radius: 4)

            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
        .transition(.scale.combined(with: .opacity))
    }
}
