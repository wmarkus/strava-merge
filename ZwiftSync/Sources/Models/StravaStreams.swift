import Foundation

/// Time-series stream data from a Strava activity.
struct StravaStreams {
    let time: [Int]             // seconds offset from activity start
    let latlng: [[Double]]?     // [lat, lng] pairs
    let altitude: [Double]?
    let watts: [Int]?
    let cadence: [Int]?
    let distance: [Double]?
    let velocitySmooth: [Double]?
    let heartrate: [Int]?

    var count: Int { time.count }
}

/// Raw JSON response from Strava streams endpoint.
struct StravaStreamResponse: Codable {
    let type: String
    let data: AnyCodableArray
    let seriesType: String?
    let originalSize: Int?
    let resolution: String?

    enum CodingKeys: String, CodingKey {
        case type, data
        case seriesType = "series_type"
        case originalSize = "original_size"
        case resolution
    }
}

/// Wrapper to decode heterogeneous JSON arrays from Strava.
struct AnyCodableArray: Codable {
    let values: [Any]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Any] = []
        while !container.isAtEnd {
            if let intVal = try? container.decode(Int.self) {
                result.append(intVal)
            } else if let doubleVal = try? container.decode(Double.self) {
                result.append(doubleVal)
            } else if let arrayVal = try? container.decode([Double].self) {
                result.append(arrayVal)
            } else {
                // skip unknown
                _ = try? container.decode(String.self)
            }
        }
        values = result
    }

    func encode(to encoder: Encoder) throws {
        // Not needed for our use case
    }

    var asIntArray: [Int] {
        values.compactMap { $0 as? Int }
    }

    var asDoubleArray: [Double] {
        values.compactMap { $0 as? Double }
    }

    var asLatLngArray: [[Double]] {
        values.compactMap { $0 as? [Double] }
    }
}
