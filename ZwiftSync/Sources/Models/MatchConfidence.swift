import Foundation

/// Confidence level of a HealthKit workout matching a Strava activity.
enum MatchConfidence: Comparable {
    case noMatch
    case low        // time overlap < 50%
    case medium     // time overlap 50–90%
    case high       // time overlap > 90%

    /// Numeric rank for comparison and sorting.
    var rank: Int {
        switch self {
        case .noMatch: 0
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }

    static func < (lhs: MatchConfidence, rhs: MatchConfidence) -> Bool {
        lhs.rank < rhs.rank
    }

    var label: String {
        switch self {
        case .high: "Match ✓"
        case .medium: "Partial"
        case .low: "Weak"
        case .noMatch: "No Match"
        }
    }
}
