import XCTest
@testable import ZwiftSync

final class OverlapCalculatorTests: XCTestCase {

    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Complete Overlap

    func testCompleteOverlapIsHigh() {
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(3600),
            workoutStart: base,
            workoutEnd: base.addingTimeInterval(3600)
        )
        XCTAssertEqual(result, .high)
    }

    func testWorkoutFullyContainsActivity() {
        let result = OverlapCalculator.confidence(
            activityStart: base.addingTimeInterval(60),
            activityEnd: base.addingTimeInterval(3540),
            workoutStart: base,
            workoutEnd: base.addingTimeInterval(3600)
        )
        XCTAssertEqual(result, .high)
    }

    // MARK: - Partial Overlap

    func testNinetyPercentOverlapIsHigh() {
        // Activity: 0-1000s, Workout: 50-1000s → overlap 950/1000 = 95%
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(50),
            workoutEnd: base.addingTimeInterval(1000)
        )
        XCTAssertEqual(result, .high)
    }

    func testSeventyPercentOverlapIsMedium() {
        // Activity: 0-1000s, Workout: 300-1000s → overlap 700/1000 = 70%
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(300),
            workoutEnd: base.addingTimeInterval(1000)
        )
        XCTAssertEqual(result, .medium)
    }

    func testThirtyPercentOverlapIsLow() {
        // Activity: 0-1000s, Workout: 700-1200s → overlap 300/1000 = 30%
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(700),
            workoutEnd: base.addingTimeInterval(1200)
        )
        XCTAssertEqual(result, .low)
    }

    // MARK: - No Overlap

    func testNoOverlapBeforeActivity() {
        let result = OverlapCalculator.confidence(
            activityStart: base.addingTimeInterval(1000),
            activityEnd: base.addingTimeInterval(2000),
            workoutStart: base,
            workoutEnd: base.addingTimeInterval(500)
        )
        XCTAssertEqual(result, .noMatch)
    }

    func testNoOverlapAfterActivity() {
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(2000),
            workoutEnd: base.addingTimeInterval(3000)
        )
        XCTAssertEqual(result, .noMatch)
    }

    func testAdjacentTimesNoOverlap() {
        // Workout ends exactly when activity starts
        let result = OverlapCalculator.confidence(
            activityStart: base.addingTimeInterval(1000),
            activityEnd: base.addingTimeInterval(2000),
            workoutStart: base,
            workoutEnd: base.addingTimeInterval(1000)
        )
        XCTAssertEqual(result, .noMatch)
    }

    // MARK: - Edge Cases

    func testZeroDurationActivityIsNoMatch() {
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base,
            workoutStart: base,
            workoutEnd: base.addingTimeInterval(3600)
        )
        XCTAssertEqual(result, .noMatch)
    }

    func testNegativeDurationActivityIsNoMatch() {
        let result = OverlapCalculator.confidence(
            activityStart: base.addingTimeInterval(100),
            activityEnd: base,
            workoutStart: base,
            workoutEnd: base.addingTimeInterval(3600)
        )
        XCTAssertEqual(result, .noMatch)
    }

    func testMinimalOverlapIsLow() {
        // Activity: 0-1000s, Workout: 999-2000s → overlap 1/1000 = 0.1%
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(999),
            workoutEnd: base.addingTimeInterval(2000)
        )
        XCTAssertEqual(result, .low)
    }

    // MARK: - Boundary Values

    func testExactly90PercentIsHigh() {
        // Activity: 0-1000s, Workout: 100-1000s → overlap 900/1000 = 90%
        // > 0.9 not >= 0.9, so 90% should be medium
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(100),
            workoutEnd: base.addingTimeInterval(1000)
        )
        XCTAssertEqual(result, .medium)
    }

    func testJustOver90PercentIsHigh() {
        // Activity: 0-1000s, Workout: 99-1000s → overlap 901/1000 = 90.1%
        let result = OverlapCalculator.confidence(
            activityStart: base,
            activityEnd: base.addingTimeInterval(1000),
            workoutStart: base.addingTimeInterval(99),
            workoutEnd: base.addingTimeInterval(1000)
        )
        XCTAssertEqual(result, .high)
    }
}
