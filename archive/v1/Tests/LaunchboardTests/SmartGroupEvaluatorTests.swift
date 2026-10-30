/// Comprehensive unit tests for SmartGroupEvaluator:
/// every field × operator combination, both combinators, and all documented edge cases.
import XCTest
@testable import LaunchboardKit

final class SmartGroupEvaluatorTests: XCTestCase {

    // MARK: - Fixtures

    // Opened 3 days ago, 200 MB, third-party, productivity
    private lazy var figma: AppEntry = AppEntry(
        bundleIdentifier: "com.figma.desktop",
        displayName: "Figma",
        bundleURL: URL(fileURLWithPath: "/Applications/Figma.app"),
        lastOpenedAt: daysAgo(3),
        fileSize: mb(200),
        isAppleBuiltIn: false,
        category: "public.app-category.productivity"
    )

    // Opened 10 days ago, 50 MB, Apple built-in, utilities
    private lazy var finder: AppEntry = AppEntry(
        bundleIdentifier: "com.apple.finder",
        displayName: "Finder",
        bundleURL: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"),
        lastOpenedAt: daysAgo(10),
        fileSize: mb(50),
        isAppleBuiltIn: true,
        category: "public.app-category.utilities"
    )

    // Never opened, 10 000 MB, third-party (fake URL), developer-tools
    private lazy var xcode: AppEntry = AppEntry(
        bundleIdentifier: "com.apple.dt.Xcode",
        displayName: "Xcode",
        bundleURL: URL(fileURLWithPath: "/Applications/Xcode.app"),
        lastOpenedAt: nil,
        fileSize: mb(10_000),
        isAppleBuiltIn: false,
        category: "public.app-category.developer-tools"
    )

    // Opened today, 5 MB, no category
    private lazy var openedToday: AppEntry = AppEntry(
        bundleIdentifier: "com.test.today",
        displayName: "TodayApp",
        bundleURL: URL(fileURLWithPath: "/Applications/TodayApp.app"),
        lastOpenedAt: Date(),
        fileSize: mb(5),
        isAppleBuiltIn: false,
        category: nil
    )

    /// All four baseline apps.
    private lazy var allApps: [AppEntry] = [figma, finder, xcode, openedToday]

    // MARK: - Helpers

    private func rule(_ field: RuleField, _ op: RuleOperator, _ value: String) -> SmartGroupRule {
        SmartGroupRule(field: field, op: op, value: value)
    }

    private func ids(_ results: [AppEntry]) -> Set<String> {
        Set(results.map { $0.bundleIdentifier })
    }

    private func daysAgo(_ n: Double) -> Date {
        Date().addingTimeInterval(-n * 86_400)
    }

    private func mb(_ n: Int64) -> Int64 { n * 1_048_576 }

    // MARK: - Edge cases

    func testEmptyRulesReturnsEmpty_all() {
        let result = SmartGroupEvaluator.evaluate(rules: [], combinator: .all, apps: allApps)
        XCTAssertTrue(result.isEmpty)
    }

    func testEmptyRulesReturnsEmpty_any() {
        let result = SmartGroupEvaluator.evaluate(rules: [], combinator: .any, apps: allApps)
        XCTAssertTrue(result.isEmpty)
    }

    func testEmptyAppsReturnsEmpty() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .contains, "fig")],
            combinator: .all,
            apps: []
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Name × contains

    func testName_contains_matchesCaseInsensitive() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .contains, "IGM")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testName_contains_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .contains, "zzz")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testName_contains_emptyValueNoMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .contains, "")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Name × startsWith

    func testName_startsWith_match() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .startsWith, "fig")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testName_startsWith_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .startsWith, "code")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testName_startsWith_caseInsensitive() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .startsWith, "FIND")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.apple.finder"])
    }

    // MARK: - Name × equals

    func testName_equals_exactMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .equals, "Figma")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testName_equals_caseInsensitive() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .equals, "figma")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testName_equals_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .equals, "Firefox")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Name × notEquals

    func testName_notEquals_excludesMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .notEquals, "figma")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertFalse(ids(result).contains("com.figma.desktop"))
        XCTAssertTrue(ids(result).contains("com.apple.finder"))
    }

    // MARK: - Last Opened × greaterThan (more recent than N days ago)

    func testLastOpened_greaterThan_includesRecent() {
        // Figma opened 3 days ago → more recent than 5 days → match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .greaterThan, "5")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(ids(result).contains("com.figma.desktop"))
    }

    func testLastOpened_greaterThan_excludesOld() {
        // Finder opened 10 days ago → NOT more recent than 5 days → no match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .greaterThan, "5")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertFalse(ids(result).contains("com.apple.finder"))
    }

    func testLastOpened_greaterThan_excludesNilOpenDate() {
        // Xcode has no lastOpenedAt → no match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .greaterThan, "30")],
            combinator: .all,
            apps: [xcode]
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testLastOpened_greaterThan_invalidValueNoMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .greaterThan, "abc")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Last Opened × lessThan (older than N days ago)

    func testLastOpened_lessThan_includesOld() {
        // Finder opened 10 days ago → older than 5 days → match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .lessThan, "5")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(ids(result).contains("com.apple.finder"))
    }

    func testLastOpened_lessThan_excludesRecent() {
        // Figma opened 3 days ago → NOT older than 5 days → no match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .lessThan, "5")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertFalse(ids(result).contains("com.figma.desktop"))
    }

    func testLastOpened_lessThan_excludesNilOpenDate() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .lessThan, "1")],
            combinator: .all,
            apps: [xcode]
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Last Opened × equals (specific date)

    func testLastOpened_equals_todayMatches() throws {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let todayStr = fmt.string(from: Date())

        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .equals, todayStr)],
            combinator: .all,
            apps: [openedToday]
        )
        XCTAssertEqual(ids(result), ["com.test.today"])
    }

    func testLastOpened_equals_wrongDateNoMatch() throws {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .equals, "2000-01-01")],
            combinator: .all,
            apps: [openedToday]
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testLastOpened_equals_invalidFormatNoMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .equals, "not-a-date")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testLastOpened_equals_nilOpenDateNoMatch() {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .equals, fmt.string(from: Date()))],
            combinator: .all,
            apps: [xcode]
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - File Size × greaterThan

    func testFileSize_greaterThan_match() {
        // Figma 200 MB > 100 MB → match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .greaterThan, "100")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(ids(result).contains("com.figma.desktop"))
        XCTAssertFalse(ids(result).contains("com.apple.finder")) // 50 MB not > 100 MB
    }

    func testFileSize_greaterThan_largeFile() {
        // Xcode 10 000 MB → matches any reasonable threshold
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .greaterThan, "5000")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.apple.dt.Xcode"])
    }

    func testFileSize_greaterThan_invalidValueNoMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .greaterThan, "abc")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - File Size × lessThan

    func testFileSize_lessThan_match() {
        // Finder 50 MB < 100 MB → match; Figma 200 MB → no match
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .lessThan, "100")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(ids(result).contains("com.apple.finder"))
        XCTAssertFalse(ids(result).contains("com.figma.desktop"))
    }

    func testFileSize_lessThan_invalidValueNoMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .lessThan, "")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - File Size × equals

    func testFileSize_equals_exactMatch() {
        // Finder is exactly 50 MB
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .equals, "50")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.apple.finder"])
    }

    func testFileSize_equals_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .equals, "999")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Source × equals Apple

    func testSource_equals_Apple_match() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .equals, "Apple")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.apple.finder"])
    }

    func testSource_equals_Apple_caseInsensitive() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .equals, "apple")],
            combinator: .all,
            apps: [finder]
        )
        XCTAssertEqual(ids(result), ["com.apple.finder"])
    }

    // MARK: - Source × equals Other

    func testSource_equals_Other_match() {
        // Figma uses /Applications/Figma.app — no receipt on disk → "Other"
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .equals, "Other")],
            combinator: .all,
            apps: [figma]
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testSource_equals_Other_doesNotMatchApple() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .equals, "Other")],
            combinator: .all,
            apps: [finder]  // isAppleBuiltIn = true
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Source × equals Mac App Store

    func testSource_equals_MacAppStore_match() throws {
        // Create a temp bundle with a _MASReceipt/receipt file to simulate an MAS app.
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("SGETests-\(UUID().uuidString)")
        let receiptDir = tmp
            .appendingPathComponent("Contents")
            .appendingPathComponent("_MASReceipt")
        try FileManager.default.createDirectory(at: receiptDir, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: receiptDir.appendingPathComponent("receipt").path,
            contents: Data()
        )
        defer { try? FileManager.default.removeItem(at: tmp) }

        let masApp = AppEntry(
            bundleIdentifier: "com.example.masapp",
            displayName: "MAS App",
            bundleURL: tmp,
            isAppleBuiltIn: false
        )

        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .equals, "Mac App Store")],
            combinator: .all,
            apps: [masApp]
        )
        XCTAssertEqual(ids(result), ["com.example.masapp"])
    }

    func testSource_equals_MacAppStore_noReceiptNoMatch() {
        // Figma has no receipt → does not match "Mac App Store"
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .equals, "Mac App Store")],
            combinator: .all,
            apps: [figma]
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Source × notEquals

    func testSource_notEquals_Apple_excludesApple() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .notEquals, "Apple")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertFalse(ids(result).contains("com.apple.finder"))
        XCTAssertTrue(ids(result).contains("com.figma.desktop"))
    }

    // MARK: - Category × equals

    func testCategory_equals_match() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .equals, "public.app-category.productivity")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testCategory_equals_caseInsensitive() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .equals, "PUBLIC.APP-CATEGORY.PRODUCTIVITY")],
            combinator: .all,
            apps: [figma]
        )
        XCTAssertEqual(ids(result), ["com.figma.desktop"])
    }

    func testCategory_equals_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .equals, "public.app-category.games")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testCategory_equals_nilCategoryNoMatch() {
        // openedToday has category = nil
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .equals, "public.app-category.productivity")],
            combinator: .all,
            apps: [openedToday]
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testCategory_equals_emptyValueNoMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .equals, "")],
            combinator: .all,
            apps: [figma]
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Category × notEquals

    func testCategory_notEquals_excludesMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .notEquals, "public.app-category.productivity")],
            combinator: .all,
            apps: [figma, finder]
        )
        XCTAssertFalse(ids(result).contains("com.figma.desktop"))
        XCTAssertTrue(ids(result).contains("com.apple.finder"))
    }

    func testCategory_notEquals_nilCategoryNoMatch() {
        // Nil category never equals or not-equals a specific value — returns false.
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.category, .notEquals, "anything")],
            combinator: .all,
            apps: [openedToday]
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Combinator: .all (AND)

    func testCombinator_all_bothRulesMustMatch() {
        // Rule 1: name contains "fi"  → figma, finder
        // Rule 2: source equals "Apple" → finder only
        // AND → finder only
        let rules = [
            rule(.name, .contains, "fi"),
            rule(.source, .equals, "Apple"),
        ]
        let result = SmartGroupEvaluator.evaluate(rules: rules, combinator: .all, apps: allApps)
        XCTAssertEqual(ids(result), ["com.apple.finder"])
    }

    func testCombinator_all_oneRuleFailsExcludesEntry() {
        // Rule 1: name contains "figma" → figma
        // Rule 2: source equals "Apple" → finder only
        // AND → empty (no app satisfies both)
        let rules = [
            rule(.name, .contains, "figma"),
            rule(.source, .equals, "Apple"),
        ]
        let result = SmartGroupEvaluator.evaluate(rules: rules, combinator: .all, apps: allApps)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Combinator: .any (OR)

    func testCombinator_any_oneRuleSuffices() {
        // Rule 1: name equals "Figma" → figma
        // Rule 2: source equals "Apple" → finder
        // OR → figma + finder
        let rules = [
            rule(.name, .equals, "Figma"),
            rule(.source, .equals, "Apple"),
        ]
        let result = SmartGroupEvaluator.evaluate(rules: rules, combinator: .any, apps: allApps)
        XCTAssertTrue(ids(result).contains("com.figma.desktop"))
        XCTAssertTrue(ids(result).contains("com.apple.finder"))
    }

    func testCombinator_any_noRuleMatchesReturnsEmpty() {
        let rules = [
            rule(.name, .equals, "NonExistent"),
            rule(.source, .equals, "BogusSource"),
        ]
        let result = SmartGroupEvaluator.evaluate(rules: rules, combinator: .any, apps: allApps)
        XCTAssertTrue(result.isEmpty)
    }

    func testCombinator_any_doesNotDuplicate() {
        // Rule 1 and Rule 2 both match the same app — it should appear only once.
        let rules = [
            rule(.name, .equals, "Figma"),
            rule(.fileSize, .greaterThan, "100"),  // also matches figma (200 MB)
        ]
        let result = SmartGroupEvaluator.evaluate(rules: rules, combinator: .any, apps: [figma])
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Unsupported operator × field combinations return false

    func testUnsupportedOperator_nameGreaterThan_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.name, .greaterThan, "Figma")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testUnsupportedOperator_fileSizeContains_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.fileSize, .contains, "100")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testUnsupportedOperator_sourceGreaterThan_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.source, .greaterThan, "Apple")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testUnsupportedOperator_lastOpenedContains_noMatch() {
        let result = SmartGroupEvaluator.evaluate(
            rules: [rule(.lastOpened, .contains, "7")],
            combinator: .all,
            apps: allApps
        )
        XCTAssertTrue(result.isEmpty)
    }
}
