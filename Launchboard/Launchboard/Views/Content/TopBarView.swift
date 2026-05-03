import SwiftUI

struct TopBarView: View {
    @Environment(LibraryViewModel.self) private var library
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var library = library

        HStack(spacing: LB.spaceSM) {
            // Search field
            SearchField(query: $library.searchQuery, isFocused: $searchFocused)
                .frame(maxWidth: .infinity)

            // View mode toggle
            ViewModeToggle(viewMode: $library.viewMode)

            // Sort picker
            SortPicker(sortMode: $library.sortMode)
        }
        .padding(.horizontal, LB.spaceLG)
        .frame(height: 52)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LB.borderSubtle)
                .frame(height: 1)
        }
        .onAppear {
            // Only handle ⌘F here; Esc + arrow keys are owned by AppGridView
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command),
                   event.charactersIgnoringModifiers == "f" {
                    searchFocused = true
                    return nil
                }
                return event
            }
        }
    }
}

// MARK: – Search field

private struct SearchField: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: LB.spaceSM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LB.textTertiary)

            TextField("Search apps…", text: $query)
                .textFieldStyle(.plain)
                .font(LB.fontBody)
                .foregroundStyle(LB.textPrimary)
                .focused(isFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(LB.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, LB.spaceMD)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: LB.radiusSM)
                .fill(isFocused.wrappedValue ? Color.white.opacity(0.10) : Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .strokeBorder(
                            isFocused.wrappedValue ? LB.borderActive : LB.borderMid,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isFocused.wrappedValue ? LB.accent.opacity(0.25) : .clear,
                    radius: 6, x: 0, y: 0
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
    }
}

// MARK: – View mode toggle

private struct ViewModeToggle: View {
    @Binding var viewMode: ViewMode

    var body: some View {
        HStack(spacing: 0) {
            toggleButton(icon: "square.grid.2x2", mode: .grid)
            toggleButton(icon: "list.bullet", mode: .list)
        }
        .background(
            RoundedRectangle(cornerRadius: LB.radiusSM)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .strokeBorder(LB.borderSubtle, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func toggleButton(icon: String, mode: ViewMode) -> some View {
        let isActive = viewMode == mode
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? LB.accent : LB.textTertiary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: LB.radiusSM)
                        .fill(isActive ? LB.accentDim : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Sort picker

private struct SortPicker: View {
    @Binding var sortMode: SortMode
    @State private var isHovered = false

    var body: some View {
        Menu {
            ForEach(SortMode.allCases) { mode in
                Button {
                    withAnimation { sortMode = mode }
                } label: {
                    HStack {
                        Text(mode.rawValue)
                        if sortMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: LB.spaceXS) {
                Text(sortMode.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LB.textSecondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(LB.textTertiary)
            }
            .padding(.horizontal, LB.spaceMD)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: LB.radiusSM)
                    .fill(isHovered ? Color.white.opacity(0.09) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: LB.radiusSM)
                            .strokeBorder(LB.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
