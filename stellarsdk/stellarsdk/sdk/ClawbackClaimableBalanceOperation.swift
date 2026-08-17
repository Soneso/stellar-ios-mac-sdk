//
//  ClawbackClaimableBalanceOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar clawback claimable balance operation allowing issuers to reclaim unclaimedbalances.
public class ClawbackClaimableBalanceOperation:Operation, @unchecked Sendable {

    /// The claimable balance id to be clawed back.
    ///
    /// An operation read from XDR reports the 72-character form Horizon serves: the four-byte
    /// big-endian union discriminant ahead of the 32-byte hash. An operation built from a
    /// string reports that string as given.
    public let claimableBalanceID:String

    /// Creates a new ClawbackClaimableBalanceOperation object.
    ///
    /// - Parameter claimableBalanceID: The claimable balance id to be clawed back.
    /// - Parameter sourceAccountId: The source account of the operation. Optional. Defaults to the transaction's source account.
    public init(claimableBalanceID:String, sourceAccountId:String? = nil) {
        self.claimableBalanceID = claimableBalanceID
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new ClawbackClaimableBalanceOperation object from the given ClawbackClaimableBalanceOpXDR object.
    ///
    /// - Parameter fromXDR: the ClawbackClaimableBalanceOpXDR object to be used to create a new ClawbackClaimableBalanceOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:ClawbackClaimableBalanceOpXDR, sourceAccountId:String?) throws {
        self.claimableBalanceID = fromXDR.claimableBalanceID.paddedBalanceIdHex
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let cIDXDR = try ClaimableBalanceIDXDR(claimableBalanceId: claimableBalanceID)
        let cbXDR = ClawbackClaimableBalanceOpXDR(claimableBalanceID: cIDXDR)
        return OperationBodyXDR.clawbackClaimableBalanceOp(cbXDR)
    }
}
