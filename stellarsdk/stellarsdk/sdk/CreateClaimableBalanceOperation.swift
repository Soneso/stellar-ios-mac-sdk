//
//  CreateClaimableBalanceOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a create claimable balance operation. Claimable Balances can be used to “split up” a payment into two parts, which allows the sending to only depend on the sending account, and the receipt to only depend on the receiving account.
/// See [Stellar Guides](https://developers.stellar.org/docs/glossary/claimable-balance "Claimable Balances").
public class CreateClaimableBalanceOperation:Operation {
    
    public let claimants:[Claimant]
    public let asset:Asset
    public let amount:Decimal
    
    /// Creates a new CreateClaimableBalanceOperation object.
    ///
    /// - Parameter asset: The asset for the claimable balance.
    /// - Parameter amount: The amount for the claimable balance.
    /// - Parameter claimants: An array of Claimants for the claimable balance.
    /// - Parameter sourceAccountId: The source account of the operation. Optional. Defaults to the transaction's source account.
    public init(asset:Asset, amount:Decimal, claimants:[Claimant], sourceAccountId:String? = nil) {
        self.asset = asset
        self.amount = amount
        self.claimants = claimants
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new CreateClaimableBalanceOperation object from the given CreateClaimableBalanceOpXDR object.
    ///
    /// - Parameter fromXDR: the CreateClaimableBalanceOpXDR object to be used to create a new CreateClaimableBalanceOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:CreateClaimableBalanceOpXDR, sourceAccountId:String?) throws {
        self.asset = try Asset.fromXDR(assetXDR: fromXDR.asset)
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        var claimantsArray = [Claimant]()
        for claimantXDR in fromXDR.claimants {
            claimantsArray.append(try Claimant.fromXDR(claimantXDR: claimantXDR))
        }
        self.claimants = claimantsArray
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let assetXDR = try asset.toXDR()
        var claimantsXDRArray = [ClaimantXDR]()
        for claimant in claimants {
            claimantsXDRArray.append(try claimant.toXDR())
        }
        let amountXDR = Operation.toXDRAmount(amount: amount)
        let cbXDR = CreateClaimableBalanceOpXDR(asset: assetXDR, amount: amountXDR, claimants: claimantsXDRArray)
        return OperationBodyXDR.createClaimableBalance(cbXDR)
    }
}
