import SwiftUI

struct AppGridView: View {
    @Environment(LibraryViewModel.self) private var library

    private let gridColumns = [GridItem(.adaptive(minimum: 86), spacing: 6)]
    // Key: 125=↑ 126=↓ 123=← 124=→ 36=↵ 53=Esc
    private let arrowKeyCodes: Set<UInt16> = [123, 124, 125, 126]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if library.currentApps.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    if library.viewMode == .grid {
                        gridContent
                    } else {
                        listContent
                    }
                }
            }

            keyboardHint
                .padding(.trailing, LB.spaceLG)
                .padding(.bottom, LB.spaceMD)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture { library.clearFocus() }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear  { updateColumnCount(width: geo.size.width) }
                    .onChange(of: geo.size.width) { updateColumnCount(width: $0) }
            }
        )
        .onAppear { installKeyboardMonitor() }
    }

    // MARK: – Column count reporting

    private func updateColumnCount(width: CGFloat) {
        let tileMin: CGFloat = 86 + 6    // adaptive minimum + spacing
        library.gridColumnCount = max(1, Int(width / tileMin))
    }

    // MARK: – Keyboard monitor

    private func installKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            guard !library.showSettings,
                  !library.showAppSelectModal,
                  !library.showSetupModal
            else { return event }

            switch event.keyCode {
            case 125: library.moveFocus(.down);  return nil   // ↓
            case 126: library.moveFocus(.up);    return nil   // ↑
            case 123: library.moveFocus(.left);  return nil   // ←
            case 124: library.moveFocus(.right); return nil   // →
            case 36:                                          // ↵
                library.launchFocusedApp()
                return nil
            case 53:                                          // Esc
                if !library.searchQuery.isEmpty {
                    library.searchQuery = ""
                } else {
                    library.clearFocus()
                }
                return nil
            default:
                return event
            }
        }
    }

    // MARK: – Grid layout

    private var gridContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            sectionHeader

            LazyVGrid(columns: gridColumns, spacing: 6) {
                ForEach(library.currentApps) { app in
                    AppTileView(item: app, isSearching: !library.searchQuery.isEmpty)
                }
            }
            .padding(.horizontal, LB.spaceLG)
            .padding(.bottom, 14)
        }
        .padding(.top, 14)
    }

    // MARK: – List layout

    private var listContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            VStack(spacing: 2) {
                ForEach(library.currentApps) { app in
                    if library.matchesSearch(app) {
                        AppListRowView(item: app)
                    }
                }
            }
            .padding(.horizontal, LB.spaceLG)
            .padding(.bottom, 14)
        }
        .padding(.top, 14)
    }

    // MARK: – Section header

    @ViewBuilder
    private var sectionHeader: some View {
        let title = library.currentSectionTitle
        let count = library.currentApps.count

        HStack {
            Text(title.uppercased())
                .font(LB.fontLabel)
                .foregroundStyle(LB.textTertiary)
                .tracking(0.8)

            Spacer()

            Text("\(count) app\(count == 1 ? "" : "s")")
                .font(LB.fontLabel)
                .foregroundStyle(LB.textDisabled)

            // "+ Add Apps" button shown in group view
            if library.currentGroup != nil {
                Button {
                    library.showAppSelectModal = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Add Apps")
                            .font(LB.fontLabel)
                    }
                    .foregroundStyle(LB.accent)
                    .padding(.horizontal, LB.spaceSM)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: LB.radiusXS)
                            .fill(LB.accentDim)
                            .overlay(
                                RoundedRectangle(cornerRadius: LB.radiusXS)
                                    .strokeBorder(LB.borderActive, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LB.spaceLG)
        .padding(.bottom, LB.spaceSM)
        .animation(.easeInOut(duration: 0.2), value: title)
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: LB.spaceMD) {
            Image(systemName: library.searchQuery.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(LB.textTertiary)

            if library.searchQuery.isEmpty {
                Text("No apps here yet")
                    .font(LB.fontBodyMed)
                    .foregroundStyle(LB.textTertiary)
                Text("Add apps using the button above")
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textDisabled)
            } else {
                Text("No results for \u{201C}\(library.searchQuery)\u{201D}")
                    .font(LB.fontBodyMed)
                    .foregroundStyle(LB.textTertiary)
                Text("Try a different search term")
                    .font(LB.fontCaption)
                    .foregroundStyle(LB.textDisabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    // MARK: – Keyboard hint

    private var keyboardHint: some View {
        HStack(spacing: LB.spaceXS) {
            KbdChip(label: "⌘F")
            Text("search")
                .font(LB.fontCaption)
                .foregroundStyle(LB.textDisabled)

            Spacer().frame(width: LB.spaceSM)

            KbdChip(label: "↵")
            Text("launch")
                .font(LB.fontCaption)
                .foregroundStyle(LB.textDisabled)
        }
        .allowsHitTesting(false)
    }
}
