import XCTest
@testable import ZwiftSync

final class StravaActivityTests: XCTestCase {

    // MARK: - Computed Properties

    func testEndDateIsStartPlusElapsedTime() {
        let activity = TestFixtures.makeActivity(elapsedTime: 3600)
        let expected = activity.startDate.addingTimeInterval(3600)
        XCTAssertEqual(activity.endDate, expected)
    }

    func testEndDateWithZeroElapsedTime() {
        let activity = TestFixtures.makeActivity(elapsedTime: 0)
        XCTAssertEqual(activity.endDate, activity.startDate)
    }

    func testFormattedDurationHoursAndMinutes() {
        let activity = TestFixtures.makeActivity(elapsedTime: 5400) // 1h 30m
        XCTAssertEqual(activity.formattedDuration, "1h 30m")
    }

    func testFormattedDurationMinutesOnly() {
        let activity = TestFixtures.makeActivity(elapsedTime: 2700) // 45m
        XCTAssertEqual(activity.formattedDuration, "45m")
    }

    func testFormattedDurationExactHour() {
        let activity = TestFixtures.makeActivity(elapsedTime: 7200) // 2h 0m
        XCTAssertEqual(activity.formattedDuration, "2h 0m")
    }

    func testFormattedDurationZero() {
        let activity = TestFixtures.makeActivity(elapsedTime: 0)
        XCTAssertEqual(activity.formattedDuration, "0m")
    }

    func testHasPowerDataWhenWattsPresent() {
        let activity = TestFixtures.makeActivity(averageWatts: 200)
        XCTAssertTrue(activity.hasPowerData)
    }

    func testHasPowerDataWhenWattsNil() {
        let activity = TestFixtures.makeActivity(averageWatts: nil)
        XCTAssertFalse(activity.hasPowerData)
    }

    func testHasCadenceDataWhenCadencePresent() {
        let activity = TestFixtures.makeActivity(averageCadence: 85)
        XCTAssertTrue(activity.hasCadenceData)
    }

    func testHasCadenceDataWhenCadenceNil() {
        let activity = TestFixtures.makeActivity(averageCadence: nil)
        XCTAssertFalse(activity.hasCadenceData)
    }

    // MARK: - JSON Decoding

    func testDecodesFromJSON() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = TestFixtures.activityJSON.data(using: .utf8)!
        let activity = try decoder.decode(StravaActivity.self, from: data)

        XCTAssertEqual(activity.id, 12345)
        XCTAssertEqual(activity.name, "Morning Zwift Ride")
        XCTAssertEqual(activity.type, "VirtualRide")
        XCTAssertEqual(activity.sportType, "VirtualRide")
        XCTAssertEqual(activity.elapsedTime, 3600)
        XCTAssertEqual(activity.movingTime, 3500)
        XCTAssertEqual(activity.distance, 30000.0)
        XCTAssertFalse(activity.hasHeartrate)
        XCTAssertEqual(activity.averageWatts, 200.0)
        XCTAssertEqual(activity.trainer, true)
    }

    func testDecodesWithOptionalFieldsMissing() throws {
        let json = """
        {
            "id": 1,
            "name": "Ride",
            "type": "Ride",
            "start_date": "2023-11-14T22:13:20Z",
            "elapsed_time": 60,
            "moving_time": 50,
            "distance": 100.0,
            "has_heartrate": true,
            "average_heartrate": 140.0,
            "max_heartrate": 180.0
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activity = try decoder.decode(StravaActivity.self, from: json.data(using: .utf8)!)

        XCTAssertNil(activity.sportType)
        XCTAssertNil(activity.averageWatts)
        XCTAssertNil(activity.kilojoules)
        XCTAssertNil(activity.averageCadence)
        XCTAssertNil(activity.gearId)
        XCTAssertNil(activity.description)
        XCTAssertNil(activity.commute)
        XCTAssertNil(activity.trainer)
        XCTAssertNil(activity.externalId)
        XCTAssertTrue(activity.hasHeartrate)
        XCTAssertEqual(activity.averageHeartrate, 140.0)
    }

    // MARK: - Identifiable

    func testIdentifiableById() {
        let a = TestFixtures.makeActivity(id: 1)
        let b = TestFixtures.makeActivity(id: 2)
        XCTAssertNotEqual(a.id, b.id)
    }
}
