//
//  AccountBalanceResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents the account balance.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html "Account Balance")
public class AccountBalanceResponse: NSObject, Decodable {

    /// Balance for the specified asset.
    public var balance:String
    
    /// Buying Liabilities for the specified asset.
    public var buyingLiabilities:String?
    
    /// Selling Liabilities for the specified asset.
    public var sellingLiabilities:String?
    
    /// Maximum number of asset amount this account can hold.
    public var limit:String!
    
    /// The asset type. Possible values: native, credit_alphanum4, credit_alphanum12
    /// See also Constants.AssetType
    public var assetType:String
    
    /// The asset code e.g., USD or BTC.
    public var assetCode:String?
    
    /// The account id of the account that created the asset.
    public var assetIssuer:String?
    
    public var sponsor:String?
    
    public var isAuthorized:Bool?
    
    public var isAuthorizedToMaintainLiabilities:Bool?
    
    public var isClawbackEnabled:Bool?
    
    public var liquidityPoolId:String?
    
    public var lastModifiedLedger:Int?
    
    public var lastModifiedTime:String?
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case balance
        case buyingLiabilities = "buying_liabilities"
        case sellingLiabilities = "selling_liabilities"
        case limit
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case sponsor
        case isAuthorized = "is_authorized"
        case isAuthorizedToMaintainLiabilities = "is_authorized_to_maintain_liabilities"
        case isClawbackEnabled = "is_clawback_enabled"
        case liquidityPoolId = "liquidity_pool_id"
        case lastModifiedLedger = "last_modified_ledger"
        case lastModifiedTime = "last_modified_time"
        
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        balance = try values.decode(String.self, forKey: .balance) as String
        buyingLiabilities = try values.decodeIfPresent(String.self, forKey: .buyingLiabilities) as String?
        sellingLiabilities = try values.decodeIfPresent(String.self, forKey: .sellingLiabilities) as String?
        limit = try values.decodeIfPresent(String.self, forKey: .limit)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        sponsor = try values.decodeIfPresent(String.self, forKey: .sponsor)
        isAuthorized = try values.decodeIfPresent(Bool.self, forKey: .isAuthorized)
        isAuthorizedToMaintainLiabilities = try values.decodeIfPresent(Bool.self, forKey: .isAuthorizedToMaintainLiabilities)
        isClawbackEnabled = try values.decodeIfPresent(Bool.self, forKey: .isClawbackEnabled)
        liquidityPoolId = try values.decodeIfPresent(String.self, forKey: .liquidityPoolId)
        lastModifiedLedger = try values.decodeIfPresent(Int.self, forKey: .lastModifiedLedger)
        lastModifiedTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedTime)
    }
}
