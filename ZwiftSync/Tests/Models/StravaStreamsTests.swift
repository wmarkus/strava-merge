import XCTest
@testable import ZwiftSync

final class StravaStreamsTests: XCTestCase {

    // MARK: - StravaStreams

    func testCountReturnsTimeArrayLength() {
        let streams = TestFixtures.makeStreams(count: 10)
        XCTAssertEqual(streams.count, 10)
    }

    func testCountWithEmptyStreams() {
        let streams = StravaStreams(
            time: [],
            latlng: nil,
            altitude: nil,
            watts: nil,
            cadence: nil,
            distance: nil,
            velocitySmooth: nil,
            heartrate: nil
        )
        XCTAssertEqual(streams.count, 0)
    }

    func testOptionalStreamsCanBeNil() {
        let streams = StravaStreams(
            time: [0, 1, 2],
            latlng: nil,
            altitude: nil,
            watts: nil,
            cadence: nil,
            distance: nil,
            velocitySmooth: nil,
            heartrate: nil
        )
        XCTAssertNil(streams.latlng)
        XCTAssertNil(streams.altitude)
        XCTAssertNil(streams.watts)
        XCTAssertNil(streams.cadence)
        XCTAssertNil(streams.distance)
        XCTAssertNil(streams.velocitySmooth)
        XCTAssertNil(streams.heartrate)
    }

    // MARK: - AnyCodableArray

    func testIntArrayDecoding() throws {
        let json = "[1, 2, 3, 4, 5]"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodableArray.self, from: data)
        XCTAssertEqual(decoded.asIntArray, [1, 2, 3, 4, 5])
    }

    func testDoubleArrayDecoding() throws {
        let json = "[1.5, 2.7, 3.9]"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodableArray.self, from: data)
        XCTAssertEqual(decoded.asDoubleArray, [1.5, 2.7, 3.9])
    }

    func testLatLngArrayDecoding() throws {
        let json = "[[37.7749, -122.4194], [37.7750, -122.4195]]"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodableArray.self, from: data)
        let latlng = decoded.asLatLngArray
        XCTAssertEqual(latlng.count, 2)
        XCTAssertEqual(latlng[0][0], 37.7749, accuracy: 0.0001)
        XCTAssertEqual(latlng[0][1], -122.4194, accuracy: 0.0001)
    }

    func testEmptyArrayDecoding() throws {
        let json = "[]"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodableArray.self, from: data)
        XCTAssertTrue(decoded.asIntArray.isEmpty)
        XCTAssertTrue(decoded.asDoubleArray.isEmpty)
        XCTAssertTrue(decoded.asLatLngArray.isEmpty)
    }

    // MARK: - StravaStreamResponse

    func testStreamResponseDecoding() throws {
        let json = """
        {
            "type": "time",
            "data": [0, 1, 2, 3],
            "series_type": "distance",
            "original_size": 4,
            "resolution": "high"
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StravaStreamResponse.self, from: data)

        XCTAssertEqual(response.type, "time")
        XCTAssertEqual(response.data.asIntArray, [0, 1, 2, 3])
        XCTAssertEqual(response.seriesType, "distance")
        XCTAssertEqual(response.originalSize, 4)
        XCTAssertEqual(response.resolution, "high")
    }
}
