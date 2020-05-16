//
//  MuxedAccount.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// see https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md
public class MuxedAccount: Account
{
    public private (set) var id: UInt64?
    public private (set) var xdr: MuxedAccountXDR
    
    /// Creates a new MuxedAccount object.
    ///
    /// - Parameter keyPair: KeyPair associated with this Account.
    /// - Parameter sequenceNumber: Current sequence number of the account (can be obtained using the sdk or horizon server).
    /// - Parameter id: optional [subaccount ID](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md)
    ///
    public init(keyPair: KeyPair, sequenceNumber: Int64, id:UInt64? = nil) {
        self.id = id
        if let mid = id {
            let m = MuxedAccountMed25519XDR(id: mid, sourceAccountEd25519: keyPair.publicKey.bytes)
            self.xdr = MuxedAccountXDR.med25519(m)
        } else {
            self.xdr = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
        }
        super.init(keyPair: keyPair, sequenceNumber: sequenceNumber)
    }
    
    /// Creates a MuxedAccount from a secretSeed "S..." and a sequence number
    /// The account will be of type ED25519 if you do not provide an id
    /// The account will be of type MUXED_ED25519 if you provide an id
    public convenience init(secretSeed:String, sequenceNumber: Int64, id:UInt64? = nil) throws {
        let keyPair = try KeyPair(secretSeed: secretSeed)
        self.init(keyPair: keyPair, sequenceNumber: sequenceNumber, id:id)
    }
    
    /// Creates a MuxedAccount from an account id wich can start with "M" or with "G" and a sequence number
    /// Optionally you can also send the secret seed "S..."
    /// The account will be of type MUXED_ED25519 if the account id starts with "M" (contains the id)
    /// The account will be of type ED25519 if the account id starts with "G" (does not contain the id)
    public convenience init(accountId:String, secretSeed:String?, sequenceNumber: Int64) throws {
        
        let mux = try accountId.decodeMuxedAccount()
        let keyPair:KeyPair
        if let oseed = secretSeed {
            keyPair = try KeyPair(secretSeed: oseed)
        } else {
            keyPair = try KeyPair(publicKey: PublicKey(accountId: mux.ed25519AccountId))
        }
        var id:UInt64? = nil
        switch mux {
        case .med25519(let med):
            id = med.id
        default:
            break
        }
        self.init(keyPair: keyPair, sequenceNumber: sequenceNumber, id:id)
    }
}
