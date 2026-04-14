import Foundation

/// Orchestrates the full enrichment pipeline:
/// pull streams → match HR → merge → delete old → upload new → copy metadata.
final class EnrichmentService {
    private let stravaService: any StravaServiceProtocol
    private let healthKitService: any HealthKitServiceProtocol

    init(stravaService: any StravaServiceProtocol, healthKitService: any HealthKitServiceProtocol) {
        self.stravaService = stravaService
        self.healthKitService = healthKitService
    }

    /// Find Strava activities that are missing heart rate data.
    func findEnrichableActivities() async throws -> [StravaActivity] {
        let activities = try await stravaService.getActivities(perPage: 30)
        return activities.filter { !$0.hasHeartrate && ($0.trainer == true || $0.type == "VirtualRide") }
    }

    /// Match a Strava activity to the best HealthKit workout.
    func findMatchingWorkout(for activity: StravaActivity) async throws -> EnrichmentCandidate {
        var bestWorkout: (workout: HKWorkout, confidence: MatchConfidence)?

        for try await workouts in healthKitService.findMatchingWorkouts(start: activity.startDate, end: activity.endDate) {
            for workout in workouts {
                let confidence = OverlapCalculator.confidence(
                    activityStart: activity.startDate,
                    activityEnd: activity.endDate,
                    workoutStart: workout.startDate,
                    workoutEnd: workout.endDate
                )

                if let current = bestWorkout {
                    if confidence > current.confidence {
                        bestWorkout = (workout, confidence)
                    }
                } else {
                    bestWorkout = (workout, confidence)
                }
            }
        }

        return EnrichmentCandidate(
            id: activity.id,
            stravaActivity: activity,
            healthKitWorkout: bestWorkout?.workout,
            matchConfidence: bestWorkout?.confidence ?? .noMatch
        )
    }

    /// Execute the full enrichment pipeline for an activity.
    func enrich(candidate: EnrichmentCandidate, timeShiftSeconds: Double = 0) async throws -> EnrichmentResult {
        let activity = candidate.stravaActivity

        guard let workout = candidate.healthKitWorkout else {
            throw EnrichmentError.noMatchingWorkout
        }

        // 1. Pull streams and laps from Strava
        async let streamsTask = stravaService.getActivityStreams(activityId: activity.id)
        async let lapsTask = stravaService.getActivityLaps(activityId: activity.id)

        let streams: StravaStreams
        let laps: [StravaLap]
        do {
            streams = try await streamsTask
            laps = try await lapsTask
        } catch {
            throw error
        }

        // 2. Get HR data from HealthKit
        var hrSamples: [HRSample] = []
        for try await samples in healthKitService.getHighResolutionHR(for: workout) {
            hrSamples = samples
        }

        guard !hrSamples.isEmpty else {
            throw EnrichmentError.noHeartRateData
        }

        // 3. Generate merged TCX
        let tcxData = TCXGenerator.generate(
            activity: activity,
            streams: streams,
            hrSamples: hrSamples,
            laps: laps.isEmpty ? nil : laps,
            timeShiftSeconds: timeShiftSeconds
        )

        // 4. Upload merged file to Strava
        let uploadResponse = try await stravaService.uploadTCX(
            data: tcxData,
            activityType: activity.type,
            name: activity.name
        )

        // 5. Wait for upload to process
        let finalUpload = try await stravaService.waitForUpload(uploadId: uploadResponse.id)

        guard let newActivityId = finalUpload.activityId else {
            throw EnrichmentError.uploadDidNotProduceActivity
        }

        // 6. Copy metadata to new activity
        let update = StravaActivityUpdate(
            name: activity.name,
            description: activity.description,
            type: activity.type,
            sportType: activity.sportType,
            gearId: activity.gearId,
            commute: activity.commute,
            trainer: activity.trainer
        )
        try await stravaService.updateActivity(activityId: newActivityId, update: update)

        // 7. Delete original activity (only after successful upload + metadata copy)
        try await stravaService.deleteActivity(activityId: activity.id)

        return EnrichmentResult(
            originalActivityId: activity.id,
            newActivityId: newActivityId,
            hrSamplesInjected: hrSamples.count,
            success: true,
            error: nil
        )
    }
}
