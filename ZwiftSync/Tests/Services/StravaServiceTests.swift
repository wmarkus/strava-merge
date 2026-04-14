import XCTest
@testable import ZwiftSync

final class StravaServiceTests: XCTestCase {

    // MARK: - Token Validation

    func testHasValidTokenWhenKeychainHasToken() {
        let keychain = MockKeychainService()
        keychain.saveTokens(access: "token", refresh: "refresh", expiresAt: 9999999999)
        let service = StravaService(keychainService: keychain)

        XCTAssertTrue(service.hasValidToken)
    }

    func testHasNoValidTokenWhenKeychainEmpty() {
        let keychain = MockKeychainService()
        let service = StravaService(keychainService: keychain)

        XCTAssertFalse(service.hasValidToken)
    }

    func testClearTokensDelegatesToKeychain() {
        let keychain = MockKeychainService()
        keychain.saveTokens(access: "token", refresh: "refresh", expiresAt: 1234)
        let service = StravaService(keychainService: keychain)

        service.clearTokens()

        XCTAssertNil(keychain.getAccessToken())
        XCTAssertEqual(keychain.clearAllCallCount, 1)
    }

    // MARK: - Error Types

    func testStravaErrorDescriptions() {
        let cases: [(StravaError, String)] = [
            (.authFailed, "Strava authorization failed"),
            (.notAuthenticated, "Not connected to Strava"),
            (.deleteFailed, "Failed to delete activity"),
            (.uploadFailed("timeout"), "Upload failed: timeout"),
            (.uploadTimeout, "Upload timed out"),
            (.updateFailed, "Failed to update activity metadata"),
        ]

        for (error, expected) in cases {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }
}
