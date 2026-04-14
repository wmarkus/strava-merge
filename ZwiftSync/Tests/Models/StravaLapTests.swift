import XCTest
@testable import ZwiftSync

final class StravaLapTests: XCTestCase {

    // MARK: - Computed Properties

    func testEndDateIsStartPlusElapsed() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let lap = TestFixtures.makeLap(startIndex: 0, endIndex: 9, startDate: base, elapsed: 600)
        let expected = base.addingTimeInterval(600)
        XCTAssertEqual(lap.endDate, expected)
    }

    func testEndDateWithZeroElapsed() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let lap = TestFixtures.makeLap(startIndex: 0, endIndex: 0, startDate: base, elapsed: 0)
        XCTAssertEqual(lap.endDate, base)
    }

    // MARK: - JSON Decoding

    func testDecodesFromJSON() throws {
        let json = """
        {
            "id": 42,
            "name": "Lap 1",
            "elapsed_time": 600,
            "moving_time": 590,
            "start_date": "2023-11-14T22:13:20Z",
            "distance": 5000.0,
            "start_index": 0,
            "end_index": 599,
            "average_watts": 200.0,
            "average_cadence": 85.0,
            "total_elevation_gain": 50.0
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let lap = try decoder.decode(StravaLap.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(lap.id, 42)
        XCTAssertEqual(lap.name, "Lap 1")
        XCTAssertEqual(lap.elapsedTime, 600)
        XCTAssertEqual(lap.startIndex, 0)
        XCTAssertEqual(lap.endIndex, 599)
        XCTAssertEqual(lap.distance, 5000.0)
        XCTAssertEqual(lap.averageWatts, 200.0)
    }

    func testDecodesWithOptionalFieldsNil() throws {
        let json = """
        {
            "id": 1,
            "name": "Lap",
            "elapsed_time": 60,
            "moving_time": 55,
            "start_date": "2023-11-14T22:13:20Z",
            "distance": 100.0,
            "start_index": 0,
            "end_index": 59
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let lap = try decoder.decode(StravaLap.self, from: json.data(using: .utf8)!)

        XCTAssertNil(lap.averageWatts)
        XCTAssertNil(lap.averageCadence)
        XCTAssertNil(lap.averageHeartrate)
        XCTAssertNil(lap.maxHeartrate)
        XCTAssertNil(lap.totalElevationGain)
    }

    // MARK: - Identifiable

    func testIdentifiableById() {
        let lap1 = TestFixtures.makeLap(id: 1, startIndex: 0, endIndex: 9, elapsed: 10)
        let lap2 = TestFixtures.makeLap(id: 2, startIndex: 10, endIndex: 19, elapsed: 10)
        XCTAssertNotEqual(lap1.id, lap2.id)
    }
}
