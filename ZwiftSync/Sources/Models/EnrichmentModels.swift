import Foundation
import HealthKit

/// A heart rate sample from HealthKit.
struct HRSample: Equatable {
    let timestamp: Date
    let bpm: Double
}

/// A matched pair: a Strava activity and its corresponding HealthKit workout.
struct EnrichmentCandidate: Identifiable {
    let id: Int  // Strava activity ID
    let stravaActivity: StravaActivity
    let healthKitWorkout: HKWorkout?
    let matchConfidence: MatchConfidence
}

/// Result of an enrichment operation.
struct EnrichmentResult {
    let originalActivityId: Int
    let newActivityId: Int?
    let hrSamplesInjected: Int
    let success: Bool
    let error: String?
}
