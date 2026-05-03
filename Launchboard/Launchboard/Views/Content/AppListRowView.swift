import SwiftUI

struct AppListRowView: View {
    let item: AppItem

    @Environment(LibraryViewModel.self) private var library
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: LB.spaceMD) {
            AppIconView(item: item, size: 36, cornerRadius: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(LB.fontBodyMed)
                    .foregroundStyle(isHovered ? LB.textPrimary : LB.textSecondary)

                Text(item.category.rawValue)
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textTertiary)
            }

            Spacer()

            if item.hasBadge {
                Text("New")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(LB.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(LB.accentDim)
                    )
            }

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#fbbf24"))
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, LB.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LB.radiusSM)
                .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { library.selectedAppIDs = [item.id] }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { library.launchApp(item) }
        )
        .contextMenu { contextMenuItems }
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
                    Button(group.name) { library.addApps([item.id], toGroup: group.id) }
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
