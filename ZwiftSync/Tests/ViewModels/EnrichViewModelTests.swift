import XCTest
@testable import ZwiftSync

@MainActor
final class EnrichViewModelTests: XCTestCase {

    private var mockStrava: MockStravaService!
    private var mockHealthKit: MockHealthKitService!
    private var enrichmentService: EnrichmentService!

    override func setUp() {
        super.setUp()
        mockStrava = MockStravaService()
        mockHealthKit = MockHealthKitService()
        enrichmentService = EnrichmentService(stravaService: mockStrava, healthKitService: mockHealthKit)
    }

    override func tearDown() {
        mockStrava = nil
        mockHealthKit = nil
        enrichmentService = nil
        super.tearDown()
    }

    private func makeSUT(confidence: MatchConfidence = .high) -> EnrichViewModel {
        let candidate = EnrichmentCandidate(
            id: 1,
            stravaActivity: TestFixtures.makeActivity(),
            healthKitWorkout: nil,
            matchConfidence: confidence
        )
        return EnrichViewModel(candidate: candidate, enrichmentService: enrichmentService)
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        let sut = makeSUT()
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.timeShiftSeconds, 0)
    }

    // MARK: - State Transitions

    func testRequestEnrichTransitionsToConfirming() {
        let sut = makeSUT()
        sut.requestEnrich()
        XCTAssertEqual(sut.state, .confirming)
    }

    func testResetTransitionsToIdle() {
        let sut = makeSUT()
        sut.requestEnrich()
        sut.reset()
        XCTAssertEqual(sut.state, .idle)
    }

    func testConfirmEnrichTransitionsToMerging() async {
        let sut = makeSUT()
        // Will fail because no workout, but should transition through states
        await sut.confirmEnrich()
        // Should end in failed state (no workout)
        if case .failed = sut.state {
            // Expected
        } else {
            XCTFail("Expected failed state, got \(sut.state)")
        }
    }

    // MARK: - Time Shift

    func testTimeShiftDefaultsToZero() {
        let sut = makeSUT()
        XCTAssertEqual(sut.timeShiftSeconds, 0)
    }

    func testTimeShiftCanBeSet() {
        let sut = makeSUT()
        sut.timeShiftSeconds = -10
        XCTAssertEqual(sut.timeShiftSeconds, -10)
    }

    // MARK: - Strava Activity URL

    func testStravaURLIsNilWhenNotSuccess() {
        let sut = makeSUT()
        XCTAssertNil(sut.stravaActivityURL)
    }

    func testStravaURLPresentOnSuccess() {
        let sut = makeSUT()
        // Manually set state to success for testing
        sut.state = .success(newActivityId: 12345)
        XCTAssertEqual(sut.stravaActivityURL?.absoluteString, "https://www.strava.com/activities/12345")
    }

    // MARK: - Error State

    func testFailedStateContainsMessage() async {
        let sut = makeSUT()
        await sut.confirmEnrich()

        if case .failed(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected failed state")
        }
    }

    // MARK: - Candidate Access

    func testCandidateIsAccessible() {
        let sut = makeSUT(confidence: .medium)
        XCTAssertEqual(sut.candidate.matchConfidence, .medium)
        XCTAssertEqual(sut.candidate.stravaActivity.name, "Test Zwift Ride")
    }
}
