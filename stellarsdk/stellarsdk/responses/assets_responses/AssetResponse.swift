//
//  Asset.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an asset response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class AssetResponse: NSObject, Decodable {
    
    /// A list of links related to this asset.
    public var links:AssetLinksResponse
    
    /// The type of this asset. Possible values: (native, credit_alphanum4, credit_alphanum12). See Constants.AssetType.
    public var assetType:String
    
    /// The code of this asset. E.g. BTC. Nil if assetType is "native".
    public var assetCode:String?
    
     /// The issuer of this asset. Nil if assetType is "native"
    public var assetIssuer:String?

    /// Statistics about the number of accounts holding this asset by authorization status.
    public var accounts:AssetAccounts

    /// The number of claimable balances holding this asset.
    public var numClaimableBalances:Int

    /// Statistics about the total amounts held by accounts by authorization status.
    public var balances:AssetBalances

    /// The total amount of this asset held in claimable balances.
    public var claimableBalancesAmount:Decimal
    
    /// The flags on this asset of types: auth_required, auth_revocable, auth_immutable.
    public var flags:AccountFlagsResponse
    
    /// A paging token suitable for use as the cursor parameter to assets collection resources.
    public var pagingToken:String

    /// The number of liquidity pools that include this asset.
    public var numLiquidityPools:Int

    /// The total amount of this asset held in liquidity pools.
    public var liquidityPoolsAmount:String

    /// The number of Soroban smart contracts that hold this asset. Optional, only present for Soroban-enabled networks.
    public var numContracts:Int?

    /// The total amount of this asset held in Soroban smart contracts. Optional, only present for Soroban-enabled networks.
    public var contractsAmount:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case accounts
        case numClaimableBalances = "num_claimable_balances"
        case balances
        case claimableBalancesAmount = "claimable_balances_amount"
        case flags
        case pagingToken = "paging_token"
        case numLiquidityPools = "num_liquidity_pools"
        case liquidityPoolsAmount = "liquidity_pools_amount"
        case numContracts = "num_contracts"
        case contractsAmount = "contract_amount"
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
        accounts = try values.decode(AssetAccounts.self, forKey: .accounts)
        numClaimableBalances = try values.decode(Int.self, forKey: .numClaimableBalances)
        balances = try values.decode(AssetBalances.self, forKey: .balances)
        let claimableBalancesAmountString = try values.decode(String.self, forKey: .claimableBalancesAmount) as String
        guard let cbAmount = Decimal(string: claimableBalancesAmountString) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid claimable_balances_amount format")
        }
        claimableBalancesAmount = cbAmount
        flags = try values.decode(AccountFlagsResponse.self, forKey: .flags)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        numLiquidityPools = try values.decode(Int.self, forKey: .numLiquidityPools)
        liquidityPoolsAmount = try values.decode(String.self, forKey: .liquidityPoolsAmount)
        numContracts = try values.decodeIfPresent(Int.self, forKey: .numContracts)
        contractsAmount = try values.decodeIfPresent(String.self, forKey: .contractsAmount)
    }
}

/// Statistics about the number of accounts holding an asset, categorized by authorization status.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AssetAccounts: NSObject, Decodable {

    /// The number of accounts authorized to hold and transact with this asset.
    public var authorized:Int

    /// The number of accounts authorized to maintain liabilities but not to perform other operations with this asset.
    public var authorizedToMaintainLiabilities:Int

    /// The number of accounts that are not authorized to hold or transact with this asset.
    public var unauthorized:Int
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case authorized
        case authorizedToMaintainLiabilities = "authorized_to_maintain_liabilities"
        case unauthorized
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        authorized = try values.decode(Int.self, forKey: .authorized)
        authorizedToMaintainLiabilities = try values.decode(Int.self, forKey: .authorizedToMaintainLiabilities)
        unauthorized = try values.decode(Int.self, forKey: .unauthorized)
    }
}

/// Statistics about the total amounts of an asset held by accounts, categorized by authorization status.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AssetBalances: NSObject, Decodable {

    /// The total amount held by accounts that are authorized to hold and transact with this asset.
    public var authorized:Decimal

    /// The total amount held by accounts that are authorized to maintain liabilities but not to perform other operations with this asset.
    public var authorizedToMaintainLiabilities:Decimal

    /// The total amount held by accounts that are not authorized to hold or transact with this asset.
    public var unauthorized:Decimal
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case authorized
        case authorizedToMaintainLiabilities = "authorized_to_maintain_liabilities"
        case unauthorized
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let authorizedString = try values.decode(String.self, forKey: .authorized) as String
        guard let auth = Decimal(string: authorizedString) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid authorized format")
        }
        authorized = auth
        let authorizedToMaintainLiabilitiesString = try values.decode(String.self, forKey: .authorizedToMaintainLiabilities) as String
        guard let authMaint = Decimal(string: authorizedToMaintainLiabilitiesString) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid authorized_to_maintain_liabilities format")
        }
        authorizedToMaintainLiabilities = authMaint
        let unauthorizedString = try values.decode(String.self, forKey: .unauthorized) as String
        guard let unauth = Decimal(string: unauthorizedString) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid unauthorized format")
        }
        unauthorized = unauth
    }
}
