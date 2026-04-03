import Foundation

enum Config {
    // MARK: - Strava OAuth
    /// Register your app at https://www.strava.com/settings/api
    static let stravaClientID = "YOUR_CLIENT_ID"
    static let stravaRedirectURI = "zwiftsync://oauth/callback"
    static let stravaAuthURL = "https://www.strava.com/oauth/mobile/authorize"
    static let stravaTokenURL = "https://www.strava.com/oauth/token"
    static let stravaBaseURL = "https://www.strava.com/api/v3"
    static let stravaScopes = "activity:read_all,activity:write"

    // MARK: - Merge Settings
    /// Maximum time offset (seconds) allowed when matching HealthKit workouts to Strava activities
    static let matchToleranceSeconds: TimeInterval = 120
    /// Maximum time offset (seconds) for nearest-neighbor HR sample matching
    static let hrAlignmentToleranceSeconds: TimeInterval = 2
}
