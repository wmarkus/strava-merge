import Foundation
@testable import ZwiftSync

/// Shared test fixtures for creating model instances.
enum TestFixtures {

    static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func makeActivity(
        id: Int = 12345,
        name: String = "Test Zwift Ride",
        type: String = "VirtualRide",
        sportType: String? = "VirtualRide",
        startDate: Date = baseDate,
        elapsedTime: Int = 3600,
        movingTime: Int = 3500,
        distance: Double = 30_000,
        hasHeartrate: Bool = false,
        averageHeartrate: Double? = nil,
        maxHeartrate: Double? = nil,
        averageWatts: Double? = 200,
        kilojoules: Double? = 720,
        averageCadence: Double? = 85,
        gearId: String? = nil,
        description: String? = nil,
        commute: Bool? = false,
        trainer: Bool? = true,
        externalId: String? = nil
    ) -> StravaActivity {
        StravaActivity(
            id: id,
            name: name,
            type: type,
            sportType: sportType,
            startDate: startDate,
            elapsedTime: elapsedTime,
            movingTime: movingTime,
            distance: distance,
            hasHeartrate: hasHeartrate,
            averageHeartrate: averageHeartrate,
            maxHeartrate: maxHeartrate,
            averageWatts: averageWatts,
            kilojoules: kilojoules,
            averageCadence: averageCadence,
            gearId: gearId,
            description: description,
            commute: commute,
            trainer: trainer,
            externalId: externalId
        )
    }

    static func makeStreams(count: Int) -> StravaStreams {
        StravaStreams(
            time: (0..<count).map { $0 },
            latlng: (0..<count).map { [Double($0) * 0.001, Double($0) * 0.001] },
            altitude: (0..<count).map { Double($0) * 0.5 },
            watts: (0..<count).map { 180 + $0 * 2 },
            cadence: (0..<count).map { 80 + $0 },
            distance: (0..<count).map { Double($0) * 10.0 },
            velocitySmooth: (0..<count).map { 8.0 + Double($0) * 0.1 },
            heartrate: nil
        )
    }

    static func makeHRSamples(startDate: Date = baseDate, count: Int, baseBPM: Double = 140) -> [HRSample] {
        (0..<count).map { i in
            HRSample(
                timestamp: startDate.addingTimeInterval(TimeInterval(i)),
                bpm: baseBPM + Double(i)
            )
        }
    }

    static func makeLap(
        id: Int = 0,
        startIndex: Int,
        endIndex: Int,
        startDate: Date = baseDate,
        elapsed: Int
    ) -> StravaLap {
        StravaLap(
            id: id,
            name: "Lap \(id)",
            elapsedTime: elapsed,
            movingTime: elapsed,
            startDate: startDate,
            distance: Double((endIndex - startIndex) * 10),
            startIndex: startIndex,
            endIndex: endIndex,
            averageWatts: 200,
            averageCadence: 85,
            averageHeartrate: nil,
            maxHeartrate: nil,
            totalElevationGain: 5
        )
    }

    /// JSON representation of a StravaActivity for testing decoding.
    static let activityJSON = """
    {
        "id": 12345,
        "name": "Morning Zwift Ride",
        "type": "VirtualRide",
        "sport_type": "VirtualRide",
        "start_date": "2023-11-14T22:13:20Z",
        "elapsed_time": 3600,
        "moving_time": 3500,
        "distance": 30000.0,
        "has_heartrate": false,
        "average_watts": 200.0,
        "kilojoules": 720.0,
        "average_cadence": 85.0,
        "trainer": true,
        "commute": false
    }
    """

    /// JSON for token response.
    static let tokenResponseJSON = """
    {
        "access_token": "abc123",
        "refresh_token": "def456",
        "expires_at": 1700003600,
        "athlete": {
            "id": 42,
            "firstname": "Test",
            "lastname": "User"
        }
    }
    """

    /// JSON for upload response.
    static let uploadResponseJSON = """
    {
        "id": 9876,
        "status": "Your activity is ready.",
        "activity_id": 54321
    }
    """
}
