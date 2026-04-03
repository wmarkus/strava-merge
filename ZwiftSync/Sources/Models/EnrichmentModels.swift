import Foundation
import HealthKit

/// A heart rate sample from HealthKit.
struct HRSample {
    let timestamp: Date
    let bpm: Double
}

/// A matched pair: a Strava activity and its corresponding HealthKit workout.
struct EnrichmentCandidate: Identifiable {
    let id: Int  // Strava activity ID
    let stravaActivity: StravaActivity
    let healthKitWorkout: HKWorkout?
    let matchConfidence: MatchConfidence

    enum MatchConfidence {
        case high       // time overlap > 90%
        case medium     // time overlap 50-90%
        case low        // time overlap < 50%
        case noMatch    // no HealthKit workout found
    }
}

/// Result of an enrichment operation.
struct EnrichmentResult {
    let originalActivityId: Int
    let newActivityId: Int?
    let hrSamplesInjected: Int
    let success: Bool
    let error: String?
}
