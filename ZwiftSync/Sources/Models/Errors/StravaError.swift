import Foundation

/// Errors from Strava API operations.
enum StravaError: LocalizedError {
    case authFailed
    case notAuthenticated
    case deleteFailed
    case uploadFailed(String)
    case uploadTimeout
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .authFailed: "Strava authorization failed"
        case .notAuthenticated: "Not connected to Strava"
        case .deleteFailed: "Failed to delete activity"
        case .uploadFailed(let msg): "Upload failed: \(msg)"
        case .uploadTimeout: "Upload timed out"
        case .updateFailed: "Failed to update activity metadata"
        }
    }
}
