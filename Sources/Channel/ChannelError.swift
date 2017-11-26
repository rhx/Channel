//
//  ChannelError.swift
//  Channel
//
//  Created by Rene Hexel on 26/11/17.
//  Copyright © 2017 Rene Hexel. All rights reserved.
//
import Foundation

public typealias _ErrorProtocol = Error

public extension Channel {
    public enum Error: _ErrorProtocol {
        /// Everything is OK
        case ok
        /// The channel is closed
        case closed
    }
}
