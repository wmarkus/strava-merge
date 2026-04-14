import Foundation

/// Pure function that calculates the time overlap between a Strava activity
/// and a HealthKit workout, returning a confidence level.
enum OverlapCalculator {

    /// Calculate match confidence based on time overlap ratio.
    ///
    /// - Parameters:
    ///   - activityStart: Strava activity start time
    ///   - activityEnd: Strava activity end time
    ///   - workoutStart: HealthKit workout start time
    ///   - workoutEnd: HealthKit workout end time
    /// - Returns: The confidence level of the match
    static func confidence(
        activityStart: Date,
        activityEnd: Date,
        workoutStart: Date,
        workoutEnd: Date
    ) -> MatchConfidence {
        let activityDuration = activityEnd.timeIntervalSince(activityStart)
        guard activityDuration > 0 else { return .noMatch }

        let overlapStart = max(activityStart, workoutStart)
        let overlapEnd = min(activityEnd, workoutEnd)
        let overlapDuration = max(0, overlapEnd.timeIntervalSince(overlapStart))

        let ratio = overlapDuration / activityDuration
        if ratio > 0.9 { return .high }
        if ratio > 0.5 { return .medium }
        if ratio > 0 { return .low }
        return .noMatch
    }
}
