import Foundation
import HealthKit

/// Abstraction over HealthKit data access.
/// Enables dependency injection and testability without a real HKHealthStore.
protocol HealthKitServiceProtocol: Sendable {
    func requestAuthorization() async throws
    func findMatchingWorkouts(start: Date, end: Date, tolerance: TimeInterval) -> AsyncThrowingStream<[HKWorkout], Error>
    func getHeartRateSamples(start: Date, end: Date) -> AsyncThrowingStream<[HRSample], Error>
    func getHighResolutionHR(for workout: HKWorkout) -> AsyncThrowingStream<[HRSample], Error>
}

extension HealthKitServiceProtocol {
    func findMatchingWorkouts(start: Date, end: Date) -> AsyncThrowingStream<[HKWorkout], Error> {
        findMatchingWorkouts(start: start, end: end, tolerance: Config.matchToleranceSeconds)
    }
}
