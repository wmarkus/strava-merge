import Foundation
import HealthKit

/// Abstraction over Strava API communication.
/// Enables dependency injection and testability.
protocol StravaServiceProtocol: Sendable {
    var hasValidToken: Bool { get }

    @MainActor func authorize() async throws
    func clearTokens()

    func getActivities(page: Int, perPage: Int) async throws -> [StravaActivity]
    func getActivityStreams(activityId: Int) async throws -> StravaStreams
    func getActivityLaps(activityId: Int) async throws -> [StravaLap]
    func deleteActivity(activityId: Int) async throws
    func uploadTCX(data: Data, activityType: String, name: String?) async throws -> StravaUploadResponse
    func waitForUpload(uploadId: Int, maxAttempts: Int) async throws -> StravaUploadResponse
    func updateActivity(activityId: Int, update: StravaActivityUpdate) async throws
}

extension StravaServiceProtocol {
    func getActivities(page: Int = 1, perPage: Int = 30) async throws -> [StravaActivity] {
        try await getActivities(page: page, perPage: perPage)
    }

    func uploadTCX(data: Data, activityType: String = "VirtualRide", name: String? = nil) async throws -> StravaUploadResponse {
        try await uploadTCX(data: data, activityType: activityType, name: name)
    }

    func waitForUpload(uploadId: Int, maxAttempts: Int = 20) async throws -> StravaUploadResponse {
        try await waitForUpload(uploadId: uploadId, maxAttempts: maxAttempts)
    }
}
