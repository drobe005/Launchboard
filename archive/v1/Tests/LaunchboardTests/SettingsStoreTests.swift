/// Unit tests for SettingsStore singleton-row behaviour.
import XCTest
import SwiftData
@testable import LaunchboardKit

final class SettingsStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testCreatesDefaultRowWhenAbsent() throws {
        let settings = try SettingsStore.current(in: context)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.showMenuBarIcon)
        XCTAssertEqual(settings.recentlyAddedTimeframe, 14)
        XCTAssertEqual(settings.defaultView, .grid)
        XCTAssertEqual(settings.defaultSort, .alphabetical)
        XCTAssertEqual(settings.theme, .auto)
        XCTAssertNil(settings.accentColorOverride)
        XCTAssertEqual(settings.iconSize, 64)
        XCTAssertTrue(settings.showAppNames)
        XCTAssertEqual(settings.reduceMotionMode, .auto)
        XCTAssertFalse(settings.hiddenAppBundleIDs.isEmpty == false)  // empty by default
    }

    func testDefaultScanLocationsIncludeApplications() throws {
        let settings = try SettingsStore.current(in: context)
        let paths = settings.scanLocations.map { $0.path }
        XCTAssertTrue(paths.contains("/Applications"))
    }

    func testFetchReturnsSameRowOnSecondCall() throws {
        let first = try SettingsStore.current(in: context)
        first.iconSize = 48
        let second = try SettingsStore.current(in: context)
        XCTAssertEqual(second.iconSize, 48, "Second fetch should return the mutated row, not a new default")
    }

    func testOnlyOneRowExists() throws {
        _ = try SettingsStore.current(in: context)
        _ = try SettingsStore.current(in: context)
        let all = try context.fetch(FetchDescriptor<AppSettings>())
        XCTAssertEqual(all.count, 1, "SettingsStore must never insert more than one row")
    }
}
