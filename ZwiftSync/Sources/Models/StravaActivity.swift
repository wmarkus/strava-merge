import Foundation

/// A Strava activity summary from the athlete's activity list.
struct StravaActivity: Identifiable, Codable {
    let id: Int
    let name: String
    let type: String
    let sportType: String?
    let startDate: Date
    let elapsedTime: Int
    let movingTime: Int
    let distance: Double
    let hasHeartrate: Bool
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let averageWatts: Double?
    let kilojoules: Double?
    let averageCadence: Double?
    let gearId: String?
    let description: String?
    let commute: Bool?
    let trainer: Bool?
    let externalId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type, distance, description, commute, trainer
        case sportType = "sport_type"
        case startDate = "start_date"
        case elapsedTime = "elapsed_time"
        case movingTime = "moving_time"
        case hasHeartrate = "has_heartrate"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
        case averageWatts = "average_watts"
        case kilojoules
        case averageCadence = "average_cadence"
        case gearId = "gear_id"
        case externalId = "external_id"
    }

    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(elapsedTime))
    }

    var formattedDuration: String {
        let hours = elapsedTime / 3600
        let minutes = (elapsedTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var hasPowerData: Bool { averageWatts != nil }
    var hasCadenceData: Bool { averageCadence != nil }
}
