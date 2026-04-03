import SwiftUI

@MainActor
final class EnrichViewModel: ObservableObject {
    @Published var state: EnrichState = .idle
    @Published var timeShiftSeconds: Double = 0

    let candidate: EnrichmentCandidate
    private let enrichmentService: EnrichmentService

    init(candidate: EnrichmentCandidate, enrichmentService: EnrichmentService) {
        self.candidate = candidate
        self.enrichmentService = enrichmentService
    }

    enum EnrichState: Equatable {
        case idle
        case confirming
        case pullingStreams
        case mergingData
        case uploading
        case success(newActivityId: Int)
        case failed(String)
    }

    func requestEnrich() {
        state = .confirming
    }

    func confirmEnrich() async {
        state = .pullingStreams

        do {
            state = .mergingData
            let result = try await enrichmentService.enrich(
                candidate: candidate,
                timeShiftSeconds: timeShiftSeconds
            )

            if result.success, let newId = result.newActivityId {
                state = .success(newActivityId: newId)
            } else {
                state = .failed(result.error ?? "Unknown error")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }

    var stravaActivityURL: URL? {
        if case .success(let id) = state {
            return URL(string: "https://www.strava.com/activities/\(id)")
        }
        return nil
    }
}
