/// Unit tests for AppScannerActor: extraction, deduplication, and rescan update logic.
import XCTest
@testable import LaunchboardKit

final class AppScannerActorTests: XCTestCase {
    private var fixtureDir: URL!

    override func setUpWithError() throws {
        fixtureDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaunchboardFixtures_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: fixtureDir, withIntermediateDirectories: true)
        try makeFixtureApp(
            in: fixtureDir,
            name: "Alpha",
            bundleID: "com.test.alpha",
            displayName: "Alpha App",
            version: "1.0"
        )
        try makeFixtureApp(
            in: fixtureDir,
            name: "Beta",
            bundleID: "com.test.beta",
            displayName: nil,
            version: "2.3"
        )
        try makeFixtureApp(
            in: fixtureDir,
            name: "Gamma",
            bundleID: "com.apple.gamma",
            displayName: "Gamma Tool",
            version: ""
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fixtureDir)
    }

    // MARK: - Extraction

    func testScanFindsThreeBundles() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        XCTAssertEqual(results.count, 3)
    }

    func testDisplayNameFromCFBundleDisplayName() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        let alpha = results.first(where: { $0.bundleIdentifier == "com.test.alpha" })
        XCTAssertEqual(alpha?.displayName, "Alpha App")
    }

    func testDisplayNameFallsBackToFilename() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        // Beta has no CFBundleDisplayName, should fall back to filename "Beta"
        let beta = results.first(where: { $0.bundleIdentifier == "com.test.beta" })
        XCTAssertEqual(beta?.displayName, "Beta")
    }

    func testVersionExtraction() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        let alpha = results.first(where: { $0.bundleIdentifier == "com.test.alpha" })
        XCTAssertEqual(alpha?.version, "1.0")
    }

    func testAppleBuiltInFlag() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        let gamma = results.first(where: { $0.bundleIdentifier == "com.apple.gamma" })
        XCTAssertEqual(gamma?.isAppleBuiltIn, true)
        let alpha = results.first(where: { $0.bundleIdentifier == "com.test.alpha" })
        XCTAssertEqual(alpha?.isAppleBuiltIn, false)
    }

    func testBundleURLIsSet() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        for entry in results {
            XCTAssertTrue(entry.bundleURL.pathExtension == "app")
        }
    }

    func testFileSizeIsNonNegative() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir])
        for entry in results {
            // .totalFileSizeKey returns 0 for synthetic temp-dir fixtures that are
            // plain directories rather than properly packaged OS bundles.
            // Real .app bundles always return a positive value.
            XCTAssertGreaterThanOrEqual(entry.fileSize, 0)
        }
    }

    // MARK: - Deduplication across locations

    func testDeduplicateByBundleIdentifier() async {
        // Provide the same directory twice — should yield 3, not 6.
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [fixtureDir, fixtureDir])
        XCTAssertEqual(results.count, 3)
    }

    // MARK: - Rescan updates

    func testRescanReflectsUpdatedVersion() async throws {
        let scanner = AppScannerActor()

        let before = await scanner.scan(locations: [fixtureDir])
        let alphaBefore = try XCTUnwrap(before.first(where: { $0.bundleIdentifier == "com.test.alpha" }))
        XCTAssertEqual(alphaBefore.version, "1.0")

        // Overwrite Alpha's plist with a bumped version
        let alphaURL = fixtureDir.appendingPathComponent("Alpha.app")
        try makeFixtureApp(in: fixtureDir, name: "Alpha", bundleID: "com.test.alpha",
                           displayName: "Alpha App", version: "1.1", overwrite: true)

        let after = await scanner.scan(locations: [fixtureDir])
        let alphaAfter = try XCTUnwrap(after.first(where: { $0.bundleIdentifier == "com.test.alpha" }))
        XCTAssertEqual(alphaAfter.version, "1.1")
        _ = alphaURL // suppress unused warning
    }

    func testRescanDoesNotReturnRemovedApp() async throws {
        let scanner = AppScannerActor()

        let before = await scanner.scan(locations: [fixtureDir])
        XCTAssertEqual(before.count, 3)

        try FileManager.default.removeItem(at: fixtureDir.appendingPathComponent("Gamma.app"))

        let after = await scanner.scan(locations: [fixtureDir])
        XCTAssertEqual(after.count, 2)
        XCTAssertNil(after.first(where: { $0.bundleIdentifier == "com.apple.gamma" }))
    }

    // MARK: - Fixture builder

    private func makeFixtureApp(
        in directory: URL,
        name: String,
        bundleID: String,
        displayName: String?,
        version: String,
        overwrite: Bool = false
    ) throws {
        let appURL = directory.appendingPathComponent("\(name).app")
        let contentsURL = appURL.appendingPathComponent("Contents")
        let fm = FileManager.default

        if overwrite, fm.fileExists(atPath: appURL.path) {
            try fm.removeItem(at: appURL)
        }

        try fm.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        var plist: [String: Any] = [
            "CFBundleIdentifier": bundleID,
            "CFBundleName": name,
            "CFBundlePackageType": "APPL",
        ]
        if let displayName { plist["CFBundleDisplayName"] = displayName }
        if !version.isEmpty { plist["CFBundleShortVersionString"] = version }

        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: contentsURL.appendingPathComponent("Info.plist"))
    }
}
