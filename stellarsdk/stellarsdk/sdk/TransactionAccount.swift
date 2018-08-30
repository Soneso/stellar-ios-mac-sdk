//
//  TransactionAccount.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Specifies protocol for Account object used when creating an Transaction object.
public protocol TransactionAccount {
    
    /// Returns keypair associated with this Account.
    var keyPair: KeyPair { get }
    
    /// Returns current sequence number of this Account.
    var sequenceNumber : Int64 { get }
    
    /// Returns sequence number incremented by one, but does not increment internal counter.
    func incrementedSequenceNumber() -> Int64
    
    /// Increments sequence number in this object by one.
    func incrementSequenceNumber()
    
}
