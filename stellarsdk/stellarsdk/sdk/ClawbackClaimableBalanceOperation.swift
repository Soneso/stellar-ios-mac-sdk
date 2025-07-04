//
//  ClawbackClaimableBalanceOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class ClawbackClaimableBalanceOperation:Operation {
    
    public let claimableBalanceID:String
    
    /// Creates a new ClawbackClaimableBalanceOperation object.
    ///
    /// - Parameter claimableBalanceID: The claimable balance id to be claimed.
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
        switch fromXDR.claimableBalanceID {
        case .claimableBalanceIDTypeV0(let hash):
            self.claimableBalanceID = hash.wrapped.hexEncodedString()
        }
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let cIDXDR = try ClaimableBalanceIDXDR(claimableBalanceId: claimableBalanceID)
        let cbXDR = ClawbackClaimableBalanceOpXDR(claimableBalanceID: cIDXDR)
        return OperationBodyXDR.clawbackClaimableBalance(cbXDR)
    }
}
