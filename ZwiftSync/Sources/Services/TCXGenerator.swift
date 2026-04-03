import Foundation

/// Generates TCX XML files from merged Strava streams + HealthKit heart rate data.
struct TCXGenerator {

    /// Build a TCX document combining Strava streams with HealthKit HR samples.
    /// - Parameters:
    ///   - activity: The original Strava activity (for metadata)
    ///   - streams: Stream data pulled from Strava
    ///   - hrSamples: Heart rate samples from HealthKit
    ///   - timeShiftSeconds: Manual offset to apply to HR timestamps (default: 0)
    /// - Returns: TCX XML data ready for upload
    static func generate(
        activity: StravaActivity,
        streams: StravaStreams,
        hrSamples: [HRSample],
        timeShiftSeconds: Double = 0
    ) -> Data {
        let startDate = activity.startDate
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
                                xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
          <Activities>
            <Activity Sport="Biking">
              <Id>\(iso.string(from: startDate))</Id>
              <Lap StartTime="\(iso.string(from: startDate))">
                <TotalTimeSeconds>\(activity.elapsedTime)</TotalTimeSeconds>
        """

        if activity.distance > 0 {
            xml += "        <DistanceMeters>\(activity.distance)</DistanceMeters>\n"
        }

        xml += """
                <TriggerMethod>Manual</TriggerMethod>
                <Track>

        """

        // Build HR lookup for fast nearest-neighbor matching
        let hrLookup = HRLookup(samples: hrSamples, timeShiftSeconds: timeShiftSeconds)

        for i in 0..<streams.count {
            let pointTime = startDate.addingTimeInterval(TimeInterval(streams.time[i]))
            let timeStr = iso.string(from: pointTime)

            xml += "          <Trackpoint>\n"
            xml += "            <Time>\(timeStr)</Time>\n"

            // Position
            if let latlng = streams.latlng, i < latlng.count, latlng[i].count == 2 {
                xml += """
                            <Position>
                              <LatitudeDegrees>\(latlng[i][0])</LatitudeDegrees>
                              <LongitudeDegrees>\(latlng[i][1])</LongitudeDegrees>
                            </Position>

                """
            }

            // Altitude
            if let altitude = streams.altitude, i < altitude.count {
                xml += "            <AltitudeMeters>\(altitude[i])</AltitudeMeters>\n"
            }

            // Distance
            if let distance = streams.distance, i < distance.count {
                xml += "            <DistanceMeters>\(distance[i])</DistanceMeters>\n"
            }

            // Heart Rate (from HealthKit)
            if let bpm = hrLookup.nearestBPM(at: pointTime, tolerance: Config.hrAlignmentToleranceSeconds) {
                xml += "            <HeartRateBpm><Value>\(Int(bpm.rounded()))</Value></HeartRateBpm>\n"
            }

            // Cadence
            if let cadence = streams.cadence, i < cadence.count {
                xml += "            <Cadence>\(cadence[i])</Cadence>\n"
            }

            // Power (watts) as extension
            if let watts = streams.watts, i < watts.count {
                xml += """
                            <Extensions>
                              <ns3:TPX>
                                <ns3:Watts>\(watts[i])</ns3:Watts>
                              </ns3:TPX>
                            </Extensions>

                """
            }

            xml += "          </Trackpoint>\n"
        }

        xml += """
                </Track>
              </Lap>
            </Activity>
          </Activities>
        </TrainingCenterDatabase>
        """

        return xml.data(using: .utf8) ?? Data()
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

    /// Find the nearest HR value within the given tolerance.
    func nearestBPM(at date: Date, tolerance: TimeInterval) -> Double? {
        guard !samples.isEmpty else { return nil }

        let target = date.timeIntervalSinceReferenceDate

        // Binary search for closest timestamp
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

        // Check lo and lo-1 for nearest
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
