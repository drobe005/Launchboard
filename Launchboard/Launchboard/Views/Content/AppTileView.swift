import SwiftUI

struct AppTileView: View {
    let item: AppItem
    var isSearching: Bool = false

    @Environment(LibraryViewModel.self) private var library
    @State private var isHovered = false

    private var isSelected: Bool  { library.selectedAppIDs.contains(item.id) }
    private var isFocused: Bool   { library.focusedAppID == item.id }
    private var matchesSearch: Bool { library.matchesSearch(item) }
    private var isFaded: Bool { isSearching && !matchesSearch }

    var body: some View {
        VStack(spacing: 6) {
            AppIconView(item: item)

            if library.settings.showAppNames {
                Text(item.name)
                    .font(LB.fontAppName)
                    .foregroundStyle(isHovered ? LB.textPrimary : LB.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 80)
            }
        }
        .padding(6)
        .background(tileBackground)
        .opacity(isFaded ? 0.2 : 1.0)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .offset(y: isHovered ? -1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isFaded)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isHovered = hovering }
        }
        .onTapGesture { handleSingleTap() }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { library.launchApp(item) }
        )
        .contextMenu { contextMenuItems }
    }

    // MARK: – Helpers

    private func handleSingleTap() {
        if library.selectedAppIDs.contains(item.id) {
            library.selectedAppIDs.remove(item.id)
        } else {
            library.selectedAppIDs = [item.id]
        }
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: LB.radiusXL)
            .fill(
                isSelected || isFocused
                    ? LB.accentDim
                    : isHovered
                        ? Color.white.opacity(0.08)
                        : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: LB.radiusXL)
                    .strokeBorder(
                        isFocused
                            ? LB.accent
                            : isSelected
                                ? LB.accent.opacity(0.50)
                                : Color.clear,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .animation(.easeInOut(duration: 0.10), value: isFocused)
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            withAnimation { library.toggleFavorite(item) }
        } label: {
            Label(
                item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: item.isFavorite ? "star.slash" : "star"
            )
        }

        if !library.groups.isEmpty {
            Menu("Add to Group\u{2026}") {
                ForEach(library.groups) { group in
                    Button(group.name) {
                        library.addApps([item.id], toGroup: group.id)
                    }
                }
            }
        }

        Divider()

        Button(role: .destructive) {
            withAnimation { library.hideApp(item.id) }
        } label: {
            Label("Hide from Library", systemImage: "eye.slash")
        }
    }
}
