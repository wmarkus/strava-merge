import XCTest
@testable import ZwiftSync

final class ProtocolConformanceTests: XCTestCase {

    func testStravaServiceConformsToProtocol() {
        let service = StravaService()
        XCTAssertTrue(service is any StravaServiceProtocol)
    }

    func testKeychainServiceConformsToProtocol() {
        let service = KeychainService.shared
        XCTAssertTrue(service is any KeychainServiceProtocol)
    }

    func testMockStravaServiceConformsToProtocol() {
        let mock = MockStravaService()
        XCTAssertTrue(mock is any StravaServiceProtocol)
    }

    func testMockHealthKitServiceConformsToProtocol() {
        let mock = MockHealthKitService()
        XCTAssertTrue(mock is any HealthKitServiceProtocol)
    }

    func testMockKeychainServiceConformsToProtocol() {
        let mock = MockKeychainService()
        XCTAssertTrue(mock is any KeychainServiceProtocol)
    }

    func testEnrichmentServiceAcceptsProtocols() {
        let strava = MockStravaService()
        let healthKit = MockHealthKitService()
        let service = EnrichmentService(stravaService: strava, healthKitService: healthKit)
        XCTAssertNotNil(service)
    }

    @MainActor
    func testAppStateAcceptsProtocols() {
        let strava = MockStravaService()
        let healthKit = MockHealthKitService()
        let state = AppState(stravaService: strava, healthKitService: healthKit)
        XCTAssertNotNil(state)
    }
}
