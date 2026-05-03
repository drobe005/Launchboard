import SwiftUI
import Observation

@Observable
@MainActor
final class LibraryViewModel {

    // MARK: – Library state
    var apps: [AppItem]       = []
    var groups: [AppGroup]    = []
    var settings: AppSettings = AppSettings()

    // MARK: – Transient UI state
    var searchQuery: String              = ""
    var viewMode: ViewMode               = .grid
    var sortMode: SortMode               = .alphabetical
    var selectedSidebarItem: SidebarItem = .allApps
    var selectedAppIDs: Set<UUID>        = []
    var showAppSelectModal: Bool         = false
    var showSetupModal: Bool             = false
    var hasCompletedSetup: Bool          = false
    var launchErrorApp: AppItem?         = nil
    var hiddenAppIDs: Set<UUID>          = []
    var isScanning: Bool                 = false
    var showSettings: Bool               = false
    var focusedAppID: UUID?              = nil
    // Injected by AppGridView so arrow key delta can be column-aware
    var gridColumnCount: Int             = 7

    // MARK: – Sidebar navigation
    enum SidebarItem: Hashable {
        case favorites
        case recentlyAdded
        case allApps
        case group(UUID)
    }

    // MARK: – Init: load from persistence, fall back to seed

    init() {
        let store = PersistenceService.shared

        if let saved = store.loadApps(), !saved.isEmpty {
            apps = saved
        } else {
            apps = SeedData.apps
        }

        if let saved = store.loadGroups(), !saved.isEmpty {
            groups = saved
        } else {
            groups = SeedData.groups
        }

        if let saved = store.loadSettings() {
            settings = saved
        }

        hasCompletedSetup = store.loadHasCompletedSetup()
        hiddenAppIDs      = store.loadHiddenAppIDs()
        viewMode          = settings.defaultView
        sortMode          = settings.defaultSort
    }

    // MARK: – Testing init (bypasses persistence and discovery)

    init(apps: [AppItem], groups: [AppGroup] = [], settings: AppSettings = AppSettings()) {
        self.apps     = apps
        self.groups   = groups
        self.settings = settings
        self.viewMode = settings.defaultView
        self.sortMode = settings.defaultSort
    }

    // MARK: – First-launch

    func checkFirstLaunch() {
        if !hasCompletedSetup {
            showSetupModal = true
        }
        // Kick off system scan + icon load on every launch in background
        Task { await refreshFromSystem() }
    }

    // MARK: – App discovery

    func refreshFromSystem() async {
        isScanning = true
        defer { isScanning = false }

        let discovered = await AppDiscoveryService.shared.discoverApps()
        mergeDiscovered(discovered)
        save()

        // Load icons in batches to avoid hammering the main thread
        await loadIcons()
    }

    private func mergeDiscovered(_ discovered: [AppItem]) {
        let existingByBundle = Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleID, $0) })

        var merged = apps
        for new in discovered {
            if existingByBundle[new.bundleID] == nil {
                merged.append(new)
            }
        }
        apps = merged
    }

    private func loadIcons() async {
        // Process in batches of 5 so UI stays responsive
        let batchSize = 5
        let indices   = apps.indices.filter { apps[$0].iconData == nil }

        for batch in stride(from: 0, to: indices.count, by: batchSize) {
            let batchIndices = Array(indices[batch ..< min(batch + batchSize, indices.count)])

            // Fetch icons off main thread
            let results: [(Int, Data?)] = await withTaskGroup(of: (Int, Data?).self) { group in
                for idx in batchIndices {
                    let item = apps[idx]
                    group.addTask {
                        let data = await AppDiscoveryService.shared.loadIcon(for: item)
                        return (idx, data)
                    }
                }
                var out: [(Int, Data?)] = []
                for await pair in group { out.append(pair) }
                return out
            }

            // Apply on main actor
            for (idx, data) in results where data != nil {
                guard idx < apps.count else { continue }
                apps[idx].iconData = data
            }
        }
    }

    // MARK: – Derived: favorites

    var favorites: [AppItem] {
        apps.filter(\.isFavorite)
    }

    // MARK: – Derived: recently added

    var recentlyAdded: [AppItem] {
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value:    -settings.recentlyAddedDays,
            to:       .now
        ) ?? .distantPast
        return apps.filter { $0.dateAdded >= cutoff }
    }

    // MARK: – Derived: current view

    var currentApps: [AppItem] {
        let base: [AppItem]
        switch selectedSidebarItem {
        case .favorites:
            base = favorites
        case .recentlyAdded:
            base = recentlyAdded
        case .allApps:
            base = apps.filter { !hiddenAppIDs.contains($0.id) }
        case .group(let id):
            let group = groups.first { $0.id == id }
            base = apps.filter {
                group?.appIDs.contains($0.id) == true &&
                !hiddenAppIDs.contains($0.id)
            }
        }
        return filtered(sorted(base))
    }

    var currentGroup: AppGroup? {
        guard case .group(let id) = selectedSidebarItem else { return nil }
        return groups.first { $0.id == id }
    }

    var currentSectionTitle: String {
        switch selectedSidebarItem {
        case .favorites:     return "Favorites"
        case .recentlyAdded: return "Recently Added"
        case .allApps:       return "All Apps"
        case .group(let id): return groups.first { $0.id == id }?.name ?? "Group"
        }
    }

    var hiddenApps: [AppItem] {
        apps.filter { hiddenAppIDs.contains($0.id) }
    }

    // MARK: – Mutations

    func toggleFavorite(_ item: AppItem) {
        guard let idx = apps.firstIndex(where: { $0.id == item.id }) else { return }
        apps[idx].isFavorite.toggle()
        save()
    }

    func addApps(_ ids: [UUID], toGroup groupID: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let newIDs = ids.filter { !groups[idx].appIDs.contains($0) }
        groups[idx].appIDs.append(contentsOf: newIDs)
        save()
    }

    func removeApp(_ appID: UUID, fromGroup groupID: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[idx].appIDs.removeAll { $0 == appID }
        save()
    }

    func addGroup(_ group: AppGroup) {
        groups.append(group)
        selectedSidebarItem = .group(group.id)
        save()
    }

    func deleteGroup(_ groupID: UUID) {
        groups.removeAll { $0.id == groupID }
        if case .group(let id) = selectedSidebarItem, id == groupID {
            selectedSidebarItem = .allApps
        }
        save()
    }

    func hideApp(_ id: UUID) {
        hiddenAppIDs.insert(id)
        selectedAppIDs.remove(id)
        PersistenceService.shared.saveHiddenAppIDs(hiddenAppIDs)
    }

    func restoreApp(_ id: UUID) {
        hiddenAppIDs.remove(id)
        PersistenceService.shared.saveHiddenAppIDs(hiddenAppIDs)
    }

    func launchApp(_ item: AppItem) {
        guard let url = resolvedURL(for: item) else {
            launchErrorApp = item
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
        if let idx = apps.firstIndex(where: { $0.id == item.id }) {
            apps[idx].lastUsed = .now
        }
        if settings.hideWindowAfterLaunch { NSApp.hide(nil) }
        save()
    }

    // MARK: – Onboarding

    func checkFirstLaunch_setup() {
        if !hasCompletedSetup { showSetupModal = true }
    }

    func completeSetup(keepGroupIDs: Set<UUID>, favoriteIDs: Set<UUID>, shortcut: String) {
        groups.removeAll { !keepGroupIDs.contains($0.id) }
        for idx in apps.indices {
            apps[idx].isFavorite = favoriteIDs.contains(apps[idx].id)
        }
        settings.globalShortcut = shortcut
        hasCompletedSetup       = true
        showSetupModal          = false
        PersistenceService.shared.saveHasCompletedSetup(true)
        save()
    }

    // MARK: – Search

    func matchesSearch(_ item: AppItem) -> Bool {
        searchQuery.isEmpty || item.name.localizedCaseInsensitiveContains(searchQuery)
    }

    // MARK: – Keyboard navigation

    enum NavDirection { case up, down, left, right }

    func moveFocus(_ direction: NavDirection) {
        let list = currentApps
        guard !list.isEmpty else { return }

        // Seed focus to first item if nothing is focused yet
        guard let currentID = focusedAppID,
              let currentIdx = list.firstIndex(where: { $0.id == currentID })
        else {
            focusedAppID = list.first?.id
            selectedAppIDs = focusedAppID.map { [$0] } ?? []
            return
        }

        let cols  = max(1, viewMode == .grid ? gridColumnCount : 1)
        let delta: Int
        switch direction {
        case .left:  delta = -1
        case .right: delta = +1
        case .up:    delta = -cols
        case .down:  delta = +cols
        }

        let next = max(0, min(list.count - 1, currentIdx + delta))
        focusedAppID   = list[next].id
        selectedAppIDs = [list[next].id]
    }

    func launchFocusedApp() {
        guard let id  = focusedAppID ?? selectedAppIDs.first,
              let app = currentApps.first(where: { $0.id == id })
        else { return }
        launchApp(app)
    }

    func clearFocus() {
        focusedAppID   = nil
        selectedAppIDs = []
    }

    // MARK: – Persistence

    func save() {
        let store = PersistenceService.shared
        store.saveApps(apps)
        store.saveGroups(groups)
        store.saveSettings(settings)
    }

    // MARK: – Private

    private func sorted(_ list: [AppItem]) -> [AppItem] {
        switch sortMode {
        case .alphabetical: return list.sorted { $0.name < $1.name }
        case .dateAdded:    return list.sorted { $0.dateAdded > $1.dateAdded }
        case .recentlyUsed: return list.sorted {
            ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast)
        }
        case .mostUsed:     return list
        }
    }

    private func filtered(_ list: [AppItem]) -> [AppItem] {
        guard !searchQuery.isEmpty else { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    private func resolvedURL(for item: AppItem) -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.bundleID) {
            return url
        }
        let candidates = [
            "/Applications/\(item.name).app",
            "/System/Applications/\(item.name).app",
            "\(NSHomeDirectory())/Applications/\(item.name).app",
        ]
        return candidates
            .map    { URL(fileURLWithPath: $0) }
            .first  { FileManager.default.fileExists(atPath: $0.path) }
    }
}
