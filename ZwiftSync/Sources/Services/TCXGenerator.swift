import Foundation

/// Generates TCX XML files from merged Strava streams + HealthKit heart rate data.
struct TCXGenerator {

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

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
                                xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
          <Activities>
            <Activity Sport="Biking">
              <Id>\(iso.string(from: startDate))</Id>

        """

        // Determine lap boundaries
        let lapRanges = buildLapRanges(laps: laps, streamCount: streams.count)

        for (lapIndex, range) in lapRanges.enumerated() {
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

            xml += """
                  <Lap StartTime="\(iso.string(from: lapStart))">
                    <TotalTimeSeconds>\(lapDuration)</TotalTimeSeconds>
                    <DistanceMeters>\(lapDistance)</DistanceMeters>
                    <TriggerMethod>Manual</TriggerMethod>
                    <Track>

            """

            for i in range {
                guard i < streams.count else { break }
                xml += buildTrackpoint(
                    index: i,
                    startDate: startDate,
                    streams: streams,
                    hrLookup: hrLookup,
                    iso: iso
                )
            }

            xml += """
                    </Track>
                  </Lap>

            """
        }

        xml += """
            </Activity>
          </Activities>
        </TrainingCenterDatabase>
        """

        return xml.data(using: .utf8) ?? Data()
    }

    // MARK: - Private Helpers

    private static func buildTrackpoint(
        index i: Int,
        startDate: Date,
        streams: StravaStreams,
        hrLookup: HRLookup,
        iso: ISO8601DateFormatter
    ) -> String {
        let pointTime = startDate.addingTimeInterval(TimeInterval(streams.time[i]))
        let timeStr = iso.string(from: pointTime)

        var tp = "          <Trackpoint>\n"
        tp += "            <Time>\(timeStr)</Time>\n"

        if let latlng = streams.latlng, i < latlng.count, latlng[i].count == 2 {
            tp += """
                        <Position>
                          <LatitudeDegrees>\(latlng[i][0])</LatitudeDegrees>
                          <LongitudeDegrees>\(latlng[i][1])</LongitudeDegrees>
                        </Position>

            """
        }

        if let altitude = streams.altitude, i < altitude.count {
            tp += "            <AltitudeMeters>\(altitude[i])</AltitudeMeters>\n"
        }

        if let distance = streams.distance, i < distance.count {
            tp += "            <DistanceMeters>\(distance[i])</DistanceMeters>\n"
        }

        if let bpm = hrLookup.nearestBPM(at: pointTime, tolerance: Config.hrAlignmentToleranceSeconds) {
            tp += "            <HeartRateBpm><Value>\(Int(bpm.rounded()))</Value></HeartRateBpm>\n"
        }

        if let cadence = streams.cadence, i < cadence.count {
            tp += "            <Cadence>\(cadence[i])</Cadence>\n"
        }

        if let watts = streams.watts, i < watts.count {
            tp += """
                        <Extensions>
                          <ns3:TPX>
                            <ns3:Watts>\(watts[i])</ns3:Watts>
                          </ns3:TPX>
                        </Extensions>

            """
        }

        tp += "          </Trackpoint>\n"
        return tp
    }

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

        if ranges.isEmpty {
            return [0..<streamCount]
        }
        return ranges
    }

    private static func distanceForRange(_ range: Range<Int>, streams: StravaStreams) -> Double {
        guard let distance = streams.distance else { return 0 }
        let startDist = range.lowerBound < distance.count ? distance[range.lowerBound] : 0
        let endIdx = min(range.upperBound - 1, distance.count - 1)
        let endDist = endIdx >= 0 ? distance[endIdx] : 0
        return endDist - startDist
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
