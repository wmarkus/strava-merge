import Foundation

/// Strava lap data for reconstructing lap boundaries in TCX.
struct StravaLap: Codable, Identifiable {
    let id: Int
    let name: String
    let elapsedTime: Int
    let movingTime: Int
    let startDate: Date
    let distance: Double
    let startIndex: Int
    let endIndex: Int
    let averageWatts: Double?
    let averageCadence: Double?
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let totalElevationGain: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, distance
        case elapsedTime = "elapsed_time"
        case movingTime = "moving_time"
        case startDate = "start_date"
        case startIndex = "start_index"
        case endIndex = "end_index"
        case averageWatts = "average_watts"
        case averageCadence = "average_cadence"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
        case totalElevationGain = "total_elevation_gain"
    }

    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(elapsedTime))
    }
}
