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
        lock.sync { self.queue.enqueue(message) }
        elementsAvailable.signal()
    }

    /// Dequeue an element from the channel (blocks if the channel is empty)
    ///
    /// - Returns: the oldest in-flight element on the channel
    /// - Throws: `.closed` if no more elements are available on a closed cannel
    public func receive() throws -> Element {
        defer { spaceAvailable.signal() }
        elementsAvailable.wait()
        return lock.sync { self.queue.dequeue() }
    }
}
