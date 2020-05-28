//
//  AllowTrustOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an allow trust operation. Updates the authorized flag of an existing trustline. This can only be called by the issuer of a trustline’s asset. The issuer can only clear the authorized flag if the issuer has the AUTH_REVOCABLE_FLAG set. Otherwise, the issuer can only set the authorized flag.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#allow-trust, "Change Trust Operations").
public class AllowTrustOperation:Operation {
    
    public let trustor:KeyPair
    public let assetCode:String
    public let authorize:UInt32 // 0, or any bitwise combination of TrustLineFlags
    
    /// Creates a new PaymentOperation object.
    ///
    /// - Parameter trustor: The account of the recipient of the trustline.
    /// - Parameter assetCode: The asset code of the trustline. E.g. BTC
    /// - Parameter authorize: Flag indicating whether the trustline is authorized, true = TrustLineFlags.AUTHORIZED_FLAG
    /// - Throws StellarSDKError.invalidArgument if the asset code is empty or has more then 12 characters.
    @available(*, deprecated, message: "use init(sourceAccountId:String?, ...) instead")
    public convenience init(sourceAccount:KeyPair? = nil, trustor:KeyPair, assetCode:String, authorize:Bool) throws {
        var flags:UInt32 = 0
        if(authorize) {
            flags = TrustLineFlags.AUTHORIZED_FLAG
        }
        try self.init(sourceAccount: sourceAccount, trustor: trustor, assetCode: assetCode, authorize: flags)
    }
    
    /// Creates a new PaymentOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    /// - Parameter trustor: The account of the recipient of the trustline.
    /// - Parameter assetCode: The asset code of the trustline. E.g. BTC
    /// - Parameter authorize: Flag indicating whether the trustline is authorized, true = TrustLineFlags.AUTHORIZED_FLAG
    /// - Throws StellarSDKError.invalidArgument if the asset code is empty or has more then 12 characters.
    ///
    public convenience init(sourceAccountId:String?, trustor:KeyPair, assetCode:String, authorize:Bool) throws {
        var flags:UInt32 = 0
        if(authorize) {
            flags = TrustLineFlags.AUTHORIZED_FLAG
        }
        try self.init(sourceAccountId: sourceAccountId, trustor: trustor, assetCode: assetCode, authorize: flags)
    }
    
    /// Creates a new PaymentOperation object.
    ///
    /// - Parameter trustor: The account of the recipient of the trustline.
    /// - Parameter assetCode: The asset code of the trustline. E.g. BTC
    /// - Parameter authorize: Flag indicating whether the trustline is authorized, 0, or any bitwise combination of TrustLineFlags
    /// - Throws StellarSDKError.invalidArgument if the asset code is empty or has more then 12 characters.
    @available(*, deprecated, message: "use init(sourceAccountId:String?, ...) instead")
    public init(sourceAccount:KeyPair? = nil, trustor:KeyPair, assetCode:String, authorize:UInt32) throws {
        
        if assetCode.count == 0 {
            throw StellarSDKError.invalidArgument(message: "Asset code can not be empty.")
        }
        
        if assetCode.count > 12 {
            throw StellarSDKError.invalidArgument(message: "Asset code can not have more than 12 characters")
        }
        
        self.trustor = trustor
        self.assetCode = assetCode
        self.authorize = authorize
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new PaymentOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    /// - Parameter trustor: The account of the recipient of the trustline.
    /// - Parameter assetCode: The asset code of the trustline. E.g. BTC
    /// - Parameter authorize: Flag indicating whether the trustline is authorized, 0, or any bitwise combination of TrustLineFlags
    /// - Throws StellarSDKError.invalidArgument if the asset code is empty or has more then 12 characters.
    ///
    public init(sourceAccountId:String?, trustor:KeyPair, assetCode:String, authorize:UInt32) throws {
        
        if assetCode.count == 0 {
            throw StellarSDKError.invalidArgument(message: "Asset code can not be empty.")
        }
        
        if assetCode.count > 12 {
            throw StellarSDKError.invalidArgument(message: "Asset code can not have more than 12 characters")
        }
        
        self.trustor = trustor
        self.assetCode = assetCode
        self.authorize = authorize
        super.init(sourceAccountId:sourceAccountId)
    }
    
    
    /// Creates a new AllowTrustOperation object from the given AllowTrustOperationXDR object.
    ///
    /// - Parameter fromXDR: the AllowTrustOperationXDR object to be used to create a new AllowTrustOperation object.
    @available(*, deprecated, message: "use init(..., sourceAccountId:String?) instead")
    public init(fromXDR:AllowTrustOperationXDR, sourceAccount:KeyPair? = nil) {
        self.trustor = KeyPair(publicKey: fromXDR.trustor)
        self.assetCode = fromXDR.asset.assetCode
        self.authorize = fromXDR.authorize
        super.init(sourceAccount: sourceAccount)
    }
    
    /// Creates a new AllowTrustOperation object from the given AllowTrustOperationXDR object.
    ///
    /// - Parameter fromXDR: the AllowTrustOperationXDR object to be used to create a new AllowTrustOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:AllowTrustOperationXDR, sourceAccountId:String?) {
        self.trustor = KeyPair(publicKey: fromXDR.trustor)
        self.assetCode = fromXDR.asset.assetCode
        self.authorize = fromXDR.authorize
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {

        let allowTrustOpAsset: AllowTrustOpAssetXDR
        if assetCode.count <= 4 {
            let assetCodeXDR = WrappedData4(self.assetCode.data(using: .utf8)!)
            let ato4XDR = AllowTrustOpAssetXDR.AlphaATO4XDR(assetCode: assetCodeXDR)
            allowTrustOpAsset = AllowTrustOpAssetXDR.alphanum4(ato4XDR)
        } else {
            let assetCodeXDR = WrappedData12(self.assetCode.data(using: .utf8)!)
            let ato12XDR = AllowTrustOpAssetXDR.AlphaATO12XDR(assetCode: assetCodeXDR)
            allowTrustOpAsset = AllowTrustOpAssetXDR.alphanum12(ato12XDR)
        }
        
        return OperationBodyXDR.allowTrust(AllowTrustOperationXDR(trustor: trustor.publicKey,
                                                                  asset: allowTrustOpAsset,
                                                                  authorize: authorize))
    }
}
