import XCTest
@testable import Channel

class ChannelTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Channel().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
