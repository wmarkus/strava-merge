import SwiftUI
import HealthKit

@MainActor
final class ActivityListViewModel: ObservableObject {
    @Published var candidates: [EnrichmentCandidate] = []
    @Published var isLoading = false
    @Published var error: String?

    private let enrichmentService: EnrichmentService

    init(enrichmentService: EnrichmentService) {
        self.enrichmentService = enrichmentService
    }

    func loadActivities() async {
        isLoading = true
        error = nil

        do {
            let activities = try await enrichmentService.findEnrichableActivities()

            var matched: [EnrichmentCandidate] = []
            for activity in activities {
                let candidate = try await enrichmentService.findMatchingWorkout(for: activity)
                matched.append(candidate)
            }

            candidates = matched
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
