import Testing
import Foundation
@testable import Launchboard

// MARK: – Fixtures

private func makeApp(
    name: String = "TestApp",
    bundleID: String = "com.test.app",
    category: AppCategory = .utilities,
    isFavorite: Bool = false,
    dateAdded: Date = .now
) -> AppItem {
    AppItem(
        name: name, bundleID: bundleID, category: category,
        isFavorite: isFavorite, dateAdded: dateAdded
    )
}

private func makeGroup(name: String = "TestGroup", appIDs: [UUID] = []) -> AppGroup {
    AppGroup(name: name, icon: "folder.fill", colorHex: "#5a82ff", appIDs: appIDs)
}

// MARK: – Search & Filter

@MainActor
@Suite("Search and Filter")
struct SearchFilterTests {

    @Test("empty query returns all visible apps")
    func emptyQuery() {
        let apps = [makeApp(name: "Figma"), makeApp(name: "Xcode")]
        let vm = LibraryViewModel(apps: apps)
        #expect(vm.currentApps.count == apps.count)
    }

    @Test("query filters case-insensitively")
    func caseInsensitiveFilter() {
        let apps = [makeApp(name: "Figma"), makeApp(name: "Xcode"), makeApp(name: "figlet")]
        let vm = LibraryViewModel(apps: apps)
        vm.searchQuery = "FIG"
        #expect(vm.currentApps.count == 2)
        #expect(vm.currentApps.allSatisfy { $0.name.lowercased().contains("fig") })
    }

    @Test("query with no match returns empty list")
    func noMatch() {
        let vm = LibraryViewModel(apps: [makeApp(name: "Xcode")])
        vm.searchQuery = "zzznomatch"
        #expect(vm.currentApps.isEmpty)
    }

    @Test("matchesSearch respects empty query")
    func matchesSearchEmpty() {
        let vm = LibraryViewModel(apps: [])
        let app = makeApp(name: "Safari")
        #expect(vm.matchesSearch(app))
    }

    @Test("matchesSearch returns false for non-matching name")
    func matchesSearchMiss() {
        let vm = LibraryViewModel(apps: [])
        vm.searchQuery = "chrome"
        let app = makeApp(name: "Safari")
        #expect(!vm.matchesSearch(app))
    }
}

// MARK: – Sort Modes

@MainActor
@Suite("Sort Modes")
struct SortTests {

    @Test("alphabetical sorts A to Z")
    func alphabetical() {
        let apps = [makeApp(name: "Zed"), makeApp(name: "Arc"), makeApp(name: "Mail")]
        let vm = LibraryViewModel(apps: apps)
        vm.sortMode = .alphabetical
        let names = vm.currentApps.map(\.name)
        #expect(names == names.sorted())
    }

    @Test("dateAdded puts newest app first")
    func dateAdded() {
        let old = makeApp(name: "Old", dateAdded: Date(timeIntervalSinceNow: -1000))
        let new = makeApp(name: "New", dateAdded: Date(timeIntervalSinceNow: -1))
        let vm = LibraryViewModel(apps: [old, new])
        vm.sortMode = .dateAdded
        #expect(vm.currentApps.first?.name == "New")
    }
}

// MARK: – Favorites

@MainActor
@Suite("Favorites")
struct FavoritesTests {

    @Test("toggleFavorite marks an unfavorited app as favorite")
    func markFavorite() {
        let app = makeApp(isFavorite: false)
        let vm = LibraryViewModel(apps: [app])
        vm.toggleFavorite(app)
        #expect(vm.apps.first?.isFavorite == true)
    }

    @Test("toggleFavorite unmarks an already-favorite app")
    func unmarkFavorite() {
        let app = makeApp(isFavorite: true)
        let vm = LibraryViewModel(apps: [app])
        vm.toggleFavorite(app)
        #expect(vm.apps.first?.isFavorite == false)
    }

    @Test("favorites derived property only includes favorited apps")
    func favoritesOnly() {
        let apps = [makeApp(isFavorite: true), makeApp(isFavorite: false), makeApp(isFavorite: true)]
        let vm = LibraryViewModel(apps: apps)
        #expect(vm.favorites.count == 2)
        #expect(vm.favorites.allSatisfy { $0.isFavorite })
    }

    @Test("sidebar favorites view shows only favorited apps")
    func sidebarFavoritesFilter() {
        let fav    = makeApp(name: "Fav", isFavorite: true)
        let notFav = makeApp(name: "NotFav", isFavorite: false)
        let vm = LibraryViewModel(apps: [fav, notFav])
        vm.selectedSidebarItem = .favorites
        #expect(vm.currentApps.count == 1)
        #expect(vm.currentApps.first?.name == "Fav")
    }

    @Test("empty favorites list returns empty currentApps")
    func emptyFavorites() {
        let vm = LibraryViewModel(apps: [makeApp(isFavorite: false)])
        vm.selectedSidebarItem = .favorites
        #expect(vm.currentApps.isEmpty)
    }
}

// MARK: – Groups

@MainActor
@Suite("Groups")
struct GroupTests {

    @Test("addApps adds new IDs to the group")
    func addApps() {
        let app   = makeApp()
        let group = makeGroup()
        let vm    = LibraryViewModel(apps: [app], groups: [group])
        vm.addApps([app.id], toGroup: group.id)
        #expect(vm.groups.first?.appIDs.contains(app.id) == true)
    }

    @Test("addApps does not duplicate existing IDs")
    func noDuplicateIDs() {
        let app   = makeApp()
        let group = makeGroup(appIDs: [app.id])
        let vm    = LibraryViewModel(apps: [app], groups: [group])
        vm.addApps([app.id], toGroup: group.id)
        #expect(vm.groups.first?.appIDs.count == 1)
    }

    @Test("removeApp removes the app from the group")
    func removeApp() {
        let app   = makeApp()
        let group = makeGroup(appIDs: [app.id])
        let vm    = LibraryViewModel(apps: [app], groups: [group])
        vm.removeApp(app.id, fromGroup: group.id)
        #expect(vm.groups.first?.appIDs.isEmpty == true)
    }

    @Test("addGroup appends the group and selects it")
    func addGroup() {
        let vm       = LibraryViewModel(apps: [])
        let newGroup = makeGroup(name: "Design Tools")
        vm.addGroup(newGroup)
        #expect(vm.groups.last?.name == "Design Tools")
        #expect(vm.selectedSidebarItem == .group(newGroup.id))
    }

    @Test("deleteGroup removes the group from the list")
    func deleteGroup() {
        let group = makeGroup()
        let vm    = LibraryViewModel(apps: [], groups: [group])
        vm.deleteGroup(group.id)
        #expect(vm.groups.isEmpty)
    }

    @Test("deleteGroup resets sidebar selection to allApps")
    func deleteGroupResetsSelection() {
        let group = makeGroup()
        let vm    = LibraryViewModel(apps: [], groups: [group])
        vm.selectedSidebarItem = .group(group.id)
        vm.deleteGroup(group.id)
        #expect(vm.selectedSidebarItem == .allApps)
    }

    @Test("deleteGroup of non-selected group does not change selection")
    func deleteGroupKeepsSelection() {
        let g1 = makeGroup(name: "G1")
        let g2 = makeGroup(name: "G2")
        let vm = LibraryViewModel(apps: [], groups: [g1, g2])
        vm.selectedSidebarItem = .group(g1.id)
        vm.deleteGroup(g2.id)
        #expect(vm.selectedSidebarItem == .group(g1.id))
    }

    @Test("group sidebar view shows only apps in that group")
    func groupSidebarFilter() {
        let a     = makeApp(name: "A")
        let b     = makeApp(name: "B")
        let group = makeGroup(appIDs: [a.id])
        let vm    = LibraryViewModel(apps: [a, b], groups: [group])
        vm.selectedSidebarItem = .group(group.id)
        #expect(vm.currentApps.count == 1)
        #expect(vm.currentApps.first?.name == "A")
    }

    @Test("currentGroup returns nil outside a group context")
    func currentGroupNil() {
        let vm = LibraryViewModel(apps: [])
        vm.selectedSidebarItem = .allApps
        #expect(vm.currentGroup == nil)
    }

    @Test("currentGroup returns the right group")
    func currentGroupValue() {
        let group = makeGroup(name: "Dev")
        let vm    = LibraryViewModel(apps: [], groups: [group])
        vm.selectedSidebarItem = .group(group.id)
        #expect(vm.currentGroup?.name == "Dev")
    }
}

// MARK: – Hide and Restore

@MainActor
@Suite("Hide and Restore")
struct HideRestoreTests {

    @Test("hideApp removes app from allApps view")
    func hideFromView() {
        let app = makeApp()
        let vm  = LibraryViewModel(apps: [app])
        vm.hideApp(app.id)
        #expect(!vm.currentApps.contains { $0.id == app.id })
    }

    @Test("restoreApp makes app visible again")
    func restoreToView() {
        let app = makeApp()
        let vm  = LibraryViewModel(apps: [app])
        vm.hideApp(app.id)
        vm.restoreApp(app.id)
        #expect(vm.currentApps.contains { $0.id == app.id })
    }

    @Test("hiddenApps derived property lists hidden items")
    func hiddenAppsList() {
        let app = makeApp()
        let vm  = LibraryViewModel(apps: [app])
        vm.hideApp(app.id)
        #expect(vm.hiddenApps.map(\.id).contains(app.id))
    }

    @Test("hiddenApps is empty before any hide calls")
    func hiddenAppsInitiallyEmpty() {
        let vm = LibraryViewModel(apps: [makeApp()])
        #expect(vm.hiddenApps.isEmpty)
    }
}

// MARK: – Keyboard Navigation

@MainActor
@Suite("Keyboard Navigation")
struct NavigationTests {

    @Test("first moveFocus seeds focus to the first item")
    func seedFocus() {
        let apps = [makeApp(name: "A"), makeApp(name: "B")]
        let vm   = LibraryViewModel(apps: apps)
        vm.sortMode = .alphabetical
        vm.moveFocus(.right)
        #expect(vm.focusedAppID != nil)
    }

    @Test("moveFocus right advances to the next item")
    func moveRight() {
        let apps = (0..<4).map { makeApp(name: "App\($0)") }
        let vm   = LibraryViewModel(apps: apps)
        vm.sortMode      = .alphabetical
        vm.gridColumnCount = 4
        vm.moveFocus(.right)                    // seed → App0
        let firstID = vm.focusedAppID
        vm.moveFocus(.right)                    // → App1
        #expect(vm.focusedAppID != firstID)
    }

    @Test("moveFocus clamps at the end of the list")
    func clampsAtEnd() {
        let app = makeApp(name: "Only")
        let vm  = LibraryViewModel(apps: [app])
        vm.moveFocus(.right)                    // seed
        let id = vm.focusedAppID
        vm.moveFocus(.right)                    // try past end
        #expect(vm.focusedAppID == id)
    }

    @Test("moveFocus up moves back one row in grid mode")
    func moveUpGrid() {
        let apps = (0..<6).map { makeApp(name: "App\($0)") }
        let vm   = LibraryViewModel(apps: apps)
        vm.sortMode        = .alphabetical
        vm.gridColumnCount = 3
        vm.moveFocus(.down)                     // seed → App0
        vm.moveFocus(.down)                     // → App3 (row 2, col 0)
        let before = vm.focusedAppID
        vm.moveFocus(.up)                       // → App0
        #expect(vm.focusedAppID != before)
    }

    @Test("clearFocus resets focusedAppID and selectedAppIDs")
    func clearFocus() {
        let app = makeApp()
        let vm  = LibraryViewModel(apps: [app])
        vm.focusedAppID   = app.id
        vm.selectedAppIDs = [app.id]
        vm.clearFocus()
        #expect(vm.focusedAppID == nil)
        #expect(vm.selectedAppIDs.isEmpty)
    }
}

// MARK: – Section Title

@MainActor
@Suite("Section Title")
struct SectionTitleTests {

    @Test("allApps section title is 'All Apps'")
    func allAppsTitle() {
        let vm = LibraryViewModel(apps: [])
        vm.selectedSidebarItem = .allApps
        #expect(vm.currentSectionTitle == "All Apps")
    }

    @Test("favorites section title is 'Favorites'")
    func favoritesTitle() {
        let vm = LibraryViewModel(apps: [])
        vm.selectedSidebarItem = .favorites
        #expect(vm.currentSectionTitle == "Favorites")
    }

    @Test("group section title matches group name")
    func groupTitle() {
        let group = makeGroup(name: "Dev Tools")
        let vm    = LibraryViewModel(apps: [], groups: [group])
        vm.selectedSidebarItem = .group(group.id)
        #expect(vm.currentSectionTitle == "Dev Tools")
    }
}

// MARK: – Onboarding

@MainActor
@Suite("Onboarding / Setup")
struct SetupTests {

    @Test("completeSetup removes unkept groups")
    func removesUnkeptGroups() {
        let g1 = makeGroup(name: "Keep")
        let g2 = makeGroup(name: "Drop")
        let vm = LibraryViewModel(apps: [], groups: [g1, g2])
        vm.completeSetup(keepGroupIDs: [g1.id], favoriteIDs: [], shortcut: "⌥Space")
        #expect(vm.groups.count == 1)
        #expect(vm.groups.first?.name == "Keep")
    }

    @Test("completeSetup marks specified apps as favorites")
    func marksFavorites() {
        let app = makeApp(isFavorite: false)
        let vm  = LibraryViewModel(apps: [app])
        vm.completeSetup(keepGroupIDs: [], favoriteIDs: [app.id], shortcut: "⌥Space")
        #expect(vm.apps.first?.isFavorite == true)
    }

    @Test("completeSetup saves the global shortcut string")
    func savesShortcut() {
        let vm = LibraryViewModel(apps: [])
        vm.completeSetup(keepGroupIDs: [], favoriteIDs: [], shortcut: "⌃Space")
        #expect(vm.settings.globalShortcut == "⌃Space")
    }

    @Test("completeSetup sets hasCompletedSetup to true")
    func setsCompletedFlag() {
        let vm = LibraryViewModel(apps: [])
        vm.completeSetup(keepGroupIDs: [], favoriteIDs: [], shortcut: "⌥Space")
        #expect(vm.hasCompletedSetup == true)
        #expect(vm.showSetupModal == false)
    }
}

// MARK: – Persistence Round-trip

@Suite("Persistence Round-trip")
struct PersistenceTests {

    private func tempStore() -> (PersistenceService, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LBTests-\(UUID().uuidString)", isDirectory: true)
        return (PersistenceService(baseURL: dir), dir)
    }

    @Test("saveApps / loadApps preserves name and bundleID")
    func appsRoundTrip() throws {
        let (store, dir) = tempStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let apps = [makeApp(name: "RoundTrip", bundleID: "com.rt.test")]
        store.saveApps(apps)

        let loaded = try #require(store.loadApps())
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "RoundTrip")
        #expect(loaded.first?.bundleID == "com.rt.test")
    }

    @Test("saveApps strips iconData before writing")
    func stripsIconData() throws {
        let (store, dir) = tempStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var app = makeApp()
        app.iconData = Data([0xFF, 0xD8, 0xFF])
        store.saveApps([app])

        let loaded = try #require(store.loadApps())
        #expect(loaded.first?.iconData == nil)
    }

    @Test("saveGroups / loadGroups preserves group name and appIDs")
    func groupsRoundTrip() throws {
        let (store, dir) = tempStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let id    = UUID()
        let group = AppGroup(name: "DevTools", icon: "folder.fill", colorHex: "#5a82ff", appIDs: [id])
        store.saveGroups([group])

        let loaded = try #require(store.loadGroups())
        #expect(loaded.first?.name == "DevTools")
        #expect(loaded.first?.appIDs.first == id)
    }

    @Test("saveSettings / loadSettings preserves custom shortcut")
    func settingsRoundTrip() throws {
        let (store, dir) = tempStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var settings = AppSettings()
        settings.globalShortcut = "⌃Space"
        store.saveSettings(settings)

        let loaded = try #require(store.loadSettings())
        #expect(loaded.globalShortcut == "⌃Space")
    }

    @Test("loadApps returns nil when no file exists")
    func loadAppsNil() {
        let (store, dir) = tempStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(store.loadApps() == nil)
    }

    @Test("saveApps then loadApps preserves isFavorite flag")
    func preservesFavoriteFlag() throws {
        let (store, dir) = tempStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let app = makeApp(name: "Fav", isFavorite: true)
        store.saveApps([app])

        let loaded = try #require(store.loadApps())
        #expect(loaded.first?.isFavorite == true)
    }
}
