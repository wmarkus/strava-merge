import XCTest
@testable import ZwiftSync

@MainActor
final class AppStateTests: XCTestCase {

    // MARK: - Initial State

    func testInitiallyNotConnected() {
        let mockStrava = MockStravaService()
        mockStrava.stubbedHasValidToken = false

        let state = AppState(
            stravaService: mockStrava,
            healthKitService: MockHealthKitService()
        )

        XCTAssertFalse(state.isStravaConnected)
        XCTAssertFalse(state.isHealthKitAuthorized)
    }

    func testInitiallyConnectedWhenTokenExists() {
        let mockStrava = MockStravaService()
        mockStrava.stubbedHasValidToken = true

        let state = AppState(
            stravaService: mockStrava,
            healthKitService: MockHealthKitService()
        )

        XCTAssertTrue(state.isStravaConnected)
    }

    // MARK: - Disconnect

    func testDisconnectStravaClearsTokensAndState() {
        let mockStrava = MockStravaService()
        mockStrava.stubbedHasValidToken = true

        let state = AppState(
            stravaService: mockStrava,
            healthKitService: MockHealthKitService()
        )

        state.disconnectStrava()

        XCTAssertFalse(state.isStravaConnected)
        XCTAssertEqual(mockStrava.clearTokensCallCount, 1)
    }

    // MARK: - Error Descriptions

    func testStravaErrorDescriptions() {
        XCTAssertEqual(StravaError.authFailed.errorDescription, "Strava authorization failed")
        XCTAssertEqual(StravaError.notAuthenticated.errorDescription, "Not connected to Strava")
        XCTAssertEqual(StravaError.deleteFailed.errorDescription, "Failed to delete activity")
        XCTAssertEqual(StravaError.uploadFailed("test").errorDescription, "Upload failed: test")
        XCTAssertEqual(StravaError.uploadTimeout.errorDescription, "Upload timed out")
        XCTAssertEqual(StravaError.updateFailed.errorDescription, "Failed to update activity metadata")
    }

    func testHealthKitErrorDescriptions() {
        XCTAssertEqual(HealthKitError.notAvailable.errorDescription, "HealthKit is not available on this device")
        XCTAssertEqual(HealthKitError.authorizationDenied.errorDescription, "HealthKit access was denied")
    }
}
