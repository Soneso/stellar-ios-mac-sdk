//
//  PathPaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a path payment operation. Sends an amount in a specific asset to a destination account through a path of offers. This allows the asset sent (e.g., 450 XLM) to be different from the asset received (e.g, 6 BTC).
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#path-payment, "Path Payment Operations")
 */
public class PathPaymentOperation:Operation {
    
    public let sendAsset:Asset
    public let sendMax:Int64
    public let destination:KeyPair
    public let destAsset:Asset
    public let destAmount:Int64
    public let path:[Asset]
    
    /**
        Constructor
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
        - Parameter sendAsset: The asset deducted from the sender’s account.
        - Parameter sendMax: The maximum amount of send asset to deduct (excluding fees).
        - Parameter destination: Account ID of the recipient.
        - Parameter destAsset: The asset the destination account receives.
        - Parameter destAmount: The amount of destination asset the destination account receives.
        - Parameter path: The assets (other than send asset and destination asset) involved in the offers the path takes. For example, if you can only find a path from USD to EUR through XLM and BTC, the path would be USD -> XLM -> BTC -> EUR and the path field would contain XLM and BTC. The maximum number of assets in the path is 5
     
        - Returns the PathPaymentOperation if the given arguments are valid. Otherwise returns nil.
     */
    public init?(sourceAccount:KeyPair, sendAsset:Asset, sendMax:Int64, destination:KeyPair, destAsset:Asset, destAmount:Int64, path:[Asset]) {
        
        if path.count > 5 {return nil}
        
        self.sendAsset = sendAsset
        self.sendMax = sendMax
        self.destination = destination
        self.destAsset = destAsset
        self.destAmount = destAmount
        self.path = path
        super.init(sourceAccount:sourceAccount)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let sendAssetXDR = try sendAsset.toXDR()
        let destAssetXDR = try destAsset.toXDR()
        var pathXDR = [AssetXDR]()
        
        for asset in path {
            try pathXDR.append(asset.toXDR())
        }
        
        let sendMaxXDR = toXDRAmount(amount: sendMax)
        let destAmountXDR = toXDRAmount(amount: destAmount)
        
        return OperationBodyXDR.pathPayment(PathPaymentOperationXDR(sendAsset: sendAssetXDR,
                                                                    sendMax:sendMaxXDR,
                                                                    destinationID: destination.publicKey,
                                                                    destinationAsset: destAssetXDR,
                                                                    destinationAmount:destAmountXDR,
                                                                    path: pathXDR))
    }
}
