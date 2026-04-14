import XCTest
@testable import ZwiftSync

final class ConfigTests: XCTestCase {

    func testStravaRedirectURIUsesCorrectScheme() {
        XCTAssertTrue(Config.stravaRedirectURI.hasPrefix("zwiftsync://"))
    }

    func testStravaAuthURLIsHTTPS() {
        XCTAssertTrue(Config.stravaAuthURL.hasPrefix("https://"))
    }

    func testStravaTokenURLIsHTTPS() {
        XCTAssertTrue(Config.stravaTokenURL.hasPrefix("https://"))
    }

    func testStravaBaseURLIsHTTPS() {
        XCTAssertTrue(Config.stravaBaseURL.hasPrefix("https://"))
    }

    func testStravaScopesIncludeRequired() {
        XCTAssertTrue(Config.stravaScopes.contains("activity:read_all"))
        XCTAssertTrue(Config.stravaScopes.contains("activity:write"))
    }

    func testMatchToleranceIsPositive() {
        XCTAssertGreaterThan(Config.matchToleranceSeconds, 0)
    }

    func testHRAlignmentToleranceIsPositive() {
        XCTAssertGreaterThan(Config.hrAlignmentToleranceSeconds, 0)
    }

    func testHRToleranceIsSmall() {
        XCTAssertLessThanOrEqual(Config.hrAlignmentToleranceSeconds, 5)
    }
}
