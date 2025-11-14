//
//  SetTrustlineFlagsOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar set trustline flags operation allowing issuers to authorize or revoke trustlines.
public class SetTrustlineFlagsOperation:Operation {

    /// The asset of the trustline whose flags are being modified.
    public let asset:Asset
    /// The account whose trustline is affected by this operation.
    public let trustorAccountId:String
    /// Indicates which flags to set. The bit mask adds onto the existing trustline flags.
    public let setFlags:UInt32
    /// Indicates which flags to clear. The bit mask subtracts from the existing trustline flags.
    public let clearFlags:UInt32

    /// Creates a new SetTrustlineFlagsOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "M" or "G" and must be valid, otherwise it will be ignored.
    /// - Parameter asset: The asset to set trustline flags for
    /// - Parameter trustorAccountId: account whose trustline is affected by this operation
    /// - Parameter setFlags:Indicates which flags to set. For details about the flags, please refer to the trustline doc. The bit mask integer adds onto the existing flags of the trustline. This allows for setting specific bits without knowledge of existing flags. (note that CAP-35 introduces the new AUTH_CLAWBACK_ENABLED_FLAG flag)
    /// - Parameter clearFlags:Indicates which flags to clear. For details about the flags, please refer to the trustline doc. The bit mask integer subtracts from the existing flags of the trustline. This allows for setting specific bits without knowledge of existing flags. (note that CAP-35 introduces the new AUTH_CLAWBACK_ENABLED_FLAG flag)
    ///
    public init(sourceAccountId:String?, asset:Asset,trustorAccountId:String, setFlags:UInt32, clearFlags:UInt32) {
        self.asset = asset
        self.trustorAccountId = trustorAccountId
        self.clearFlags = clearFlags
        self.setFlags = setFlags
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new SetTrustlineFlagsOperation object from the given SetTrustLineFlagsOpXDR object.
    ///
    /// - Parameter fromXDR: the SetTrustLineFlagsOpXDR object to be used to create a new SetTrustlineFlagsOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:SetTrustLineFlagsOpXDR, sourceAccountId:String?) {
        self.asset = try! Asset.fromXDR(assetXDR: fromXDR.asset)
        self.trustorAccountId = fromXDR.accountID.accountId
        self.clearFlags = fromXDR.clearFlags
        self.setFlags = fromXDR.setFlags
        
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let assetXDR = try asset.toXDR()
        let pk = try PublicKey(accountId: trustorAccountId)
        return OperationBodyXDR.setTrustLineFlags(SetTrustLineFlagsOpXDR(accountID: pk, asset: assetXDR, setFlags: setFlags, clearFlags: clearFlags))
    }
}
