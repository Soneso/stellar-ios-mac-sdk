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
    
    public var accounts:AssetAccounts
    
    public var numClaimableBalances:Int
    
    /// The number of units of credit issued.
    public var amount:Decimal
    
    /// The number of accounts that: 1) trust this asset and 2) where if the asset has the auth_required flag then the account is authorized to hold the asset.
    public var numberOfAccounts:Int
    
    public var balances:AssetBalances
    
    public var claimableBalancesAmount:Decimal
    
    /// The flags on this asset of types: auth_required, auth_revocable, auth_immutable.
    public var flags:AccountFlagsResponse
    
    /// A paging token suitable for use as the cursor parameter to assets collection resources.
    public var pagingToken:String
    
    // soroban
    public var numContracts:Int?
    public var contractsAmount:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case accounts
        case numClaimableBalances = "num_claimable_balances"
        case amount
        case balances
        case claimableBalancesAmount = "claimable_balances_amount"
        case numberOfAccounts = "num_accounts"
        case flags
        case pagingToken = "paging_token"
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
        let amountString = try values.decode(String.self, forKey: .amount) as String
        amount = Decimal(string: amountString)!
        balances = try values.decode(AssetBalances.self, forKey: .balances)
        let claimableBalancesAmountString = try values.decode(String.self, forKey: .claimableBalancesAmount) as String
        claimableBalancesAmount = Decimal(string: claimableBalancesAmountString)!
        numberOfAccounts = try values.decode(Int.self, forKey: .numberOfAccounts)
        flags = try values.decode(AccountFlagsResponse.self, forKey: .flags)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        numContracts = try values.decodeIfPresent(Int.self, forKey: .numContracts)
        contractsAmount = try values.decodeIfPresent(String.self, forKey: .contractsAmount)
    }
}

public class AssetAccounts: NSObject, Decodable {
    
    public var authorized:Int
    public var authorizedToMaintainLiabilities:Int
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

public class AssetBalances: NSObject, Decodable {
    
    public var authorized:Decimal
    public var authorizedToMaintainLiabilities:Decimal
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
        authorized = Decimal(string: authorizedString)!
        let authorizedToMaintainLiabilitiesString = try values.decode(String.self, forKey: .authorizedToMaintainLiabilities) as String
        authorizedToMaintainLiabilities = Decimal(string: authorizedToMaintainLiabilitiesString)!
        let unauthorizedString = try values.decode(String.self, forKey: .unauthorized) as String
        unauthorized = Decimal(string: unauthorizedString)!
    }
}
