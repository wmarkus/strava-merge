import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDisconnectAlert = false

    var body: some View {
        List {
            connectionsSection
            aboutSection
            howItWorksSection
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

    // MARK: - Sections

    private var connectionsSection: some View {
        Section("Connections") {
            ConnectionRow(
                icon: "figure.run",
                iconColor: .orange,
                name: "Strava",
                status: appState.isStravaConnected ? "Connected" : "Not connected",
                isConnected: appState.isStravaConnected
            )

            ConnectionRow(
                icon: "heart.fill",
                iconColor: .red,
                name: "HealthKit",
                status: appState.isHealthKitAuthorized ? "Authorized" : "Not authorized",
                isConnected: appState.isHealthKitAuthorized
            )

            if appState.isStravaConnected {
                Button("Disconnect Strava", role: .destructive) {
                    showDisconnectAlert = true
                }
            }
        }
    }

    private var aboutSection: some View {
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
    }

    private var howItWorksSection: some View {
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
}

// MARK: - Connection Row

struct ConnectionRow: View {
    let icon: String
    let iconColor: Color
    let name: String
    let status: String
    let isConnected: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(name)
            Spacer()
            Text(status)
                .foregroundStyle(isConnected ? .green : .red)
        }
    }
}
