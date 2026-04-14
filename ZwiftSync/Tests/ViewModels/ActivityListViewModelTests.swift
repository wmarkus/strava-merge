import XCTest
@testable import ZwiftSync

@MainActor
final class ActivityListViewModelTests: XCTestCase {

    private var mockStrava: MockStravaService!
    private var mockHealthKit: MockHealthKitService!
    private var enrichmentService: EnrichmentService!
    private var sut: ActivityListViewModel!

    override func setUp() {
        super.setUp()
        mockStrava = MockStravaService()
        mockHealthKit = MockHealthKitService()
        enrichmentService = EnrichmentService(stravaService: mockStrava, healthKitService: mockHealthKit)
        sut = ActivityListViewModel(enrichmentService: enrichmentService)
    }

    override func tearDown() {
        mockStrava = nil
        mockHealthKit = nil
        enrichmentService = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsEmpty() {
        XCTAssertTrue(sut.candidates.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Loading

    func testLoadActivitiesSetsLoadingState() async {
        mockStrava.stubbedActivities = []
        await sut.loadActivities()
        // After completion, loading should be false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Success

    func testLoadActivitiesPopulatesCandidates() async {
        mockStrava.stubbedActivities = [
            TestFixtures.makeActivity(id: 1, hasHeartrate: false, trainer: true),
            TestFixtures.makeActivity(id: 2, hasHeartrate: false, trainer: true),
        ]
        mockHealthKit.stubbedWorkouts = []

        await sut.loadActivities()

        XCTAssertEqual(sut.candidates.count, 2)
        XCTAssertEqual(sut.candidates[0].id, 1)
        XCTAssertEqual(sut.candidates[1].id, 2)
    }

    func testLoadActivitiesClearsError() async {
        // First load fails
        mockStrava.getActivitiesError = StravaError.notAuthenticated
        await sut.loadActivities()
        XCTAssertNotNil(sut.error)

        // Second load succeeds
        mockStrava.getActivitiesError = nil
        mockStrava.stubbedActivities = []
        await sut.loadActivities()
        XCTAssertNil(sut.error)
    }

    // MARK: - Error Handling

    func testLoadActivitiesSetsErrorOnFailure() async {
        mockStrava.getActivitiesError = StravaError.notAuthenticated
        await sut.loadActivities()

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.candidates.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Empty Results

    func testEmptyActivitiesResultsInEmptyCandidates() async {
        mockStrava.stubbedActivities = []
        await sut.loadActivities()

        XCTAssertTrue(sut.candidates.isEmpty)
        XCTAssertNil(sut.error)
    }

    func testNonEnrichableActivitiesFilteredOut() async {
        mockStrava.stubbedActivities = [
            TestFixtures.makeActivity(id: 1, type: "Run", hasHeartrate: false, trainer: false),
        ]
        await sut.loadActivities()

        XCTAssertTrue(sut.candidates.isEmpty)
    }
}
