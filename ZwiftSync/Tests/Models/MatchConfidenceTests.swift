import XCTest
@testable import ZwiftSync

final class MatchConfidenceTests: XCTestCase {

    func testSortOrder() {
        let values: [MatchConfidence] = [.medium, .noMatch, .high, .low]
        let sorted = values.sorted()
        XCTAssertEqual(sorted, [.noMatch, .low, .medium, .high])
    }

    func testMaxReturnsHighest() {
        let values: [MatchConfidence] = [.low, .high, .medium]
        XCTAssertEqual(values.max(), .high)
    }

    func testMinReturnsLowest() {
        let values: [MatchConfidence] = [.low, .high, .medium]
        XCTAssertEqual(values.min(), .low)
    }

    func testEqualityWithSameCase() {
        XCTAssertEqual(MatchConfidence.high, .high)
        XCTAssertEqual(MatchConfidence.noMatch, .noMatch)
    }

    func testRankValues() {
        XCTAssertEqual(MatchConfidence.noMatch.rank, 0)
        XCTAssertEqual(MatchConfidence.low.rank, 1)
        XCTAssertEqual(MatchConfidence.medium.rank, 2)
        XCTAssertEqual(MatchConfidence.high.rank, 3)
    }

    func testLabelValues() {
        XCTAssertEqual(MatchConfidence.high.label, "Match ✓")
        XCTAssertEqual(MatchConfidence.medium.label, "Partial")
        XCTAssertEqual(MatchConfidence.low.label, "Weak")
        XCTAssertEqual(MatchConfidence.noMatch.label, "No Match")
    }

    func testAllCasesCompare() {
        XCTAssertTrue(MatchConfidence.noMatch < .low)
        XCTAssertTrue(MatchConfidence.low < .medium)
        XCTAssertTrue(MatchConfidence.medium < .high)
        XCTAssertFalse(MatchConfidence.high < .high)
    }
}
