import XCTest
@testable import ZwiftSync

final class StravaAuthTests: XCTestCase {

    // MARK: - StravaTokenResponse

    func testTokenResponseDecoding() throws {
        let data = TestFixtures.tokenResponseJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: data)

        XCTAssertEqual(response.accessToken, "abc123")
        XCTAssertEqual(response.refreshToken, "def456")
        XCTAssertEqual(response.expiresAt, 1_700_003_600)
        XCTAssertEqual(response.athlete?.id, 42)
        XCTAssertEqual(response.athlete?.firstname, "Test")
        XCTAssertEqual(response.athlete?.lastname, "User")
    }

    func testExpirationDate() {
        let response = StravaTokenResponse(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: 1_700_003_600,
            athlete: nil
        )
        let expected = Date(timeIntervalSince1970: 1_700_003_600)
        XCTAssertEqual(response.expirationDate, expected)
    }

    func testIsExpiredWhenPastExpiration() {
        let pastTimestamp = Int(Date().timeIntervalSince1970) - 3600
        let response = StravaTokenResponse(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: pastTimestamp,
            athlete: nil
        )
        XCTAssertTrue(response.isExpired)
    }

    func testIsNotExpiredWhenBeforeExpiration() {
        let futureTimestamp = Int(Date().timeIntervalSince1970) + 3600
        let response = StravaTokenResponse(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: futureTimestamp,
            athlete: nil
        )
        XCTAssertFalse(response.isExpired)
    }

    func testTokenResponseWithoutAthlete() throws {
        let json = """
        {
            "access_token": "abc",
            "refresh_token": "def",
            "expires_at": 1700000000
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        XCTAssertNil(response.athlete)
    }

    // MARK: - StravaUploadResponse

    func testUploadResponseDecoding() throws {
        let data = TestFixtures.uploadResponseJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(StravaUploadResponse.self, from: data)

        XCTAssertEqual(response.id, 9876)
        XCTAssertEqual(response.status, "Your activity is ready.")
        XCTAssertEqual(response.activityId, 54321)
        XCTAssertNil(response.error)
    }

    func testUploadResponseWithError() throws {
        let json = """
        {
            "id": 1,
            "status": "error",
            "error": "duplicate activity"
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StravaUploadResponse.self, from: data)

        XCTAssertNil(response.activityId)
        XCTAssertEqual(response.error, "duplicate activity")
    }

    // MARK: - StravaActivityUpdate

    func testActivityUpdateEncoding() throws {
        let update = StravaActivityUpdate(
            name: "Updated Ride",
            description: "A great ride",
            type: "VirtualRide",
            sportType: "VirtualRide",
            gearId: "g123",
            commute: false,
            trainer: true
        )

        let data = try JSONEncoder().encode(update)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["name"] as? String, "Updated Ride")
        XCTAssertEqual(dict["description"] as? String, "A great ride")
        XCTAssertEqual(dict["sport_type"] as? String, "VirtualRide")
        XCTAssertEqual(dict["gear_id"] as? String, "g123")
        XCTAssertEqual(dict["trainer"] as? Bool, true)
    }

    func testActivityUpdateWithNilFields() throws {
        let update = StravaActivityUpdate(
            name: nil,
            description: nil,
            type: nil,
            sportType: nil,
            gearId: nil,
            commute: nil,
            trainer: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(update)
        let json = String(data: data, encoding: .utf8)!

        // Nil fields should not appear in encoded JSON
        // (default Codable behavior skips nils)
        XCTAssertFalse(json.contains("\"name\""))
    }

    // MARK: - MatchConfidence

    func testMatchConfidenceComparable() {
        XCTAssertTrue(MatchConfidence.noMatch < .low)
        XCTAssertTrue(MatchConfidence.low < .medium)
        XCTAssertTrue(MatchConfidence.medium < .high)
    }

    func testMatchConfidenceLabels() {
        XCTAssertEqual(MatchConfidence.high.label, "Match ✓")
        XCTAssertEqual(MatchConfidence.medium.label, "Partial")
        XCTAssertEqual(MatchConfidence.low.label, "Weak")
        XCTAssertEqual(MatchConfidence.noMatch.label, "No Match")
    }

    func testMatchConfidenceRank() {
        XCTAssertEqual(MatchConfidence.noMatch.rank, 0)
        XCTAssertEqual(MatchConfidence.low.rank, 1)
        XCTAssertEqual(MatchConfidence.medium.rank, 2)
        XCTAssertEqual(MatchConfidence.high.rank, 3)
    }
}
