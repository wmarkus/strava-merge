import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var isConnecting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                heroSection
                Spacer()
                setupSteps
                errorMessage
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("ZwiftSync")
                .font(.largeTitle.bold())

            Text("Enrich your Strava rides with\nApple Watch heart rate data")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var setupSteps: some View {
        VStack(spacing: 20) {
            SetupStep(
                number: 1,
                title: "Connect Strava",
                subtitle: "We'll read your rides and upload enriched ones",
                isComplete: appState.isStravaConnected,
                action: connectStrava
            )

            SetupStep(
                number: 2,
                title: "Allow Health Access",
                subtitle: "To read heart rate from your Apple Watch workouts",
                isComplete: appState.isHealthKitAuthorized,
                action: authorizeHealthKit
            )
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let error {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func connectStrava() {
        Task {
            isConnecting = true
            error = nil
            do {
                try await appState.connectStrava()
            } catch {
                self.error = error.localizedDescription
            }
            isConnecting = false
        }
    }

    private func authorizeHealthKit() {
        Task {
            error = nil
            do {
                try await appState.authorizeHealthKit()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Setup Step Row

struct SetupStep: View {
    let number: Int
    let title: String
    let subtitle: String
    let isComplete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isComplete ? Color.green : Color.orange)
                        .frame(width: 36, height: 36)

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                    } else {
                        Text("\(number)")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isComplete {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isComplete)
    }
}
