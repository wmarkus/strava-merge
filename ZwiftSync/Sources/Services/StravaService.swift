import Foundation
import AuthenticationServices

/// Handles Strava OAuth and API communication.
final class StravaService: StravaServiceProtocol, @unchecked Sendable {
    private let keychainService = KeychainService.shared
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    var hasValidToken: Bool {
        keychainService.getAccessToken() != nil
    }

    // MARK: - OAuth

    @MainActor
    func authorize() async throws {
        let codeVerifier = PKCEHelper.generateCodeVerifier()
        let codeChallenge = PKCEHelper.generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(string: Config.stravaAuthURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Config.stravaClientID),
            URLQueryItem(name: "redirect_uri", value: Config.stravaRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Config.stravaScopes),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        let authURL = components.url!
        let callbackScheme = "zwiftsync"

        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url,
                      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: StravaError.authFailed)
                    return
                }
                continuation.resume(returning: code)
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = PresentationContextProvider.shared
            session.start()
        }

        try await exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
    }

    private func exchangeCodeForToken(code: String, codeVerifier: String) async throws {
        var request = URLRequest(url: URL(string: Config.stravaTokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": Config.stravaClientID,
            "code": code,
            "grant_type": "authorization_code",
            "code_verifier": codeVerifier,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        let tokenResponse = try decoder.decode(StravaTokenResponse.self, from: data)
        keychainService.saveTokens(access: tokenResponse.accessToken,
                                   refresh: tokenResponse.refreshToken,
                                   expiresAt: tokenResponse.expiresAt)
    }

    private func refreshTokenIfNeeded() async throws -> String {
        guard let accessToken = keychainService.getAccessToken(),
              let refreshToken = keychainService.getRefreshToken(),
              let expiresAt = keychainService.getExpiresAt() else {
            throw StravaError.notAuthenticated
        }

        if Date().timeIntervalSince1970 < TimeInterval(expiresAt) - 60 {
            return accessToken
        }

        var request = URLRequest(url: URL(string: Config.stravaTokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": Config.stravaClientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        let tokenResponse = try decoder.decode(StravaTokenResponse.self, from: data)
        keychainService.saveTokens(access: tokenResponse.accessToken,
                                   refresh: tokenResponse.refreshToken,
                                   expiresAt: tokenResponse.expiresAt)
        return tokenResponse.accessToken
    }

    func clearTokens() {
        keychainService.clearAll()
    }

    // MARK: - Activities

    /// Fetch recent activities for the authenticated athlete.
    func getActivities(page: Int = 1, perPage: Int = 30) async throws -> [StravaActivity] {
        let token = try await refreshTokenIfNeeded()
        var components = URLComponents(string: "\(Config.stravaBaseURL)/athlete/activities")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: request)
        return try decoder.decode([StravaActivity].self, from: data)
    }

    /// Fetch detailed activity streams.
    func getActivityStreams(activityId: Int) async throws -> StravaStreams {
        let token = try await refreshTokenIfNeeded()
        let keys = "time,latlng,altitude,watts,cadence,distance,velocity_smooth,heartrate"
        var components = URLComponents(string: "\(Config.stravaBaseURL)/activities/\(activityId)/streams")!
        components.queryItems = [
            URLQueryItem(name: "keys", value: keys),
            URLQueryItem(name: "key_type", value: "type"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: request)
        let streams = try decoder.decode([StravaStreamResponse].self, from: data)

        return parseStreams(streams)
    }

    /// Fetch laps for an activity.
    func getActivityLaps(activityId: Int) async throws -> [StravaLap] {
        let token = try await refreshTokenIfNeeded()
        let url = URL(string: "\(Config.stravaBaseURL)/activities/\(activityId)/laps")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: request)
        return try decoder.decode([StravaLap].self, from: data)
    }

    /// Delete an activity.
    func deleteActivity(activityId: Int) async throws {
        let token = try await refreshTokenIfNeeded()
        let url = URL(string: "\(Config.stravaBaseURL)/activities/\(activityId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StravaError.deleteFailed
        }
    }

    /// Upload a TCX file as a new activity.
    func uploadTCX(data tcxData: Data, activityType: String = "VirtualRide", name: String? = nil) async throws -> StravaUploadResponse {
        let token = try await refreshTokenIfNeeded()
        let url = URL(string: "\(Config.stravaBaseURL)/uploads")!

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // data_type
        body.appendMultipart(boundary: boundary, name: "data_type", value: "tcx")
        // activity_type
        body.appendMultipart(boundary: boundary, name: "activity_type", value: activityType)
        // name
        if let name {
            body.appendMultipart(boundary: boundary, name: "name", value: name)
        }
        // file
        body.appendMultipartFile(boundary: boundary, name: "file", filename: "activity.tcx", mimeType: "application/xml", data: tcxData)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (responseData, _) = try await session.data(for: request)
        return try decoder.decode(StravaUploadResponse.self, from: responseData)
    }

    /// Poll upload status until complete.
    func waitForUpload(uploadId: Int, maxAttempts: Int = 20) async throws -> StravaUploadResponse {
        let token = try await refreshTokenIfNeeded()

        for _ in 0..<maxAttempts {
            try await Task.sleep(for: .seconds(2))

            let url = URL(string: "\(Config.stravaBaseURL)/uploads/\(uploadId)")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await session.data(for: request)
            let status = try decoder.decode(StravaUploadResponse.self, from: data)

            if status.activityId != nil {
                return status
            }
            if let error = status.error, !error.isEmpty {
                throw StravaError.uploadFailed(error)
            }
        }
        throw StravaError.uploadTimeout
    }

    /// Update activity metadata (name, description, gear, etc.).
    func updateActivity(activityId: Int, update: StravaActivityUpdate) async throws {
        let token = try await refreshTokenIfNeeded()
        let url = URL(string: "\(Config.stravaBaseURL)/activities/\(activityId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(update)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StravaError.updateFailed
        }
    }

    // MARK: - Helpers

    private func parseStreams(_ streams: [StravaStreamResponse]) -> StravaStreams {
        var time: [Int] = []
        var latlng: [[Double]]?
        var altitude: [Double]?
        var watts: [Int]?
        var cadence: [Int]?
        var distance: [Double]?
        var velocitySmooth: [Double]?
        var heartrate: [Int]?

        for stream in streams {
            switch stream.type {
            case "time": time = stream.data.asIntArray
            case "latlng": latlng = stream.data.asLatLngArray
            case "altitude": altitude = stream.data.asDoubleArray
            case "watts": watts = stream.data.asIntArray
            case "cadence": cadence = stream.data.asIntArray
            case "distance": distance = stream.data.asDoubleArray
            case "velocity_smooth": velocitySmooth = stream.data.asDoubleArray
            case "heartrate": heartrate = stream.data.asIntArray
            default: break
            }
        }

        return StravaStreams(
            time: time,
            latlng: latlng,
            altitude: altitude,
            watts: watts,
            cadence: cadence,
            distance: distance,
            velocitySmooth: velocitySmooth,
            heartrate: heartrate
        )
    }
}

// MARK: - Presentation Context

@MainActor
final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Multipart Helpers

extension Data {
    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartFile(boundary: String, name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
