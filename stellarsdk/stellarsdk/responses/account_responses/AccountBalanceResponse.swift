//
//  AccountBalanceResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a single asset balance in an account.
///
/// Each AccountResponse contains an array of AccountBalanceResponse objects representing
/// all assets (including native XLM) held by the account. Also includes authorization status
/// and liabilities from open offers.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountResponse for complete account information
public class AccountBalanceResponse: NSObject, Decodable {

    /// Current balance amount for this asset as a decimal string.
    public var balance:String

    /// Amount of this asset reserved for buying in open offers (liabilities).
    public var buyingLiabilities:String?

    /// Amount of this asset reserved for selling in open offers (liabilities).
    public var sellingLiabilities:String?

    /// Maximum amount of this asset the account can hold (from trustline limit).
    /// Nil for native XLM which has no limit.
    public var limit:String!

    /// Asset type: "native" for XLM, "credit_alphanum4" for 4-char assets, "credit_alphanum12" for 12-char assets, or "liquidity_pool_shares".
    public var assetType:String

    /// Asset code (e.g., "USD", "BTC"). Nil for native XLM.
    public var assetCode:String?

    /// Issuer account ID for the asset. Nil for native XLM.
    public var assetIssuer:String?

    /// Account ID sponsoring this trustline's base reserve. Nil if not sponsored.
    public var sponsor:String?

    /// Whether the issuer has authorized this account to hold the asset.
    public var isAuthorized:Bool?

    /// Whether the account is authorized to maintain liabilities but not hold new balance.
    public var isAuthorizedToMaintainLiabilities:Bool?

    /// Whether clawback is enabled for this asset.
    public var isClawbackEnabled:Bool?

    /// Liquidity pool ID for pool share balances. Nil for regular assets.
    public var liquidityPoolId:String?

    /// Ledger sequence when this balance was last modified.
    public var lastModifiedLedger:Int?

    /// Timestamp when this balance was last modified (ISO 8601).
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
