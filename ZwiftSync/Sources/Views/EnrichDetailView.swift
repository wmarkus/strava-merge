import SwiftUI

struct EnrichDetailView: View {
    @StateObject private var viewModel: EnrichViewModel

    init(candidate: EnrichmentCandidate, enrichmentService: EnrichmentService) {
        _viewModel = StateObject(wrappedValue: EnrichViewModel(
            candidate: candidate,
            enrichmentService: enrichmentService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Activity info card
                activityInfoCard

                // Data fields comparison
                dataFieldsCard

                // Time shift adjustment
                if viewModel.candidate.matchConfidence != .noMatch {
                    timeShiftCard
                }

                // Action area
                actionArea
            }
            .padding()
        }
        .navigationTitle("Enrich Activity")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Enrich this activity?", isPresented: showConfirmation) {
            Button("Cancel", role: .cancel) { viewModel.reset() }
            Button("Enrich", role: .destructive) {
                Task { await viewModel.confirmEnrich() }
            }
        } message: {
            Text("This will replace the current Strava activity with an enriched version that includes heart rate data.\n\n⚠️ Kudos and comments on the original will be lost.")
        }
    }

    // MARK: - Subviews

    private var activityInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(viewModel.candidate.stravaActivity.name)
                    .font(.title3.bold())
            }

            HStack(spacing: 16) {
                InfoItem(icon: "clock", label: viewModel.candidate.stravaActivity.formattedDuration)
                if viewModel.candidate.stravaActivity.distance > 0 {
                    InfoItem(icon: "arrow.right", label: String(format: "%.1f km", viewModel.candidate.stravaActivity.distance / 1000))
                }
                if let watts = viewModel.candidate.stravaActivity.averageWatts {
                    InfoItem(icon: "bolt.fill", label: "\(Int(watts))W avg")
                }
            }

            Text(viewModel.candidate.stravaActivity.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dataFieldsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Fields")
                .font(.headline)

            DataFieldRow(icon: "bolt.fill", name: "Power", source: "Strava (Zwift)", available: viewModel.candidate.stravaActivity.hasPowerData)
            DataFieldRow(icon: "arrow.trianglehead.2.counterclockwise.rotate.90", name: "Cadence", source: "Strava (Zwift)", available: viewModel.candidate.stravaActivity.hasCadenceData)
            DataFieldRow(icon: "location.fill", name: "GPS", source: "Strava (Zwift)", available: true)
            DataFieldRow(icon: "mountain.2.fill", name: "Altitude", source: "Strava (Zwift)", available: true)

            Divider()

            DataFieldRow(icon: "heart.fill", name: "Heart Rate", source: "Apple Watch", available: viewModel.candidate.healthKitWorkout != nil, highlight: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timeShiftCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Offset")
                .font(.headline)
            Text("Adjust if your devices' clocks were slightly out of sync")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("\(Int(viewModel.timeShiftSeconds))s")
                    .font(.body.monospacedDigit())
                    .frame(width: 50)

                Slider(value: $viewModel.timeShiftSeconds, in: -300...300, step: 1)
            }

            if viewModel.timeShiftSeconds != 0 {
                Button("Reset to 0") {
                    viewModel.timeShiftSeconds = 0
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var actionArea: some View {
        switch viewModel.state {
        case .idle:
            if viewModel.candidate.matchConfidence == .noMatch {
                Text("No matching Apple Watch workout found")
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    viewModel.requestEnrich()
                } label: {
                    Label("Enrich with Heart Rate", systemImage: "heart.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

        case .confirming:
            EmptyView() // handled by alert

        case .pullingStreams, .mergingData, .uploading:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(progressLabel)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()

        case .success:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Activity Enriched!")
                    .font(.headline)

                if let url = viewModel.stravaActivityURL {
                    Link("View on Strava", destination: url)
                        .font(.body.bold())
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()

        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text("Enrichment Failed")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Try Again") { viewModel.reset() }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var progressLabel: String {
        switch viewModel.state {
        case .pullingStreams: "Pulling activity data from Strava…"
        case .mergingData: "Merging heart rate data…"
        case .uploading: "Uploading enriched activity…"
        default: ""
        }
    }

    private var showConfirmation: Binding<Bool> {
        Binding(
            get: { viewModel.state == .confirming },
            set: { if !$0 { viewModel.reset() } }
        )
    }
}

// MARK: - Reusable Components

private struct InfoItem: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct DataFieldRow: View {
    let icon: String
    let name: String
    let source: String
    let available: Bool
    var highlight: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(highlight ? .red : .secondary)
                .frame(width: 24)
            Text(name)
                .font(.body)
            Spacer()
            if available {
                Text(source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: highlight ? "plus.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(highlight ? .orange : .green)
            } else {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
