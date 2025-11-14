//
//  PathPaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a path payment operation. Sends an amount in a specific asset to a destination account through a path of offers. This allows the asset sent (e.g., 450 XLM) to be different from the asset received (e.g, 6 BTC).
/// See [Stellar developer docs](https://developers.stellar.org)
public class PathPaymentOperation:Operation {

    /// The asset deducted from the sender's account.
    public let sendAsset:Asset
    /// The maximum amount of send asset to deduct, excluding fees.
    public let sendMax:Decimal
    /// The destination account that receives the payment.
    public let destinationAccountId:String
    /// The asset the destination account receives.
    public let destAsset:Asset
    /// The amount of destination asset the destination account receives.
    public let destAmount:Decimal
    /// The assets involved in the offers the path takes. Maximum of 5 assets.
    public let path:[Asset]
    
    /// Creates a new PathPaymentOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    /// - Parameter sendAsset: The asset deducted from the sender’s account.
    /// - Parameter sendMax: The maximum amount of send asset to deduct (excluding fees).
    /// - Parameter destinationAccountId: Account address that receives the payment, must be valid, otherwise this will throw an exception.
    /// - Parameter destAsset: The asset the destination account receives.
    /// - Parameter destAmount: The amount of destination asset the destination account receives.
    /// - Parameter path: The assets (other than send asset and destination asset) involved in the offers the path takes. For example, if you can only find a path from USD to EUR through XLM and BTC, the path would be USD -> XLM -> BTC -> EUR and the path field would contain XLM and BTC. The maximum number of assets in the path is 5
    ///
    /// - Throws StellarSDKError.invalidArgument if maximum number of assets in the path is > 5
    ///
    public init(sourceAccountId:String?, sendAsset:Asset, sendMax:Decimal, destinationAccountId:String, destAsset:Asset, destAmount:Decimal, path:[Asset]) throws {
        
        if path.count > 5 {
            throw StellarSDKError.invalidArgument(message: "The maximum number of assets in the path is 5")
        }
        
        self.sendAsset = sendAsset
        self.sendMax = sendMax
        let mux = try destinationAccountId.decodeMuxedAccount()
        self.destinationAccountId = mux.accountId
        self.destAsset = destAsset
        self.destAmount = destAmount
        self.path = path
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new PathPaymentOperation object from the given PathPaymentOperationXDR object.
    ///
    /// - Parameter fromXDR: the PathPaymentOperationXDR object to be used to create a new PathPaymentOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:PathPaymentOperationXDR, sourceAccountId:String?) {
        self.sendAsset = try! Asset.fromXDR(assetXDR: fromXDR.sendAsset)
        self.sendMax = Operation.fromXDRAmount(fromXDR.sendMax)
        self.destinationAccountId = fromXDR.destination.accountId
        self.destAsset = try! Asset.fromXDR(assetXDR: fromXDR.destinationAsset)
        self.destAmount = Operation.fromXDRAmount(fromXDR.destinationAmount)
        var path = [Asset]()
        for asset in fromXDR.path {
            path.append(try! Asset.fromXDR(assetXDR: asset))
        }
        self.path = path
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let sendAssetXDR = try sendAsset.toXDR()
        let destAssetXDR = try destAsset.toXDR()
        var pathXDR = [AssetXDR]()
        
        for asset in path {
            try pathXDR.append(asset.toXDR())
        }
        
        let sendMaxXDR = Operation.toXDRAmount(amount: sendMax)
        let destAmountXDR = Operation.toXDRAmount(amount: destAmount)
        let mDestination = try destinationAccountId.decodeMuxedAccount()
        
        return OperationBodyXDR.pathPayment(PathPaymentOperationXDR(sendAsset: sendAssetXDR,
                                                                    sendMax:sendMaxXDR,
                                                                    destination: mDestination,
                                                                    destinationAsset: destAssetXDR,
                                                                    destinationAmount:destAmountXDR,
                                                                    path: pathXDR))
    }
}
