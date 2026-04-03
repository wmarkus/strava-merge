import XCTest
@testable import ZwiftSync

final class PKCEHelperTests: XCTestCase {

    func testCodeVerifierLength() {
        let verifier = PKCEHelper.generateCodeVerifier()
        // Base64 of 32 bytes ≈ 43 chars (no padding)
        XCTAssertGreaterThanOrEqual(verifier.count, 40)
    }

    func testCodeVerifierIsURLSafe() {
        let verifier = PKCEHelper.generateCodeVerifier()
        XCTAssertFalse(verifier.contains("+"))
        XCTAssertFalse(verifier.contains("/"))
        XCTAssertFalse(verifier.contains("="))
    }

    func testCodeChallengeIsDeterministic() {
        let verifier = "test-verifier-12345"
        let challenge1 = PKCEHelper.generateCodeChallenge(from: verifier)
        let challenge2 = PKCEHelper.generateCodeChallenge(from: verifier)
        XCTAssertEqual(challenge1, challenge2)
    }

    func testCodeChallengeIsURLSafe() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)
        XCTAssertFalse(challenge.contains("+"))
        XCTAssertFalse(challenge.contains("/"))
        XCTAssertFalse(challenge.contains("="))
    }

    func testDifferentVerifiersProduceDifferentChallenges() {
        let verifier1 = "verifier-aaa"
        let verifier2 = "verifier-bbb"
        let challenge1 = PKCEHelper.generateCodeChallenge(from: verifier1)
        let challenge2 = PKCEHelper.generateCodeChallenge(from: verifier2)
        XCTAssertNotEqual(challenge1, challenge2)
    }
}
