import Foundation
import HealthKit

/// Reads heart rate and workout data from HealthKit.
final class HealthKitService: @unchecked Sendable {
    private let healthStore = HKHealthStore()

    /// Request authorization to read heart rate and workout data.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKObjectType.workoutType(),
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Query HealthKit workouts that overlap with a given time window.
    func findMatchingWorkouts(start: Date, end: Date, tolerance: TimeInterval = Config.matchToleranceSeconds) -> AsyncThrowingStream<[HKWorkout], Error> {
        let adjustedStart = start.addingTimeInterval(-tolerance)
        let adjustedEnd = end.addingTimeInterval(tolerance)

        return AsyncThrowingStream { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: adjustedStart, end: adjustedEnd)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.yield(workouts)
                continuation.finish()
            }

            healthStore.execute(query)
        }
    }

    /// Get per-second heart rate samples for a time window.
    func getHeartRateSamples(start: Date, end: Date) -> AsyncThrowingStream<[HRSample], Error> {
        return AsyncThrowingStream { continuation in
            let heartRateType = HKQuantityType(.heartRate)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }

                let hrSamples = (samples as? [HKQuantitySample])?.map { sample in
                    HRSample(
                        timestamp: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    )
                } ?? []

                continuation.yield(hrSamples)
                continuation.finish()
            }

            healthStore.execute(query)
        }
    }

    /// Get high-resolution heart rate data using quantity series (available iOS 15+).
    /// This provides ~1Hz samples during workouts.
    func getHighResolutionHR(for workout: HKWorkout) -> AsyncThrowingStream<[HRSample], Error> {
        return AsyncThrowingStream { continuation in
            let heartRateType = HKQuantityType(.heartRate)
            let predicate = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate
            )
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

            // First get samples, then try to get series data for each
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                guard let self else {
                    continuation.finish()
                    return
                }

                if let error {
                    continuation.finish(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.yield([])
                    continuation.finish()
                    return
                }

                // Try series query for high-res data
                var allSamples: [HRSample] = []
                let group = DispatchGroup()
                let lock = NSLock()

                for sample in quantitySamples {
                    group.enter()
                    let seriesQuery = HKQuantitySeriesSampleQuery(quantityType: heartRateType, predicate: HKQuery.predicateForObject(with: sample.uuid)) { _, quantity, dateInterval, _, done, seriesError in
                        if let quantity, let dateInterval {
                            let hr = HRSample(
                                timestamp: dateInterval.start,
                                bpm: quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                            )
                            lock.lock()
                            allSamples.append(hr)
                            lock.unlock()
                        }
                        if done {
                            if seriesError != nil || allSamples.isEmpty {
                                // Fallback: use the sample itself
                                let hr = HRSample(
                                    timestamp: sample.startDate,
                                    bpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                                )
                                lock.lock()
                                allSamples.append(hr)
                                lock.unlock()
                            }
                            group.leave()
                        }
                    }
                    self.healthStore.execute(seriesQuery)
                }

                group.notify(queue: .global()) {
                    allSamples.sort { $0.timestamp < $1.timestamp }
                    continuation.yield(allSamples)
                    continuation.finish()
                }
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable: "HealthKit is not available on this device"
        case .authorizationDenied: "HealthKit access was denied"
        }
    }
}
