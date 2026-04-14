import Foundation
@testable import ZwiftSync

/// Test double for KeychainService. Stores tokens in memory.
final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Int?

    // MARK: - Call Tracking

    var saveTokensCalls: [(access: String, refresh: String, expiresAt: Int)] = []
    var clearAllCallCount = 0

    // MARK: - Protocol

    func saveTokens(access: String, refresh: String, expiresAt: Int) {
        saveTokensCalls.append((access, refresh, expiresAt))
        self.accessToken = access
        self.refreshToken = refresh
        self.expiresAt = expiresAt
    }

    func getAccessToken() -> String? { accessToken }
    func getRefreshToken() -> String? { refreshToken }
    func getExpiresAt() -> Int? { expiresAt }

    func clearAll() {
        clearAllCallCount += 1
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
    }
}
