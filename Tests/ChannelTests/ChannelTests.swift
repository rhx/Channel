import XCTest
@testable import Channel

class ChannelTests: XCTestCase {
    func testChannel() {
        let channel = Channel<Int>(capacity: 1)
        var i = 0
        DispatchQueue.global(qos: .utility).async {
            i += 1
            try! channel.send(1)
            i += 1
            try! channel.send(2)
        }
        let a = try! channel.receive()
        XCTAssertEqual(a, 1)
        let b = try! channel.receive()
        XCTAssertEqual(b, 2)
        XCTAssertEqual(i, 2)
    }


    static var allTests = [
        ("testChannel", testChannel),
    ]
}
