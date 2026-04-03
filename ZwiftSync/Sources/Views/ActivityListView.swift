import SwiftUI

struct ActivityListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ActivityListViewModel

    init() {
        // Initialize with a placeholder; actual service injected in onAppear
        _viewModel = StateObject(wrappedValue: ActivityListViewModel(
            enrichmentService: EnrichmentService(
                stravaService: StravaService(),
                healthKitService: HealthKitService()
            )
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Finding activities…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await viewModel.loadActivities() } }
                    }
                } else if viewModel.candidates.isEmpty {
                    ContentUnavailableView {
                        Label("All Caught Up", systemImage: "checkmark.circle")
                    } description: {
                        Text("No Strava activities need heart rate data")
                    } actions: {
                        Button("Refresh") { Task { await viewModel.loadActivities() } }
                    }
                } else {
                    List(viewModel.candidates) { candidate in
                        NavigationLink(destination: EnrichDetailView(
                            candidate: candidate,
                            enrichmentService: EnrichmentService(
                                stravaService: appState.stravaService,
                                healthKitService: appState.healthKitService
                            )
                        )) {
                            ActivityRow(candidate: candidate)
                        }
                    }
                }
            }
            .navigationTitle("ZwiftSync")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadActivities() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                await viewModel.loadActivities()
            }
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let candidate: EnrichmentCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(candidate.stravaActivity.name)
                    .font(.headline)
                Spacer()
                MatchBadge(confidence: candidate.matchConfidence)
            }

            HStack(spacing: 12) {
                Label(candidate.stravaActivity.formattedDuration, systemImage: "clock")
                if candidate.stravaActivity.hasPowerData {
                    Label("Power", systemImage: "bolt.fill")
                }
                if candidate.stravaActivity.hasCadenceData {
                    Label("Cadence", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "heart.slash")
                    .foregroundStyle(.red)
                Text("Missing Heart Rate")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let workout = candidate.healthKitWorkout {
                HStack {
                    Image(systemName: "applewatch")
                        .foregroundStyle(.green)
                    Text("Matched: \(workout.startDate.formatted(date: .omitted, time: .shortened)) – \(workout.endDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Match Badge

struct MatchBadge: View {
    let confidence: EnrichmentCandidate.MatchConfidence

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch confidence {
        case .high: "Match ✓"
        case .medium: "Partial"
        case .low: "Weak"
        case .noMatch: "No Match"
        }
    }

    private var color: Color {
        switch confidence {
        case .high: .green
        case .medium: .orange
        case .low: .yellow
        case .noMatch: .red
        }
    }
}
