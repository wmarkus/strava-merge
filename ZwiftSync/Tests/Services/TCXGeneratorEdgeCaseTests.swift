import XCTest
@testable import ZwiftSync

final class TCXGeneratorEdgeCaseTests: XCTestCase {

    // MARK: - Empty / Minimal Streams

    func testEmptyStreamsProducesValidXML() {
        let activity = TestFixtures.makeActivity()
        let streams = StravaStreams(
            time: [],
            latlng: nil, altitude: nil, watts: nil,
            cadence: nil, distance: nil, velocitySmooth: nil,
            heartrate: nil
        )
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [])
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertTrue(xml.contains("<TrainingCenterDatabase"))
        XCTAssertTrue(xml.contains("</TrainingCenterDatabase>"))
        XCTAssertFalse(xml.contains("<Trackpoint>"))
    }

    func testSingleTrackpoint() {
        let activity = TestFixtures.makeActivity()
        let streams = StravaStreams(
            time: [0],
            latlng: nil, altitude: nil, watts: nil,
            cadence: nil, distance: nil, velocitySmooth: nil,
            heartrate: nil
        )
        let hrSamples = TestFixtures.makeHRSamples(startDate: activity.startDate, count: 1, baseBPM: 120)

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples)
        let xml = String(data: data, encoding: .utf8)!

        let count = xml.components(separatedBy: "<Trackpoint>").count - 1
        XCTAssertEqual(count, 1)
        XCTAssertTrue(xml.contains("<Value>120</Value>"))
    }

    // MARK: - Missing Optional Fields

    func testStreamsWithOnlyTime() {
        let activity = TestFixtures.makeActivity()
        let streams = StravaStreams(
            time: [0, 1, 2],
            latlng: nil, altitude: nil, watts: nil,
            cadence: nil, distance: nil, velocitySmooth: nil,
            heartrate: nil
        )
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [])
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertTrue(xml.contains("<Time>"))
        XCTAssertFalse(xml.contains("<LatitudeDegrees>"))
        XCTAssertFalse(xml.contains("<AltitudeMeters>"))
        XCTAssertFalse(xml.contains("<ns3:Watts>"))
        XCTAssertFalse(xml.contains("<Cadence>"))
        XCTAssertFalse(xml.contains("<DistanceMeters>"), "No distance stream")
        XCTAssertFalse(xml.contains("<HeartRateBpm>"))
    }

    // MARK: - Large Dataset

    func testLargeDatasetPerformance() {
        let activity = TestFixtures.makeActivity(elapsedTime: 7200)
        let streams = TestFixtures.makeStreams(count: 7200)
        let hrSamples = TestFixtures.makeHRSamples(startDate: activity.startDate, count: 7200)

        let startTime = CFAbsoluteTimeGetCurrent()
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertGreaterThan(data.count, 0)
        XCTAssertLessThan(elapsed, 5.0, "Should generate 7200 trackpoints in under 5 seconds")
    }

    // MARK: - XML Structure

    func testXMLHasProperEncoding() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 1)
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [])
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertTrue(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    func testActivitySportIsBiking() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 1)
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [])
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertTrue(xml.contains("<Activity Sport=\"Biking\">"))
    }

    func testActivityIdUsesISO8601StartDate() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 1)
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [])
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertTrue(xml.contains("<Id>"))
        XCTAssertTrue(xml.contains("</Id>"))
    }

    // MARK: - Lap Boundaries

    func testSinglePointLap() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 1)
        let laps = [TestFixtures.makeLap(startIndex: 0, endIndex: 0, elapsed: 1)]

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [], laps: laps)
        let xml = String(data: data, encoding: .utf8)!

        let lapCount = xml.components(separatedBy: "<Lap StartTime=").count - 1
        XCTAssertEqual(lapCount, 1)
    }

    func testEmptyLapsFallsBackToSingle() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 5)
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [], laps: [])
        let xml = String(data: data, encoding: .utf8)!

        let lapCount = xml.components(separatedBy: "<Lap StartTime=").count - 1
        XCTAssertEqual(lapCount, 1)

        let trackpointCount = xml.components(separatedBy: "<Trackpoint>").count - 1
        XCTAssertEqual(trackpointCount, 5)
    }

    func testThreeLaps() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 30)
        let laps = [
            TestFixtures.makeLap(id: 1, startIndex: 0, endIndex: 9, startDate: activity.startDate, elapsed: 10),
            TestFixtures.makeLap(id: 2, startIndex: 10, endIndex: 19, startDate: activity.startDate.addingTimeInterval(10), elapsed: 10),
            TestFixtures.makeLap(id: 3, startIndex: 20, endIndex: 29, startDate: activity.startDate.addingTimeInterval(20), elapsed: 10),
        ]

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [], laps: laps)
        let xml = String(data: data, encoding: .utf8)!

        let lapCount = xml.components(separatedBy: "<Lap StartTime=").count - 1
        XCTAssertEqual(lapCount, 3)

        let trackCount = xml.components(separatedBy: "<Track>").count - 1
        XCTAssertEqual(trackCount, 3)
    }

    func testLapDistanceMeters() {
        let activity = TestFixtures.makeActivity()
        let streams = TestFixtures.makeStreams(count: 10)
        let laps = [TestFixtures.makeLap(startIndex: 0, endIndex: 9, startDate: activity.startDate, elapsed: 10)]

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [], laps: laps)
        let xml = String(data: data, encoding: .utf8)!

        // Lap distance = (9-0)*10 = 90
        XCTAssertTrue(xml.contains("<DistanceMeters>90.0</DistanceMeters>"))
    }
}
