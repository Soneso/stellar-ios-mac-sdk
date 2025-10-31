//
//  Asset.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 14.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Base Asset class.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/assets.html, "Assets")
public class Asset
{
    public let type:Int32
    public private(set) var code:String?
    public private(set) var issuer:KeyPair?
    
    /// Creates an Asset object based on the given type, code and issuer. Assets can have the types: native, alphanumeric 4, alphanumeric 12. The asset of type native has no code and no issuer. Assets of type alphanumeric 4, alphanumeric 12 must have a code and an issuer.
    ///
    /// - Parameter type: Type of asset. Possible values: AssetType.ASSET_TYPE_NATIVE, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 and AssetType.ASSET_TYPE_CREDIT_ALPHANUM12.
    /// - Parameter code: Code of asset. E.g. "BTC". Any characters from the set [a-z][A-Z][0-9] are allowed. If the value of the parameter 'type' is AssetType.ASSET_TYPE_NATIVE the value of the parameter 'code' will be ignored. If 'type' has the value AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 then 'code' must be not nil and not empty, 4-character maximum. If 'type' is AssetType.ASSET_TYPE_CREDIT_ALPHANUM12 then 'code' must be not nil and not shorter than 5 characters, 12-character maximum.
    ///- Parameter issuer: Issuer of the asset. If the value of the parameter 'type' is AssetType.ASSET_TYPE_NATIVE the value of the parameter issuer will be ignored. If the value of the parameter 'type' is NOT AssetType.ASSET_TYPE_NATIVE, the value of issuer must be a not nil.
    ///
    /// - Returns: an Asset object or nil for invalid parameter values.
    ///
    public init?(type:Int32, code:String? = nil, issuer:KeyPair? = nil) {
        self.type = type
        switch self.type {
            case AssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
                guard let code = code, code.count >= StellarProtocolConstants.ASSET_CODE_MIN_LENGTH, code.count <= StellarProtocolConstants.ASSET_CODE_ALPHANUM4_MAX_LENGTH, issuer != nil else { return nil }
                self.code = code
                self.issuer = issuer
            case AssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
                guard let code = code, code.count >= StellarProtocolConstants.ASSET_CODE_ALPHANUM12_MIN_LENGTH, code.count <= StellarProtocolConstants.ASSET_CODE_ALPHANUM12_MAX_LENGTH, issuer != nil else { return nil }
                self.code = code
                self.issuer = issuer
            case AssetType.ASSET_TYPE_NATIVE:
                break
            case AssetType.ASSET_TYPE_POOL_SHARE:
                break
            default:
                return nil
        }
    }
    
    public convenience init?(canonicalForm: String) {
        if canonicalForm == StellarProtocolConstants.ASSET_CANONICAL_NATIVE || canonicalForm == "XLM" {
            self.init(type: AssetType.ASSET_TYPE_NATIVE)!
            return
        }
        let components = canonicalForm.components(separatedBy: ":")
        if components.count != 2 {
            return nil
        }
        let code = components[0].trimmingCharacters(in: .whitespaces)
        let issuer = components[1].trimmingCharacters(in: .whitespaces)
        let type = code.count < StellarProtocolConstants.ASSET_CODE_ALPHANUM12_MIN_LENGTH ? AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 : AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
        do {
            let kp = try KeyPair(accountId: issuer)
            self.init(type: type, code: code, issuer: kp)
        } catch {
            return nil
        }
    }
    
    public func toCanonicalForm() -> String {
        switch self.type {
            case AssetType.ASSET_TYPE_NATIVE:
                return StellarProtocolConstants.ASSET_CANONICAL_NATIVE
            default:
                return self.code! + ":" + self.issuer!.accountId
        }
    }
    
    /// Generates XDR object from the Asset object.
    /// Throws StellarSDKError.xdrEncodingError if the XDR Object could not be created.
    public func toXDR() throws -> AssetXDR {
        
        do {
            switch self.type {
                case AssetType.ASSET_TYPE_NATIVE:
                    return AssetXDR.native
                default:
                    return try AssetXDR(assetCode:code!, issuer:issuer!)
            }
        } catch {
            throw StellarSDKError.xdrEncodingError(message: "Error encoding asset: " + error.localizedDescription)
        }
    }
    
    public func toTrustlineAssetXDR() throws -> TrustlineAssetXDR {
        
        do {
            switch self.type {
                case AssetType.ASSET_TYPE_NATIVE:
                    return TrustlineAssetXDR.native
                default:
                    return try TrustlineAssetXDR(assetCode:code!, issuer:issuer!)
            }
        } catch {
            throw StellarSDKError.xdrEncodingError(message: "Error encoding asset: " + error.localizedDescription)
        }
    }
    
    /// Generates Asset object from a given XDR object.
    ///
    /// - Parameter assetXDR: the AssetXDR object to be used create the Asset object.
    ///
    /// - Throws StellarSDKError.xdrDecodingError if the Asset object could not be created from the given.
    ///
    /// - Returns the generated Asset object.
    ///
    public static func fromXDR(assetXDR:AssetXDR) throws -> Asset {
        
        var result: Asset?
        switch assetXDR {
            case .native:
                result = Asset(type:AssetType.ASSET_TYPE_NATIVE)
            
            case .alphanum4 (let a4):
                let issuerKeyPair = KeyPair (publicKey: a4.issuer, privateKey: nil)
                result = Asset(type:AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code:assetXDR.assetCode, issuer:issuerKeyPair)
            
            case .alphanum12 (let a12):
                let issuerKeyPair = KeyPair (publicKey: a12.issuer, privateKey: nil)
                result = Asset(type:AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code:assetXDR.assetCode, issuer:issuerKeyPair)
        }
        guard let asset = result else {
            throw StellarSDKError.xdrDecodingError(message: "Error decoding asset: invalid data in xdr")
        }
        return asset
    }
}

public class ChangeTrustAsset : Asset {
    public private(set) var assetA:Asset?
    public private(set) var assetB:Asset?
    
    public init?(assetA:Asset, assetB:Asset) throws {
        
        // validate asset type
        if AssetType.ASSET_TYPE_POOL_SHARE == assetA.type || AssetType.ASSET_TYPE_POOL_SHARE == assetB.type {
            throw StellarSDKError.invalidArgument(message: "Asset can not be of type AssetType.ASSET_TYPE_POOL_SHARE")
        }
        if assetA.type == assetB.type && assetA.type == AssetType.ASSET_TYPE_NATIVE {
            throw StellarSDKError.invalidArgument(message: "Assets can not be both of type AssetType.ASSET_TYPE_NATIVE")
        }
        
        // validate asset order
        // Native < AlphaNum4 < AlphaNum12, then by Code, then by Issuer, using lexicographic ordering.
        var sortError = false
        if assetA.type > assetB.type {
            sortError = true
        } else if assetA.type == assetB.type {
            if assetA.code! > assetB.code! {
                sortError = true
            } else if assetA.code! == assetB.code! {
                if assetA.issuer!.accountId > assetB.issuer!.accountId {
                    sortError = true
                }
            }
        }
        if sortError {
            throw StellarSDKError.invalidArgument(message: "Assets are in wrong order. Sort by: Native < AlphaNum4 < AlphaNum12, then by Code, then by Issuer, using lexicographic ordering.")
        }
        
        self.assetA = assetA
        self.assetB = assetB
    
        super.init(type: AssetType.ASSET_TYPE_POOL_SHARE)
    }
    
    public override init?(type:Int32, code:String? = nil, issuer:KeyPair? = nil) {
        super.init(type: type, code: code, issuer: issuer)
    }
    
    public func toChangeTrustAssetXDR() throws -> ChangeTrustAssetXDR {
        
        do {
            switch self.type {
                case AssetType.ASSET_TYPE_NATIVE:
                    return ChangeTrustAssetXDR.native
                case AssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
                    return try ChangeTrustAssetXDR(assetCode:code!, issuer:issuer!)
                case AssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
                    return try ChangeTrustAssetXDR(assetCode:code!, issuer:issuer!)
                case AssetType.ASSET_TYPE_POOL_SHARE:
                    let assetAXDR = try assetA!.toXDR()
                    let assetBXDR = try assetB!.toXDR()
                    let params = LiquidityPoolConstantProductParametersXDR(assetA: assetAXDR, assetB: assetBXDR, fee: StellarProtocolConstants.LIQUIDITY_POOL_FEE_V18)
                    return ChangeTrustAssetXDR(params: params)
                default:
                    throw StellarSDKError.xdrEncodingError(message: "Unknown asset type")
                
            }
        } catch {
            throw StellarSDKError.xdrEncodingError(message: "Error encoding asset: " + error.localizedDescription)
        }
    }
    
    public static func fromXDR(assetXDR:ChangeTrustAssetXDR) throws -> ChangeTrustAsset {
        
        var result: ChangeTrustAsset?
        switch assetXDR {
            case .native:
                result = ChangeTrustAsset(type:AssetType.ASSET_TYPE_NATIVE)
            
            case .alphanum4 (let a4):
                let issuerKeyPair = KeyPair (publicKey: a4.issuer, privateKey: nil)
                result = ChangeTrustAsset(type:AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code:assetXDR.assetCode, issuer:issuerKeyPair)
            
            case .alphanum12 (let a12):
                let issuerKeyPair = KeyPair (publicKey: a12.issuer, privateKey: nil)
                result = ChangeTrustAsset(type:AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code:assetXDR.assetCode, issuer:issuerKeyPair)
                
            case .poolShare(let params):
                switch params {
                case .constantProduct(let cp):
                    let assetA = try Asset.fromXDR(assetXDR: cp.assetA)
                    let assetB = try Asset.fromXDR(assetXDR: cp.assetB)
                    result = try ChangeTrustAsset(assetA: assetA, assetB: assetB)
                }
        }
        guard let asset = result else {
            throw StellarSDKError.xdrDecodingError(message: "Error decoding asset: invalid data in xdr")
        }
        return asset
    }
}
