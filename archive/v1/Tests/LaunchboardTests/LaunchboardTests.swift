/// Unit tests for LaunchboardKit core logic — scanning, search, and model invariants.
import XCTest
@testable import LaunchboardKit

final class LaunchboardTests: XCTestCase {
    func testSearchIndexReturnsEmptyForBlankQuery() {
        let index = SearchIndex()
        XCTAssertTrue(index.search("").isEmpty)
    }

    func testSearchIndexReturnsEmptyForAnyQuery() {
        let index = SearchIndex()
        XCTAssertTrue(index.search("figma").isEmpty)
    }

    func testAppScannerReturnsEmptyStub() async {
        let scanner = AppScannerActor()
        let results = await scanner.scan(locations: [])
        XCTAssertTrue(results.isEmpty)
    }

    func testRuleFieldCasesAreExhaustive() {
        XCTAssertEqual(RuleField.allCases.count, 5)
    }

    func testRuleOperatorCasesAreExhaustive() {
        XCTAssertEqual(RuleOperator.allCases.count, 6)
    }
}
