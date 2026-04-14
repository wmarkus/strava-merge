import XCTest
@testable import ZwiftSync

final class XMLBuilderTests: XCTestCase {

    func testEmptyBuilderProducesEmptyData() {
        let builder = XMLBuilder()
        XCTAssertEqual(builder.data.count, 0)
    }

    func testSingleLineOutput() {
        var builder = XMLBuilder()
        builder.line("<root/>")
        let output = String(data: builder.data, encoding: .utf8)!
        XCTAssertEqual(output, "<root/>")
    }

    func testMultipleLinesJoinedWithNewlines() {
        var builder = XMLBuilder()
        builder.line("<root>")
        builder.line("  <child/>")
        builder.line("</root>")
        let output = String(data: builder.data, encoding: .utf8)!
        XCTAssertEqual(output, "<root>\n  <child/>\n</root>")
    }

    func testOutputIsUTF8() {
        var builder = XMLBuilder()
        builder.line("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        let data = builder.data
        XCTAssertNotNil(String(data: data, encoding: .utf8))
    }

    func testSpecialCharactersPreserved() {
        var builder = XMLBuilder()
        builder.line("<name>Zwift Ride — 2h 30m</name>")
        let output = String(data: builder.data, encoding: .utf8)!
        XCTAssertTrue(output.contains("—"))
    }
}
