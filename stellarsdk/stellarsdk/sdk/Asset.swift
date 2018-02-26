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
                guard let code = code, code.count >= 1, code.count <= 4, issuer != nil else { return nil }
                self.code = code
                self.issuer = issuer
            case AssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
                guard let code = code, code.count >= 5, code.count <= 12, issuer != nil else { return nil }
                self.code = code
                self.issuer = issuer
            case AssetType.ASSET_TYPE_NATIVE:
                break
            default:
                return nil
        }
    }
    
    /// Generates XDR object from the Asset object.
    /// Throws StellarSDKError.xdrDecodingError if the XDR Object could not be created.
    public func toXDR() throws -> AssetXDR {
        
        do {
            switch self.type {
                case AssetType.ASSET_TYPE_NATIVE:
                    return AssetXDR.native
                default:
                    return try AssetXDR(assetCode:code!, issuer:issuer!)
            }
        } catch {
            throw StellarSDKError.xdrDecodingError(message: "Error decoding asset: " + error.localizedDescription)
        }
    }
    
    /// Generates Asset object from a given XDR object.
    ///
    /// - Parameter assetXDR: the AssetXDR object to be used create the Asset object.
    ///
    /// - Throws StellarSDKError.xdrEncodingError if the Asset object could not be created from the given.
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
            throw StellarSDKError.xdrDecodingError(message: "Error encoding asset: invalid data in xdr")
        }
        return asset
    }
}
