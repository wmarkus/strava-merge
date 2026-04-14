import XCTest
@testable import ZwiftSync

final class MultipartEncoderTests: XCTestCase {

    func testContentTypeIncludesBoundary() {
        let encoder = MultipartEncoder(boundary: "test-boundary")
        XCTAssertEqual(encoder.contentType, "multipart/form-data; boundary=test-boundary")
    }

    func testAddFieldProducesCorrectFormat() {
        var encoder = MultipartEncoder(boundary: "BOUNDARY")
        encoder.addField(name: "key", value: "value")
        let data = encoder.finalize()
        let body = String(data: data, encoding: .utf8)!

        XCTAssertTrue(body.contains("--BOUNDARY\r\n"))
        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"key\"\r\n\r\n"))
        XCTAssertTrue(body.contains("value\r\n"))
        XCTAssertTrue(body.hasSuffix("--BOUNDARY--\r\n"))
    }

    func testAddFileProducesCorrectFormat() {
        var encoder = MultipartEncoder(boundary: "BOUNDARY")
        let fileData = "file-content".data(using: .utf8)!
        encoder.addFile(name: "file", filename: "test.txt", mimeType: "text/plain", data: fileData)
        let data = encoder.finalize()
        let body = String(data: data, encoding: .utf8)!

        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"file\"; filename=\"test.txt\""))
        XCTAssertTrue(body.contains("Content-Type: text/plain\r\n\r\n"))
        XCTAssertTrue(body.contains("file-content"))
    }

    func testMultipleFieldsAndFile() {
        var encoder = MultipartEncoder(boundary: "B")
        encoder.addField(name: "type", value: "tcx")
        encoder.addField(name: "name", value: "My Ride")
        encoder.addFile(name: "file", filename: "a.tcx", mimeType: "application/xml", data: Data())
        let data = encoder.finalize()
        let body = String(data: data, encoding: .utf8)!

        let boundaryCount = body.components(separatedBy: "--B\r\n").count - 1
        XCTAssertEqual(boundaryCount, 3, "Should have 3 parts")
        XCTAssertTrue(body.hasSuffix("--B--\r\n"))
    }

    func testFinalizeClosesWithTerminatingBoundary() {
        let encoder = MultipartEncoder(boundary: "END")
        let data = encoder.finalize()
        let body = String(data: data, encoding: .utf8)!
        XCTAssertTrue(body.hasSuffix("--END--\r\n"))
    }

    func testEmptyEncoderProducesOnlyTerminator() {
        let encoder = MultipartEncoder(boundary: "X")
        let data = encoder.finalize()
        let body = String(data: data, encoding: .utf8)!
        XCTAssertEqual(body, "--X--\r\n")
    }
}
