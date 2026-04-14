import XCTest
@testable import ZwiftSync

final class PKCEHelperTests: XCTestCase {

    // MARK: - Code Verifier

    func testCodeVerifierLength() {
        let verifier = PKCEHelper.generateCodeVerifier()
        // Base64 of 32 bytes ≈ 43 chars (no padding)
        XCTAssertGreaterThanOrEqual(verifier.count, 40)
        XCTAssertLessThanOrEqual(verifier.count, 128)
    }

    func testCodeVerifierIsURLSafe() {
        let verifier = PKCEHelper.generateCodeVerifier()
        XCTAssertFalse(verifier.contains("+"))
        XCTAssertFalse(verifier.contains("/"))
        XCTAssertFalse(verifier.contains("="))
    }

    func testCodeVerifierIsUnique() {
        let verifiers = (0..<10).map { _ in PKCEHelper.generateCodeVerifier() }
        let unique = Set(verifiers)
        XCTAssertEqual(unique.count, 10, "Each verifier should be unique")
    }

    func testCodeVerifierContainsOnlyBase64URLChars() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let verifierChars = CharacterSet(charactersIn: verifier)
        XCTAssertTrue(allowed.isSuperset(of: verifierChars))
    }

    // MARK: - Code Challenge

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

    func testCodeChallengeIsBase64URLEncoded() {
        let challenge = PKCEHelper.generateCodeChallenge(from: "known-input")
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let challengeChars = CharacterSet(charactersIn: challenge)
        XCTAssertTrue(allowed.isSuperset(of: challengeChars))
    }

    func testCodeChallengeLength() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)
        // SHA-256 produces 32 bytes → base64url ≈ 43 chars
        XCTAssertEqual(challenge.count, 43)
    }
}
