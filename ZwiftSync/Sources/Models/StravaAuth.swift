import Foundation

/// Strava OAuth token response.
struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let athlete: StravaAthlete?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athlete
    }

    var expirationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(expiresAt))
    }

    var isExpired: Bool {
        Date() >= expirationDate
    }
}

struct StravaAthlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
}

/// Strava upload status response.
struct StravaUploadResponse: Codable {
    let id: Int
    let status: String
    let activityId: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case id, status, error
        case activityId = "activity_id"
    }
}

/// Strava activity update payload.
struct StravaActivityUpdate: Codable {
    let name: String?
    let description: String?
    let type: String?
    let sportType: String?
    let gearId: String?
    let commute: Bool?
    let trainer: Bool?

    enum CodingKeys: String, CodingKey {
        case name, description, type, commute, trainer
        case sportType = "sport_type"
        case gearId = "gear_id"
    }
}
