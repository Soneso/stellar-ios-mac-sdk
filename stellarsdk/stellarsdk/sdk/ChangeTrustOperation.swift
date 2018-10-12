//
//  ChangeTrustOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a change trust operation. Creates, updates, or deletes a trustline.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#change-trust, "Change Trust Operations").
public class ChangeTrustOperation:Operation {
    
    public let asset:Asset
    public let limit:Decimal?
    
    /// Creates a new ChangeTrustOperation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    /// - Parameter asset: The asset of the trustline. For example, if a user extends a trustline of up to 200 USD to an anchor, the line is USD:anchor.
    /// - Parameter limit: The limit of the trustline. In the previous example, the limit would be 200.
    ///
    public init(sourceAccount:KeyPair? = nil, asset:Asset, limit:Decimal? = nil) {
        self.asset = asset
        self.limit = limit
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new ChangeTrustOperation object from the given ChangeTrustOperationXDR object.
    ///
    /// - Parameter fromXDR: the ChangeTrustOperationXDR object to be used to create a new ChangeTrustOperation object.
    ///
    public init(fromXDR:ChangeTrustOperationXDR, sourceAccount:KeyPair? = nil) {
        self.asset = try! Asset.fromXDR(assetXDR: fromXDR.asset)
        self.limit = Operation.fromXDRAmount(fromXDR.limit)
        super.init(sourceAccount: sourceAccount)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let assetXDR = try asset.toXDR()
        var limitXDR: Int64!
        if let limit = limit {
            limitXDR = Operation.toXDRAmount(amount: limit)
        } else {
            limitXDR = Int64.max
        }
        
        return OperationBodyXDR.changeTrust(ChangeTrustOperationXDR(asset:assetXDR,
                                                                    limit:limitXDR))
    }
}
