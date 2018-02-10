//
//  Asset.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an asset response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/assets-all.html "All Assets Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/asset.html "Asset")
public class AssetResponse: NSObject, Decodable {
    
    /// A list of links related to this asset.
    public var links:AssetLinksResponse
    
    /// The type of this asset. Possible values: (native, credit_alphanum4, credit_alphanum12). See Constants.AssetType.
    public var assetType:String
    
    /// The code of this asset. E.g. BTC. Nil if assetType is "native".
    public var assetCode:String?
    
     /// The issuer of this asset. Nil if assetType is "native"
    public var assetIssuer:String?
    
    /// The number of units of credit issued.
    public var amount:Decimal
    
    /// The number of accounts that: 1) trust this asset and 2) where if the asset has the auth_required flag then the account is authorized to hold the asset.
    public var numberOfAccounts:Int
    
    /// The flags on this asset of types: auth_required, auth_revocable, auth_immutable.
    public var flags:AccountFlagsResponse
    
    /// A paging token suitable for use as the cursor parameter to assets collection resources.
    public var pagingToken:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case amount
        case numberOfAccounts = "num_accounts"
        case flags
        case pagingToken = "paging_token"
        
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(AssetLinksResponse.self, forKey: .links)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        let amountString = try values.decode(String.self, forKey: .amount) as String
        amount = Decimal(string: amountString)!
        numberOfAccounts = try values.decode(Int.self, forKey: .numberOfAccounts)
        flags = try values.decode(AccountFlagsResponse.self, forKey: .flags)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
       
    }
}
