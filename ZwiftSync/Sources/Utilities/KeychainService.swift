import Foundation
import Security

/// Simple Keychain wrapper for storing Strava OAuth tokens.
final class KeychainService: KeychainServiceProtocol, Sendable {
    static let shared = KeychainService()
    private let service = "com.zwiftsync.strava"

    private init() {}

    func saveTokens(access: String, refresh: String, expiresAt: Int) {
        set(key: "access_token", value: access)
        set(key: "refresh_token", value: refresh)
        set(key: "expires_at", value: "\(expiresAt)")
    }

    func getAccessToken() -> String? { get(key: "access_token") }
    func getRefreshToken() -> String? { get(key: "refresh_token") }
    func getExpiresAt() -> Int? {
        guard let str = get(key: "expires_at") else { return nil }
        return Int(str)
    }

    func clearAll() {
        delete(key: "access_token")
        delete(key: "refresh_token")
        delete(key: "expires_at")
    }

    // MARK: - Private

    private func set(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
