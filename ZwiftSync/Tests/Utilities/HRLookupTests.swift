import XCTest
@testable import ZwiftSync

final class HRLookupExtendedTests: XCTestCase {

    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Large Dataset

    func testLargeDatasetBinarySearch() {
        let count = 10_000
        let samples = (0..<count).map { i in
            HRSample(
                timestamp: base.addingTimeInterval(TimeInterval(i)),
                bpm: 60 + Double(i % 120)
            )
        }
        let lookup = HRLookup(samples: samples)

        // Search in the middle
        let midTime = base.addingTimeInterval(5000)
        let result = lookup.nearestBPM(at: midTime, tolerance: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 60 + Double(5000 % 120), accuracy: 0.01)
    }

    func testLargeDatasetEdges() {
        let count = 1000
        let samples = (0..<count).map { i in
            HRSample(timestamp: base.addingTimeInterval(TimeInterval(i)), bpm: 100)
        }
        let lookup = HRLookup(samples: samples)

        // First sample
        XCTAssertEqual(lookup.nearestBPM(at: base, tolerance: 2), 100)
        // Last sample
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(999), tolerance: 2), 100)
    }

    // MARK: - Boundary Conditions

    func testExactlyAtTolerance() {
        let samples = [HRSample(timestamp: base, bpm: 120)]
        let lookup = HRLookup(samples: samples)

        // Exactly at 2s tolerance boundary
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(2.0), tolerance: 2), 120)
    }

    func testJustOutsideTolerance() {
        let samples = [HRSample(timestamp: base, bpm: 120)]
        let lookup = HRLookup(samples: samples)

        // Just beyond 2s tolerance
        XCTAssertNil(lookup.nearestBPM(at: base.addingTimeInterval(2.001), tolerance: 2))
    }

    // MARK: - Single Sample

    func testSingleSampleExactMatch() {
        let samples = [HRSample(timestamp: base, bpm: 75)]
        let lookup = HRLookup(samples: samples)
        XCTAssertEqual(lookup.nearestBPM(at: base, tolerance: 2), 75)
    }

    func testSingleSampleBeforeTarget() {
        let samples = [HRSample(timestamp: base, bpm: 75)]
        let lookup = HRLookup(samples: samples)
        // Target is before the sample but within tolerance
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(-1), tolerance: 2), 75)
    }

    // MARK: - Consecutive Duplicates

    func testConsecutiveDuplicateTimestamps() {
        let samples = [
            HRSample(timestamp: base, bpm: 100),
            HRSample(timestamp: base, bpm: 110),
            HRSample(timestamp: base.addingTimeInterval(1), bpm: 120),
        ]
        let lookup = HRLookup(samples: samples)
        let result = lookup.nearestBPM(at: base, tolerance: 2)
        XCTAssertNotNil(result)
        // Should return one of the duplicate timestamps
        XCTAssertTrue(result == 100 || result == 110)
    }

    // MARK: - Time Shift Edge Cases

    func testLargePositiveTimeShift() {
        let samples = [HRSample(timestamp: base, bpm: 130)]
        let lookup = HRLookup(samples: samples, timeShiftSeconds: 300)

        // Sample shifted to base+300
        XCTAssertNil(lookup.nearestBPM(at: base, tolerance: 2))
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(300), tolerance: 2), 130)
    }

    func testNegativeTimeShift() {
        let samples = [HRSample(timestamp: base.addingTimeInterval(100), bpm: 145)]
        let lookup = HRLookup(samples: samples, timeShiftSeconds: -100)

        // Sample shifted from base+100 to base+0
        XCTAssertEqual(lookup.nearestBPM(at: base, tolerance: 2), 145)
    }

    // MARK: - Between Two Samples

    func testBetweenTwoSamplesPicksNearest() {
        let samples = [
            HRSample(timestamp: base, bpm: 100),
            HRSample(timestamp: base.addingTimeInterval(4), bpm: 200),
        ]
        let lookup = HRLookup(samples: samples)

        // 1.5s — closer to first
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(1.5), tolerance: 2), 100)
        // 3s — closer to second (diff = 1s vs 3s)
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(3), tolerance: 2), 200)
    }
}
