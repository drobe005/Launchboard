import SwiftUI

struct FavoritesBarView: View {
    @Environment(LibraryViewModel.self) private var library

    private var visibleFavorites: [AppItem] {
        Array(library.favorites.prefix(12))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Rotated "FAVORITES" label
            Text("FAVORITES")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(LB.textTertiary)
                .tracking(1.0)
                .rotationEffect(.degrees(-90))
                .frame(width: 28)
                .fixedSize()

            Rectangle()
                .fill(LB.borderSubtle)
                .frame(width: 1)
                .padding(.vertical, 12)

            if visibleFavorites.isEmpty {
                Text("No favorites yet — right-click any app to add one")
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textDisabled)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(visibleFavorites) { app in
                            FavTile(item: app)
                        }
                    }
                    .padding(.horizontal, LB.spaceSM)
                }
            }
        }
        .frame(height: 84)
        .background(Color.white.opacity(0.015))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LB.borderSubtle)
                .frame(height: 1)
        }
    }
}

// MARK: – Individual favorite tile

private struct FavTile: View {
    let item: AppItem

    @Environment(LibraryViewModel.self) private var library
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 5) {
            AppIconView(item: item, size: 44, cornerRadius: 11)

            Text(item.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isHovered ? LB.textSecondary : LB.textTertiary)
                .lineLimit(1)
                .frame(maxWidth: 52)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: LB.radiusMD)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .offset(y: isHovered ? -2 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { library.selectedAppIDs = [item.id] }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { library.launchApp(item) }
        )
        .contextMenu {
            Button {
                withAnimation { library.toggleFavorite(item) }
            } label: {
                Label("Remove from Favorites", systemImage: "star.slash")
            }
        }
    }
}
