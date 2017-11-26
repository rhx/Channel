//
//  Channel.swift
//  Channel
//
//  Created by Rene Hexel on 26/11/17.
//  Copyright © 2017 Rene Hexel. All rights reserved.
//
import Dispatch
import CircularQueue
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension pthread_mutex_t {
    mutating func lock() { pthread_mutex_lock(&self) }
    mutating func unlock() { pthread_mutex_unlock(&self) }
    mutating func sync<T>(_ compute: () -> T) -> T {
        lock()
        let rv = compute()
        unlock()
        return rv
    }
}

/// Uni-directional Channel class for communication between threads and
/// Dispatch queues.
public class Channel<Element> {
    let queue: CircularQueue<Element>
    var spaceAvailable: DispatchSemaphore
    var elementsAvailable: DispatchSemaphore
    var lock = pthread_mutex_t()

    /// Number of in-flight send operations before blocking
    public var capacity: Int { return queue.capacity }
    /// Indicate whether the channel will transmit any more elements
    public fileprivate(set) var isClosed = false
    /// `true` if there are no elements that can currently be read
    public var isEmpty: Bool {
        let isEmpty = elementsAvailable.wait(timeout: .now()) == .timedOut
        if !isEmpty { elementsAvailable.signal() }
        return isEmpty
    }
    /// `true` if the channel has reached capacity
    public var isFull: Bool {
        let isFull = spaceAvailable.wait(timeout: .now()) == .timedOut
        if !isFull { spaceAvailable.signal() }
        return isFull
    }

    /// Create a channel with a given capacity
    ///
    /// - Parameter n: maximum number messages to queue
    public init(capacity n: Int) {
        spaceAvailable = DispatchSemaphore(value: n)
        elementsAvailable = DispatchSemaphore(value: 0)
        queue = CircularQueue(capacity: n)
        pthread_mutex_init(&lock, nil)
    }

    deinit {
        pthread_mutex_destroy(&lock)
    }

    /// Enqueue a message on the channel
    ///
    /// - Parameter message: the message to transmit
    /// - Throws: `.closed` if the channel has been closed
    public func send(_ message: Element) throws {
        guard !isClosed else { throw Error.closed }
        spaceAvailable.wait()
        defer { elementsAvailable.signal() }
        guard !isClosed else { throw Error.closed }
        lock.sync { self.queue.enqueue(message) }
    }

    /// Dequeue an element from the channel (blocks if the channel is empty)
    ///
    /// - Returns: the oldest in-flight element on the channel
    /// - Throws: `.closed` if the channel is closed
    public func receive() throws -> Element {
        guard !isClosed else { throw Error.closed }
        elementsAvailable.wait()
        defer { spaceAvailable.signal() }
        guard !isClosed else { throw Error.closed }
        return lock.sync { self.queue.dequeue() }
    }

    /// Dequeue an element from the channel with a given timeout
    ///
    /// - Returns: the oldest in-flight element on the channel, or `nil` in case of timeout
    /// - Parameter timeout: dispatch time interval (e.g. `.seconds(1)`)
    public func receive(timeout: DispatchTimeInterval) -> Element? {
        guard !isClosed, elementsAvailable.wait(timeout: .now() + timeout) == .success else { return nil }
        defer { spaceAvailable.signal() }
        guard !isClosed else { return nil }
        return lock.sync { self.queue.dequeue() }
    }

    /// Dequeue an element from the channel (blocks if the channel is empty)
    ///
    /// - Returns: the oldest in-flight element on the channel, or `nil` in case of timeout
    /// - Parameter t: absolute wall time (e.g. `.now()`, `.distantFuture`)
    public func receive(by t: DispatchWallTime) -> Element? {
        guard !isClosed, elementsAvailable.wait(wallTimeout: t) == .success else { return nil }
        defer { spaceAvailable.signal() }
        guard !isClosed else { return nil }
        return lock.sync { self.queue.dequeue() }
    }

    /// Close the channel.
    /// This will make all pending `send()` and `receive()` operations fail.
    public func close() {
        isClosed = true
        for _ in 0..<capacity {
            spaceAvailable.signal()
            elementsAvailable.signal()
        }
    }
}
