import Foundation

/// Abstraction over Keychain token storage.
/// Enables testing without real Keychain access.
protocol KeychainServiceProtocol: Sendable {
    func saveTokens(access: String, refresh: String, expiresAt: Int)
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func getExpiresAt() -> Int?
    func clearAll()
}
