import XCTest
@testable import ZwiftSync

final class TCXGeneratorTests: XCTestCase {

    // MARK: - Basic Generation

    func testGeneratesSingleLapTCX() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 5)
        let hrSamples = makeHRSamples(startDate: activity.startDate, count: 5)

        let data = TCXGenerator.generate(
            activity: activity,
            streams: streams,
            hrSamples: hrSamples
        )

        let xml = String(data: data, encoding: .utf8)!

        // Verify XML structure
        XCTAssertTrue(xml.contains("<TrainingCenterDatabase"))
        XCTAssertTrue(xml.contains("<Activity Sport=\"Biking\">"))
        XCTAssertTrue(xml.contains("<Lap StartTime="))
        XCTAssertTrue(xml.contains("<Track>"))
        XCTAssertTrue(xml.contains("<Trackpoint>"))
        XCTAssertTrue(xml.contains("</TrainingCenterDatabase>"))
    }

    func testIncludesAllDataFields() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 3)
        let hrSamples = makeHRSamples(startDate: activity.startDate, count: 3)

        let data = TCXGenerator.generate(
            activity: activity,
            streams: streams,
            hrSamples: hrSamples
        )
        let xml = String(data: data, encoding: .utf8)!

        // Check all field types present
        XCTAssertTrue(xml.contains("<Time>"))
        XCTAssertTrue(xml.contains("<LatitudeDegrees>"))
        XCTAssertTrue(xml.contains("<LongitudeDegrees>"))
        XCTAssertTrue(xml.contains("<AltitudeMeters>"))
        XCTAssertTrue(xml.contains("<DistanceMeters>"))
        XCTAssertTrue(xml.contains("<HeartRateBpm>"))
        XCTAssertTrue(xml.contains("<Cadence>"))
        XCTAssertTrue(xml.contains("<ns3:Watts>"))
    }

    func testTrackpointCount() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 10)
        let hrSamples = makeHRSamples(startDate: activity.startDate, count: 10)

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples)
        let xml = String(data: data, encoding: .utf8)!

        let trackpointCount = xml.components(separatedBy: "<Trackpoint>").count - 1
        XCTAssertEqual(trackpointCount, 10)
    }

    // MARK: - Multi-Lap

    func testMultiLapGeneration() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 20)
        let hrSamples = makeHRSamples(startDate: activity.startDate, count: 20)
        let laps = [
            makeStavaLap(startIndex: 0, endIndex: 9, startDate: activity.startDate, elapsed: 10),
            makeStavaLap(startIndex: 10, endIndex: 19, startDate: activity.startDate.addingTimeInterval(10), elapsed: 10),
        ]

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples, laps: laps)
        let xml = String(data: data, encoding: .utf8)!

        let lapCount = xml.components(separatedBy: "<Lap StartTime=").count - 1
        XCTAssertEqual(lapCount, 2)

        let trackCount = xml.components(separatedBy: "<Track>").count - 1
        XCTAssertEqual(trackCount, 2)
    }

    // MARK: - HR Matching

    func testHRSamplesInjected() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 5)
        let hrSamples = makeHRSamples(startDate: activity.startDate, count: 5, baseBPM: 145)

        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples)
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertTrue(xml.contains("<Value>145</Value>"))
    }

    func testMissingHRSamplesDoNotGenerateTag() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 5)
        // No HR samples
        let data = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: [])
        let xml = String(data: data, encoding: .utf8)!

        XCTAssertFalse(xml.contains("<HeartRateBpm>"))
    }

    func testTimeShiftAdjustsHRMatching() throws {
        let activity = makeActivity()
        let streams = makeStreams(count: 3)

        // HR samples offset by 10 seconds into the future
        let hrSamples = makeHRSamples(startDate: activity.startDate.addingTimeInterval(10), count: 3, baseBPM: 160)

        // Without time shift — samples won't match (outside 2s tolerance)
        let dataNoShift = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples)
        let xmlNoShift = String(data: dataNoShift, encoding: .utf8)!
        XCTAssertFalse(xmlNoShift.contains("<HeartRateBpm>"))

        // With -10s time shift — should match
        let dataShifted = TCXGenerator.generate(activity: activity, streams: streams, hrSamples: hrSamples, timeShiftSeconds: -10)
        let xmlShifted = String(data: dataShifted, encoding: .utf8)!
        XCTAssertTrue(xmlShifted.contains("<Value>160</Value>"))
    }

    // MARK: - Helpers

    private func makeActivity(
        startDate: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> StravaActivity {
        StravaActivity(
            id: 12345,
            name: "Test Zwift Ride",
            type: "VirtualRide",
            sportType: "VirtualRide",
            startDate: startDate,
            elapsedTime: 3600,
            movingTime: 3500,
            distance: 30000,
            hasHeartrate: false,
            averageHeartrate: nil,
            maxHeartrate: nil,
            averageWatts: 200,
            kilojoules: 720,
            averageCadence: 85,
            gearId: nil,
            description: nil,
            commute: false,
            trainer: true,
            externalId: nil
        )
    }

    private func makeStreams(count: Int) -> StravaStreams {
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

    private func makeHRSamples(startDate: Date, count: Int, baseBPM: Double = 140) -> [HRSample] {
        (0..<count).map { i in
            HRSample(
                timestamp: startDate.addingTimeInterval(TimeInterval(i)),
                bpm: baseBPM + Double(i)
            )
        }
    }

    private func makeStavaLap(
        startIndex: Int,
        endIndex: Int,
        startDate: Date,
        elapsed: Int
    ) -> StravaLap {
        StravaLap(
            id: startIndex,
            name: "Lap \(startIndex)",
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
}

// MARK: - HRLookup Tests

final class HRLookupTests: XCTestCase {
    func testFindsExactMatch() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = [
            HRSample(timestamp: base, bpm: 100),
            HRSample(timestamp: base.addingTimeInterval(1), bpm: 110),
            HRSample(timestamp: base.addingTimeInterval(2), bpm: 120),
        ]
        let lookup = HRLookup(samples: samples)

        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(1), tolerance: 2), 110)
    }

    func testFindsNearestWithinTolerance() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = [
            HRSample(timestamp: base, bpm: 100),
            HRSample(timestamp: base.addingTimeInterval(5), bpm: 150),
        ]
        let lookup = HRLookup(samples: samples)

        // 1.5s from first sample — within 2s tolerance
        XCTAssertEqual(lookup.nearestBPM(at: base.addingTimeInterval(1.5), tolerance: 2), 100)
    }

    func testReturnsNilOutsideTolerance() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = [
            HRSample(timestamp: base, bpm: 100),
        ]
        let lookup = HRLookup(samples: samples)

        XCTAssertNil(lookup.nearestBPM(at: base.addingTimeInterval(5), tolerance: 2))
    }

    func testEmptySamplesReturnsNil() {
        let lookup = HRLookup(samples: [])
        XCTAssertNil(lookup.nearestBPM(at: Date(), tolerance: 2))
    }

    func testTimeShiftAdjustsSamples() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = [
            HRSample(timestamp: base.addingTimeInterval(10), bpm: 130),
        ]
        let lookup = HRLookup(samples: samples, timeShiftSeconds: -10)

        // After -10s shift, the sample is at base+0, should match base
        XCTAssertEqual(lookup.nearestBPM(at: base, tolerance: 2), 130)
    }
}
