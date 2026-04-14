import Foundation

/// Errors from HealthKit operations.
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
