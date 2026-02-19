//
//  MemoProtocol.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/16/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Protocol defining the interface for transaction memos that attach messages or data to Stellar transactions.
public protocol MemoProtocol: Sendable {
    /// Converts the memo to its XDR representation for network transmission.
    func toXDR() -> MemoXDR
    /// Creates a text memo from the provided string.
    init?(text:String) throws
    /// Creates a hash memo from the provided data.
    init?(hash:Data) throws
    /// Creates a return hash memo from the provided data.
    init?(returnHash:Data) throws
    /// Returns the memo type identifier as a string.
    func type() -> String
}

/// Protocol for memos containing hash values with hex encoding capabilities.
public protocol MemoHashProtocol: Sendable {
    /// Returns the hex-encoded string representation of the hash value.
    func hexValue() throws -> String
    /// Returns the hex-encoded hash value with leading zeros removed.
    func trimmedHexValue() throws -> String
}
