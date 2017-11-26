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

    func testEmpty() {
        let channel = Channel<Int>(capacity: 1)
        XCTAssertTrue(channel.isEmpty)
        XCTAssertNoThrow(try channel.send(1))
        XCTAssertFalse(channel.isEmpty)
        XCTAssertNoThrow(try channel.receive())
        XCTAssertTrue(channel.isEmpty)
    }

    func testFull() {
        let channel = Channel<Int>(capacity: 1)
        XCTAssertFalse(channel.isFull)
        XCTAssertNoThrow(try channel.send(1))
        XCTAssertTrue(channel.isFull)
        XCTAssertNoThrow(try channel.receive())
        XCTAssertFalse(channel.isFull)
    }

    func testTimeout() {
        let channel = Channel<Int>(capacity: 1)
        XCTAssertNil(channel.receive(by: .now()))
        XCTAssertNil(channel.receive(timeout: .seconds(0)))
        XCTAssertNoThrow(try channel.send(1))
        let a = channel.receive(by: .now())
        XCTAssertEqual(a, 1)
        XCTAssertNoThrow(try channel.send(2))
        let b = channel.receive(timeout: .seconds(1))
        XCTAssertEqual(b, 2)
        XCTAssertNil(channel.receive(timeout: .milliseconds(1)))
    }

    static var allTests = [
        ("testChannel", testChannel),
        ("testEmpty", testEmpty),
        ("testFull", testFull),
        ("testTimeout", testTimeout),
    ]
}
