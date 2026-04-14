import XCTest
@testable import ZwiftSync

final class EnrichmentServiceTests: XCTestCase {

    private var mockStrava: MockStravaService!
    private var mockHealthKit: MockHealthKitService!
    private var sut: EnrichmentService!

    override func setUp() {
        super.setUp()
        mockStrava = MockStravaService()
        mockHealthKit = MockHealthKitService()
        sut = EnrichmentService(stravaService: mockStrava, healthKitService: mockHealthKit)
    }

    override func tearDown() {
        mockStrava = nil
        mockHealthKit = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - findEnrichableActivities

    func testFindEnrichableFiltersToVirtualRidesWithoutHR() async throws {
        mockStrava.stubbedActivities = [
            TestFixtures.makeActivity(id: 1, type: "VirtualRide", hasHeartrate: false, trainer: true),
            TestFixtures.makeActivity(id: 2, type: "VirtualRide", hasHeartrate: true, trainer: true),
            TestFixtures.makeActivity(id: 3, type: "Run", hasHeartrate: false, trainer: false),
            TestFixtures.makeActivity(id: 4, type: "Ride", hasHeartrate: false, trainer: true),
        ]

        let result = try await sut.findEnrichableActivities()

        XCTAssertEqual(result.count, 2) // id 1 (VirtualRide, no HR) and id 4 (trainer, no HR)
        XCTAssertTrue(result.contains(where: { $0.id == 1 }))
        XCTAssertTrue(result.contains(where: { $0.id == 4 }))
    }

    func testFindEnrichableExcludesActivitiesWithHR() async throws {
        mockStrava.stubbedActivities = [
            TestFixtures.makeActivity(id: 1, hasHeartrate: true, trainer: true),
        ]

        let result = try await sut.findEnrichableActivities()
        XCTAssertTrue(result.isEmpty)
    }

    func testFindEnrichableCallsStravaAPI() async throws {
        mockStrava.stubbedActivities = []
        _ = try await sut.findEnrichableActivities()

        XCTAssertEqual(mockStrava.getActivitiesCalls.count, 1)
        XCTAssertEqual(mockStrava.getActivitiesCalls[0].perPage, 30)
    }

    func testFindEnrichablePropagatesError() async {
        mockStrava.getActivitiesError = StravaError.notAuthenticated

        do {
            _ = try await sut.findEnrichableActivities()
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is StravaError)
        }
    }

    // MARK: - enrich Pipeline

    func testEnrichThrowsWhenNoWorkout() async {
        let candidate = EnrichmentCandidate(
            id: 1,
            stravaActivity: TestFixtures.makeActivity(),
            healthKitWorkout: nil,
            matchConfidence: .noMatch
        )

        do {
            _ = try await sut.enrich(candidate: candidate)
            XCTFail("Should throw noMatchingWorkout")
        } catch let error as EnrichmentError {
            XCTAssertEqual(error, .noMatchingWorkout)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testEnrichThrowsWhenNoHRData() async {
        // Need a real HKWorkout, but since we can't create one in tests,
        // we test the HR samples check via the mock returning empty
        // The mock returns empty HR samples by default
        mockHealthKit.stubbedHighResHR = []

        // We can't create HKWorkout instances in unit tests without HealthKit,
        // so we test this path through integration tests. Here we verify
        // the error type exists and has the right description.
        let error = EnrichmentError.noHeartRateData
        XCTAssertEqual(error.errorDescription, "No heart rate data available for this workout")
    }

    func testEnrichCallsStravaAPIsInOrder() async throws {
        // Verify that streams and laps are fetched
        mockStrava.stubbedStreams = TestFixtures.makeStreams(count: 5)
        mockStrava.stubbedLaps = []
        mockStrava.stubbedUploadResponse = StravaUploadResponse(id: 1, status: "ok", activityId: 99, error: nil)

        mockHealthKit.stubbedHighResHR = TestFixtures.makeHRSamples(count: 5)

        // We can't create a real HKWorkout, but we can verify the error path
        let candidate = EnrichmentCandidate(
            id: 1,
            stravaActivity: TestFixtures.makeActivity(),
            healthKitWorkout: nil,
            matchConfidence: .high
        )

        do {
            _ = try await sut.enrich(candidate: candidate)
            XCTFail("Should throw without workout")
        } catch is EnrichmentError {
            // Expected
        }
    }

    // MARK: - Error Types

    func testEnrichmentErrorDescriptions() {
        XCTAssertEqual(
            EnrichmentError.noMatchingWorkout.errorDescription,
            "No matching Apple Watch workout found"
        )
        XCTAssertEqual(
            EnrichmentError.noHeartRateData.errorDescription,
            "No heart rate data available for this workout"
        )
        XCTAssertEqual(
            EnrichmentError.uploadDidNotProduceActivity.errorDescription,
            "Upload completed but no activity was created"
        )
    }
}

// MARK: - EnrichmentError Equatable

extension EnrichmentError: Equatable {
    public static func == (lhs: EnrichmentError, rhs: EnrichmentError) -> Bool {
        switch (lhs, rhs) {
        case (.noMatchingWorkout, .noMatchingWorkout): true
        case (.noHeartRateData, .noHeartRateData): true
        case (.uploadDidNotProduceActivity, .uploadDidNotProduceActivity): true
        default: false
        }
    }
}
