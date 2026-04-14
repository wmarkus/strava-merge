import Foundation

/// Errors from the enrichment pipeline.
enum EnrichmentError: LocalizedError {
    case noMatchingWorkout
    case noHeartRateData
    case uploadDidNotProduceActivity

    var errorDescription: String? {
        switch self {
        case .noMatchingWorkout: "No matching Apple Watch workout found"
        case .noHeartRateData: "No heart rate data available for this workout"
        case .uploadDidNotProduceActivity: "Upload completed but no activity was created"
        }
    }
}
