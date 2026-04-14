import XCTest
@testable import ZwiftSync

final class MockKeychainServiceTests: XCTestCase {

    func testSaveAndRetrieveTokens() {
        let keychain = MockKeychainService()
        keychain.saveTokens(access: "token", refresh: "refresh", expiresAt: 1234)

        XCTAssertEqual(keychain.getAccessToken(), "token")
        XCTAssertEqual(keychain.getRefreshToken(), "refresh")
        XCTAssertEqual(keychain.getExpiresAt(), 1234)
    }

    func testClearAllRemovesTokens() {
        let keychain = MockKeychainService()
        keychain.saveTokens(access: "token", refresh: "refresh", expiresAt: 1234)
        keychain.clearAll()

        XCTAssertNil(keychain.getAccessToken())
        XCTAssertNil(keychain.getRefreshToken())
        XCTAssertNil(keychain.getExpiresAt())
    }

    func testClearAllTracksCallCount() {
        let keychain = MockKeychainService()
        keychain.clearAll()
        keychain.clearAll()
        XCTAssertEqual(keychain.clearAllCallCount, 2)
    }

    func testSaveTokensTracksCallHistory() {
        let keychain = MockKeychainService()
        keychain.saveTokens(access: "a", refresh: "b", expiresAt: 1)
        keychain.saveTokens(access: "c", refresh: "d", expiresAt: 2)

        XCTAssertEqual(keychain.saveTokensCalls.count, 2)
        XCTAssertEqual(keychain.saveTokensCalls[0].access, "a")
        XCTAssertEqual(keychain.saveTokensCalls[1].access, "c")
    }

    func testInitialStateIsEmpty() {
        let keychain = MockKeychainService()
        XCTAssertNil(keychain.getAccessToken())
        XCTAssertNil(keychain.getRefreshToken())
        XCTAssertNil(keychain.getExpiresAt())
    }
}
