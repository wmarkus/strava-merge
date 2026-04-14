import Foundation

/// Generates TCX XML files from merged Strava streams + HealthKit heart rate data.
enum TCXGenerator {

    /// Build a TCX document combining Strava streams with HealthKit HR samples.
    /// Supports multi-lap activities when laps are provided.
    static func generate(
        activity: StravaActivity,
        streams: StravaStreams,
        hrSamples: [HRSample],
        laps: [StravaLap]? = nil,
        timeShiftSeconds: Double = 0
    ) -> Data {
        let startDate = activity.startDate
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let hrLookup = HRLookup(samples: hrSamples, timeShiftSeconds: timeShiftSeconds)

        var xml = XMLBuilder()
        xml.line("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        xml.line("<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\"")
        xml.line("                        xmlns:ns3=\"http://www.garmin.com/xmlschemas/ActivityExtension/v2\">")
        xml.line("  <Activities>")
        xml.line("    <Activity Sport=\"Biking\">")
        xml.line("      <Id>\(iso.string(from: startDate))</Id>")

        let lapRanges = buildLapRanges(laps: laps, streamCount: streams.count)

        for (lapIndex, range) in lapRanges.enumerated() {
            writeLap(
                to: &xml,
                lapIndex: lapIndex,
                range: range,
                laps: laps,
                startDate: startDate,
                streams: streams,
                hrLookup: hrLookup,
                iso: iso
            )
        }

        xml.line("    </Activity>")
        xml.line("  </Activities>")
        xml.line("</TrainingCenterDatabase>")

        return xml.data
    }

    // MARK: - Lap Writing

    private static func writeLap(
        to xml: inout XMLBuilder,
        lapIndex: Int,
        range: Range<Int>,
        laps: [StravaLap]?,
        startDate: Date,
        streams: StravaStreams,
        hrLookup: HRLookup,
        iso: ISO8601DateFormatter
    ) {
        let lapStart: Date
        let lapDuration: Int
        let lapDistance: Double

        if let laps, lapIndex < laps.count {
            lapStart = laps[lapIndex].startDate
            lapDuration = laps[lapIndex].elapsedTime
            lapDistance = laps[lapIndex].distance
        } else {
            lapStart = startDate.addingTimeInterval(TimeInterval(streams.time[range.lowerBound]))
            let endIdx = min(range.upperBound - 1, streams.count - 1)
            lapDuration = streams.time[endIdx] - streams.time[range.lowerBound]
            lapDistance = distanceForRange(range, streams: streams)
        }

        xml.line("      <Lap StartTime=\"\(iso.string(from: lapStart))\">")
        xml.line("        <TotalTimeSeconds>\(lapDuration)</TotalTimeSeconds>")
        xml.line("        <DistanceMeters>\(lapDistance)</DistanceMeters>")
        xml.line("        <TriggerMethod>Manual</TriggerMethod>")
        xml.line("        <Track>")

        for i in range where i < streams.count {
            writeTrackpoint(to: &xml, index: i, startDate: startDate, streams: streams, hrLookup: hrLookup, iso: iso)
        }

        xml.line("        </Track>")
        xml.line("      </Lap>")
    }

    // MARK: - Trackpoint Writing

    private static func writeTrackpoint(
        to xml: inout XMLBuilder,
        index i: Int,
        startDate: Date,
        streams: StravaStreams,
        hrLookup: HRLookup,
        iso: ISO8601DateFormatter
    ) {
        let pointTime = startDate.addingTimeInterval(TimeInterval(streams.time[i]))

        xml.line("          <Trackpoint>")
        xml.line("            <Time>\(iso.string(from: pointTime))</Time>")

        if let latlng = streams.latlng, i < latlng.count, latlng[i].count == 2 {
            xml.line("            <Position>")
            xml.line("              <LatitudeDegrees>\(latlng[i][0])</LatitudeDegrees>")
            xml.line("              <LongitudeDegrees>\(latlng[i][1])</LongitudeDegrees>")
            xml.line("            </Position>")
        }

        if let altitude = streams.altitude, i < altitude.count {
            xml.line("            <AltitudeMeters>\(altitude[i])</AltitudeMeters>")
        }

        if let distance = streams.distance, i < distance.count {
            xml.line("            <DistanceMeters>\(distance[i])</DistanceMeters>")
        }

        if let bpm = hrLookup.nearestBPM(at: pointTime, tolerance: Config.hrAlignmentToleranceSeconds) {
            xml.line("            <HeartRateBpm><Value>\(Int(bpm.rounded()))</Value></HeartRateBpm>")
        }

        if let cadence = streams.cadence, i < cadence.count {
            xml.line("            <Cadence>\(cadence[i])</Cadence>")
        }

        if let watts = streams.watts, i < watts.count {
            xml.line("            <Extensions>")
            xml.line("              <ns3:TPX>")
            xml.line("                <ns3:Watts>\(watts[i])</ns3:Watts>")
            xml.line("              </ns3:TPX>")
            xml.line("            </Extensions>")
        }

        xml.line("          </Trackpoint>")
    }

    // MARK: - Helpers

    /// Build index ranges for each lap. Falls back to a single lap spanning all points.
    private static func buildLapRanges(laps: [StravaLap]?, streamCount: Int) -> [Range<Int>] {
        guard let laps, !laps.isEmpty else {
            return [0..<streamCount]
        }

        var ranges: [Range<Int>] = []
        for lap in laps {
            let start = max(0, lap.startIndex)
            let end = min(streamCount, lap.endIndex + 1)
            if start < end {
                ranges.append(start..<end)
            }
        }

        return ranges.isEmpty ? [0..<streamCount] : ranges
    }

    private static func distanceForRange(_ range: Range<Int>, streams: StravaStreams) -> Double {
        guard let distance = streams.distance else { return 0 }
        let startDist = range.lowerBound < distance.count ? distance[range.lowerBound] : 0
        let endIdx = min(range.upperBound - 1, distance.count - 1)
        let endDist = endIdx >= 0 ? distance[endIdx] : 0
        return endDist - startDist
    }
}

// MARK: - XML Builder

/// Simple string builder for XML output, avoiding fragile string concatenation.
struct XMLBuilder {
    private var lines: [String] = []

    mutating func line(_ content: String) {
        lines.append(content)
    }

    var data: Data {
        let joined = lines.joined(separator: "\n")
        return joined.data(using: .utf8) ?? Data()
    }
}

// MARK: - HR Lookup (nearest-neighbor by timestamp)

/// Efficiently finds the nearest HR sample for a given timestamp using binary search.
struct HRLookup {
    private let samples: [HRSample]

    init(samples: [HRSample], timeShiftSeconds: Double = 0) {
        if timeShiftSeconds == 0 {
            self.samples = samples
        } else {
            self.samples = samples.map {
                HRSample(timestamp: $0.timestamp.addingTimeInterval(timeShiftSeconds), bpm: $0.bpm)
            }
        }
    }

    func nearestBPM(at date: Date, tolerance: TimeInterval) -> Double? {
        guard !samples.isEmpty else { return nil }

        let target = date.timeIntervalSinceReferenceDate

        var lo = 0
        var hi = samples.count - 1

        while lo < hi {
            let mid = (lo + hi) / 2
            if samples[mid].timestamp.timeIntervalSinceReferenceDate < target {
                lo = mid + 1
            } else {
                hi = mid
            }
        }

        var bestIndex = lo
        if lo > 0 {
            let diffLo = abs(samples[lo].timestamp.timeIntervalSinceReferenceDate - target)
            let diffPrev = abs(samples[lo - 1].timestamp.timeIntervalSinceReferenceDate - target)
            if diffPrev < diffLo {
                bestIndex = lo - 1
            }
        }

        let diff = abs(samples[bestIndex].timestamp.timeIntervalSinceReferenceDate - target)
        guard diff <= tolerance else { return nil }

        return samples[bestIndex].bpm
    }
}
