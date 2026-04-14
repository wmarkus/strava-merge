import Foundation
import HealthKit
@testable import ZwiftSync

/// Test double for HealthKitService. Returns pre-configured data.
final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {

    // MARK: - Stubs

    var stubbedWorkouts: [HKWorkout] = []
    var stubbedHRSamples: [HRSample] = []
    var stubbedHighResHR: [HRSample] = []

    var requestAuthError: Error?
    var findWorkoutsError: Error?
    var getHRError: Error?
    var getHighResError: Error?

    // MARK: - Call Tracking

    var requestAuthCallCount = 0
    var findWorkoutsCalls: [(start: Date, end: Date, tolerance: TimeInterval)] = []
    var getHRCalls: [(start: Date, end: Date)] = []
    var getHighResCalls: [HKWorkout] = []

    // MARK: - Protocol

    func requestAuthorization() async throws {
        requestAuthCallCount += 1
        if let error = requestAuthError { throw error }
    }

    func findMatchingWorkouts(start: Date, end: Date, tolerance: TimeInterval) -> AsyncThrowingStream<[HKWorkout], Error> {
        findWorkoutsCalls.append((start, end, tolerance))
        return AsyncThrowingStream { continuation in
            if let error = self.findWorkoutsError {
                continuation.finish(throwing: error)
            } else {
                continuation.yield(self.stubbedWorkouts)
                continuation.finish()
            }
        }
    }

    func getHeartRateSamples(start: Date, end: Date) -> AsyncThrowingStream<[HRSample], Error> {
        getHRCalls.append((start, end))
        return AsyncThrowingStream { continuation in
            if let error = self.getHRError {
                continuation.finish(throwing: error)
            } else {
                continuation.yield(self.stubbedHRSamples)
                continuation.finish()
            }
        }
    }

    func getHighResolutionHR(for workout: HKWorkout) -> AsyncThrowingStream<[HRSample], Error> {
        getHighResCalls.append(workout)
        return AsyncThrowingStream { continuation in
            if let error = self.getHighResError {
                continuation.finish(throwing: error)
            } else {
                continuation.yield(self.stubbedHighResHR)
                continuation.finish()
            }
        }
    }
}
