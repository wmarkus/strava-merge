import Foundation
import HealthKit
@testable import ZwiftSync

/// Test double for StravaService. Configure return values and track calls.
final class MockStravaService: StravaServiceProtocol, @unchecked Sendable {

    // MARK: - Stubs

    var stubbedHasValidToken = true
    var stubbedActivities: [StravaActivity] = []
    var stubbedStreams = StravaStreams(time: [], latlng: nil, altitude: nil, watts: nil, cadence: nil, distance: nil, velocitySmooth: nil, heartrate: nil)
    var stubbedLaps: [StravaLap] = []
    var stubbedUploadResponse = StravaUploadResponse(id: 1, status: "ready", activityId: 99999, error: nil)
    var stubbedWaitResponse: StravaUploadResponse?

    var authorizeError: Error?
    var getActivitiesError: Error?
    var getStreamsError: Error?
    var getLapsError: Error?
    var deleteError: Error?
    var uploadError: Error?
    var waitError: Error?
    var updateError: Error?

    // MARK: - Call Tracking

    var authorizeCallCount = 0
    var clearTokensCallCount = 0
    var getActivitiesCalls: [(page: Int, perPage: Int)] = []
    var getStreamsCalls: [Int] = []
    var getLapsCalls: [Int] = []
    var deleteActivityCalls: [Int] = []
    var uploadTCXCalls: [(data: Data, activityType: String, name: String?)] = []
    var waitForUploadCalls: [(uploadId: Int, maxAttempts: Int)] = []
    var updateActivityCalls: [(activityId: Int, update: StravaActivityUpdate)] = []

    // MARK: - Protocol

    var hasValidToken: Bool { stubbedHasValidToken }

    @MainActor func authorize() async throws {
        authorizeCallCount += 1
        if let error = authorizeError { throw error }
    }

    func clearTokens() {
        clearTokensCallCount += 1
    }

    func getActivities(page: Int, perPage: Int) async throws -> [StravaActivity] {
        getActivitiesCalls.append((page, perPage))
        if let error = getActivitiesError { throw error }
        return stubbedActivities
    }

    func getActivityStreams(activityId: Int) async throws -> StravaStreams {
        getStreamsCalls.append(activityId)
        if let error = getStreamsError { throw error }
        return stubbedStreams
    }

    func getActivityLaps(activityId: Int) async throws -> [StravaLap] {
        getLapsCalls.append(activityId)
        if let error = getLapsError { throw error }
        return stubbedLaps
    }

    func deleteActivity(activityId: Int) async throws {
        deleteActivityCalls.append(activityId)
        if let error = deleteError { throw error }
    }

    func uploadTCX(data: Data, activityType: String, name: String?) async throws -> StravaUploadResponse {
        uploadTCXCalls.append((data, activityType, name))
        if let error = uploadError { throw error }
        return stubbedUploadResponse
    }

    func waitForUpload(uploadId: Int, maxAttempts: Int) async throws -> StravaUploadResponse {
        waitForUploadCalls.append((uploadId, maxAttempts))
        if let error = waitError { throw error }
        return stubbedWaitResponse ?? stubbedUploadResponse
    }

    func updateActivity(activityId: Int, update: StravaActivityUpdate) async throws {
        updateActivityCalls.append((activityId, update))
        if let error = updateError { throw error }
    }
}
