import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDisconnectAlert = false

    var body: some View {
        List {
            Section("Connections") {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(.orange)
                    Text("Strava")
                    Spacer()
                    if appState.isStravaConnected {
                        Text("Connected")
                            .foregroundStyle(.green)
                    } else {
                        Text("Not connected")
                            .foregroundStyle(.red)
                    }
                }

                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("HealthKit")
                    Spacer()
                    if appState.isHealthKitAuthorized {
                        Text("Authorized")
                            .foregroundStyle(.green)
                    } else {
                        Text("Not authorized")
                            .foregroundStyle(.red)
                    }
                }

                if appState.isStravaConnected {
                    Button("Disconnect Strava", role: .destructive) {
                        showDisconnectAlert = true
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                Link("Source Code", destination: URL(string: "https://github.com/wmarkus/strava-merge")!)

                Link("Privacy Policy", destination: URL(string: "https://github.com/wmarkus/strava-merge#privacy")!)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it works")
                        .font(.headline)
                    Text("ZwiftSync pulls your Zwift ride data from Strava, merges it with Apple Watch heart rate data from HealthKit, and uploads an enriched activity back to Strava.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("⚠️ Enriching replaces the original activity. Kudos and comments will be lost.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Disconnect Strava?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                appState.disconnectStrava()
            }
        } message: {
            Text("You'll need to reconnect to use ZwiftSync.")
        }
    }
}
