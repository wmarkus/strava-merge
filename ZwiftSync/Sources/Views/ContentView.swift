import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isStravaConnected {
                ActivityListView(
                    enrichmentService: EnrichmentService(
                        stravaService: appState.stravaService,
                        healthKitService: appState.healthKitService
                    )
                )
            } else {
                SetupView()
            }
        }
    }
}
