/// Unit tests for SearchIndex: subsequence matching, Levenshtein ranking, and favorites boost.
import XCTest
@testable import LaunchboardKit

final class SearchIndexTests: XCTestCase {

    // MARK: - Fixtures

    private let figma    = AppEntry(bundleIdentifier: "com.figma.desktop",      displayName: "Figma",         bundleURL: url("Figma"))
    private let figJam   = AppEntry(bundleIdentifier: "com.figma.figjam",       displayName: "FigJam",        bundleURL: url("FigJam"))
    private let firefox  = AppEntry(bundleIdentifier: "org.mozilla.firefox",    displayName: "Firefox",       bundleURL: url("Firefox"))
    private let finder   = AppEntry(bundleIdentifier: "com.apple.finder",       displayName: "Finder",        bundleURL: url("Finder"))
    private let xcode    = AppEntry(bundleIdentifier: "com.apple.dt.Xcode",     displayName: "Xcode",         bundleURL: url("Xcode"))
    private let vsCode   = AppEntry(bundleIdentifier: "com.microsoft.VSCode",   displayName: "Visual Studio Code", bundleURL: url("VS Code"))
    private let terminal = AppEntry(bundleIdentifier: "com.apple.Terminal",     displayName: "Terminal",      bundleURL: url("Terminal"))

    private static func url(_ name: String) -> URL {
        URL(fileURLWithPath: "/Applications/\(name).app")
    }

    private func makeIndex(favorites: Set<String> = []) -> SearchIndex {
        var index = SearchIndex()
        index.build(from: [figma, figJam, firefox, finder, xcode, vsCode, terminal], favorites: favorites)
        return index
    }

    // MARK: - Subsequence matching

    func testExactMatchIsIncluded() {
        let idx = makeIndex()
        let ids = idx.matchingIDs(for: "Figma")
        XCTAssertTrue(ids.contains("com.figma.desktop"))
    }

    func testCaseInsensitiveMatch() {
        let idx = makeIndex()
        let ids = idx.matchingIDs(for: "figma")
        XCTAssertTrue(ids.contains("com.figma.desktop"))
    }

    func testSubsequenceMatchIsIncluded() {
        let idx = makeIndex()
        // "fnd" is a subsequence of "Finder"
        let ids = idx.matchingIDs(for: "fnd")
        XCTAssertTrue(ids.contains("com.apple.finder"))
    }

    func testNonSubsequenceIsExcluded() {
        let idx = makeIndex()
        // "xq" is not a subsequence of any fixture app name
        let ids = idx.matchingIDs(for: "xq")
        XCTAssertTrue(ids.isEmpty)
    }

    func testEmptyQueryReturnsEmpty() {
        let idx = makeIndex()
        XCTAssertTrue(idx.matchingIDs(for: "").isEmpty)
        XCTAssertTrue(idx.search("").isEmpty)
    }

    func testQueryLongerThanNameIsExcluded() {
        let idx = makeIndex()
        // "figmaxyz" can't be a subsequence of "Figma"
        let ids = idx.matchingIDs(for: "figmaxyz")
        XCTAssertFalse(ids.contains("com.figma.desktop"))
    }

    // MARK: - Levenshtein ranking

    func testCloserEditDistanceRanksHigher() throws {
        let idx = makeIndex()
        // "fig" is a subsequence of both "Figma" (dist=2) and "FigJam" (dist=3);
        // Figma has the shorter edit distance and must rank first.
        let results = idx.search("fig")
        let bundleIDs = results.map { $0.entry.bundleIdentifier }
        let figmaPos  = try XCTUnwrap(bundleIDs.firstIndex(of: "com.figma.desktop"),
                                      "Figma must be in results for query 'fig'")
        let figJamPos = try XCTUnwrap(bundleIDs.firstIndex(of: "com.figma.figjam"),
                                      "FigJam must be in results for query 'fig'")
        XCTAssertLessThan(figmaPos, figJamPos, "Figma (dist=2) should rank above FigJam (dist=3)")
    }

    func testLimitIsRespected() {
        var index = SearchIndex()
        // Build with 7 apps, all of which match "a"
        index.build(from: [figma, figJam, firefox, finder, xcode, vsCode, terminal], favorites: [])
        let results = index.search("a", limit: 3)
        XCTAssertLessThanOrEqual(results.count, 3)
    }

    func testScoresAreNonDecreasing() {
        let idx = makeIndex()
        let results = idx.search("fi")
        for i in 1..<results.count {
            XCTAssertLessThanOrEqual(results[i - 1].score, results[i].score,
                "Results should be sorted by ascending score")
        }
    }

    // MARK: - Favorites boost

    func testFavoriteRanksAboveNonFavoriteWithSameName() throws {
        // FigJam is a favorite; Figma is not.
        // Both match "fig", but FigJam's boost (-100) should surface it above Figma.
        let idx = makeIndex(favorites: ["com.figma.figjam"])
        let results = idx.search("fig")
        let bundleIDs = results.map { $0.entry.bundleIdentifier }
        let figJamPos = try XCTUnwrap(bundleIDs.firstIndex(of: "com.figma.figjam"))
        let figmaPos  = try XCTUnwrap(bundleIDs.firstIndex(of: "com.figma.desktop"))
        XCTAssertLessThan(figJamPos, figmaPos, "Favorite FigJam should rank above non-favorite Figma")
    }

    func testFavoriteScoreIsLowerThanNonFavorite() throws {
        let idx = makeIndex(favorites: ["com.figma.figjam"])
        let results = idx.search("fig")
        let figJamScore = try XCTUnwrap(results.first(where: { $0.entry.bundleIdentifier == "com.figma.figjam" })?.score)
        let figmaScore  = try XCTUnwrap(results.first(where: { $0.entry.bundleIdentifier == "com.figma.desktop" })?.score)
        XCTAssertLessThan(figJamScore, figmaScore, "Favorite score must be lower (higher rank)")
    }

    // MARK: - Algorithm unit tests

    func testLevenshteinIdentical() {
        XCTAssertEqual(levenshtein("figma", "figma"), 0)
    }

    func testLevenshteinSingleInsertion() {
        XCTAssertEqual(levenshtein("figm", "figma"), 1)
    }

    func testLevenshteinSingleDeletion() {
        XCTAssertEqual(levenshtein("figma", "figm"), 1)
    }

    func testLevenshteinSingleSubstitution() {
        XCTAssertEqual(levenshtein("figma", "xigma"), 1)
    }

    func testLevenshteinEmptyStrings() {
        XCTAssertEqual(levenshtein("", ""), 0)
        XCTAssertEqual(levenshtein("", "abc"), 3)
        XCTAssertEqual(levenshtein("abc", ""), 3)
    }

    func testIsSubsequenceTrue() {
        XCTAssertTrue(isSubsequence("fnd", in: "finder"))
        XCTAssertTrue(isSubsequence("vsc", in: "visual studio code"))
        XCTAssertTrue(isSubsequence("", in: "anything"))
    }

    func testIsSubsequenceFalse() {
        XCTAssertFalse(isSubsequence("xq", in: "xcode"))
        XCTAssertFalse(isSubsequence("abc", in: ""))
    }
}
