import XCTest
@testable import ZwiftSync

final class EnrichmentModelsTests: XCTestCase {

    // MARK: - HRSample

    func testHRSampleEquality() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = HRSample(timestamp: date, bpm: 120)
        let b = HRSample(timestamp: date, bpm: 120)
        XCTAssertEqual(a, b)
    }

    func testHRSampleInequality() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = HRSample(timestamp: date, bpm: 120)
        let b = HRSample(timestamp: date, bpm: 130)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - EnrichmentCandidate

    func testCandidateIdentifiable() {
        let candidate = EnrichmentCandidate(
            id: 42,
            stravaActivity: TestFixtures.makeActivity(id: 42),
            healthKitWorkout: nil,
            matchConfidence: .noMatch
        )
        XCTAssertEqual(candidate.id, 42)
    }

    func testCandidateWithNoMatch() {
        let candidate = EnrichmentCandidate(
            id: 1,
            stravaActivity: TestFixtures.makeActivity(),
            healthKitWorkout: nil,
            matchConfidence: .noMatch
        )
        XCTAssertNil(candidate.healthKitWorkout)
        XCTAssertEqual(candidate.matchConfidence, .noMatch)
    }

    // MARK: - EnrichmentResult

    func testSuccessResult() {
        let result = EnrichmentResult(
            originalActivityId: 100,
            newActivityId: 200,
            hrSamplesInjected: 3600,
            success: true,
            error: nil
        )
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.originalActivityId, 100)
        XCTAssertEqual(result.newActivityId, 200)
        XCTAssertEqual(result.hrSamplesInjected, 3600)
        XCTAssertNil(result.error)
    }

    func testFailureResult() {
        let result = EnrichmentResult(
            originalActivityId: 100,
            newActivityId: nil,
            hrSamplesInjected: 0,
            success: false,
            error: "Upload failed"
        )
        XCTAssertFalse(result.success)
        XCTAssertNil(result.newActivityId)
        XCTAssertEqual(result.error, "Upload failed")
    }
}
