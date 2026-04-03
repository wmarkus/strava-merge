import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isStravaConnected = false
    @Published var isHealthKitAuthorized = false

    let stravaService = StravaService()
    let healthKitService = HealthKitService()

    init() {
        isStravaConnected = stravaService.hasValidToken
    }

    func connectStrava() async throws {
        try await stravaService.authorize()
        isStravaConnected = true
    }

    func authorizeHealthKit() async throws {
        try await healthKitService.requestAuthorization()
        isHealthKitAuthorized = true
    }

    func disconnectStrava() {
        stravaService.clearTokens()
        isStravaConnected = false
    }
}
