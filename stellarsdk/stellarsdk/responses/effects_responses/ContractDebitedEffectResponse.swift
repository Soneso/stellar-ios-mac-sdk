//
//  ContractDebitedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents a contract debit effect.
/// This effect occurs when a Soroban smart contract sends an asset transfer.
/// Contracts can hold and manage Stellar assets as part of their execution.
/// Triggered by Invoke Host Function operations that transfer assets from contracts.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ContractDebitedEffectResponse: EffectResponse {

    /// The contract ID sending the debit.
    public var contract:String

    /// The amount debited from the contract.
    public var amount:String

    /// The asset type debited from the contract (e.g., native, credit_alphanum4, credit_alphanum12).
    public var assetType:String

    /// The asset code debited from the contract. Nil for native assets.
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
