//
//  ContractCreditedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents a contract credit effect.
/// This effect occurs when a Soroban smart contract receives an asset transfer.
/// Contracts can hold and manage Stellar assets as part of their execution.
/// Triggered by Invoke Host Function operations that transfer assets to contracts.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/smart-contract-internals/contract-interactions/stellar-asset-contract "Stellar Asset Contract")
public class ContractCreditedEffectResponse: EffectResponse {

    /// The contract ID receiving the credit.
    public var contract:String

    /// The amount credited to the contract.
    public var amount:String

    /// The asset type credited to the contract (e.g., native, credit_alphanum4, credit_alphanum12).
    public var assetType:String

    /// The asset code credited to the contract. Nil for native assets.
    public var assetCode:String?

    /// The issuer account ID of the asset. Nil for native assets.
    public var assetIssuer:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case contract
        case amount
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        contract = try values.decode(String.self, forKey: .contract)
        amount = try values.decode(String.self, forKey: .amount)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        try super.init(from: decoder)
    }
}
