import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isStravaConnected = false
    @Published var isHealthKitAuthorized = false

    let stravaService: any StravaServiceProtocol
    let healthKitService: any HealthKitServiceProtocol

    init(
        stravaService: any StravaServiceProtocol = StravaService(),
        healthKitService: any HealthKitServiceProtocol = HealthKitService()
    ) {
        self.stravaService = stravaService
        self.healthKitService = healthKitService
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
