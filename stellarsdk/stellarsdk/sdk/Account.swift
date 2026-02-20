//
//  Account.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account in Stellar network with it's sequence number.
public class Account: TransactionAccount, @unchecked Sendable
{
    /// The keypair associated with this account.
    public let keyPair: KeyPair
    /// The current sequence number of the account.
    public var sequenceNumber: Int64 {
        lock.lock()
        defer { lock.unlock() }
        return _sequenceNumber
    }
    private var _sequenceNumber: Int64
    private let lock = NSLock()

    /// Creates a new Account object.
    ///
    /// - Parameter keyPair: KeyPair associated with this Account.
    /// - Parameter sequenceNumber: Current sequence number of the account (can be obtained using the sdk or horizon server).
    ///
    public init(keyPair: KeyPair, sequenceNumber: Int64) {
        self.keyPair = keyPair
        self._sequenceNumber = sequenceNumber
    }

    /// Creates an Account from account ID string and sequence number.
    public init(accountId: String, sequenceNumber: Int64) throws {
        self.keyPair = try KeyPair(accountId: accountId)
        self._sequenceNumber = sequenceNumber
    }

    ///  Returns sequence number incremented by one, but does not increment internal counter.
    public func incrementedSequenceNumber() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return _sequenceNumber + 1
    }

    /// Increments sequence number in this object by one.
    public func incrementSequenceNumber() {
        lock.lock()
        defer { lock.unlock() }
        _sequenceNumber += 1
    }

    /// Decrements sequence number in this object by one.
    public func decrementSequenceNumber() {
        lock.lock()
        defer { lock.unlock() }
        _sequenceNumber -= 1
    }

    /// The Stellar account ID for this account.
    public var accountId:String {
        return keyPair.accountId
    }
}
