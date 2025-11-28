//
//  InvokeHostFunctionOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents an invoke host function operation response.
/// This Soroban operation invokes a smart contract function on the Stellar network.
/// See [Stellar developer docs](https://developers.stellar.org)
public class InvokeHostFunctionOperationResponse: OperationResponse, @unchecked Sendable {

    /// Type of host function being invoked (e.g., InvokeContract, CreateContract).
    public let function:String

    /// Contract address or deployment address.
    public let address:String

    /// Salt used for contract deployment.
    public let salt:String

    /// Parameters passed to the function.
    public let parameters:[ParameterResponse]?

    /// Asset balance changes resulting from the invocation.
    public let assetBalanceChanges:[AssetBalanceChange]?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case function
        case address
        case salt
        case parameters
        case assetBalanceChanges = "asset_balance_changes"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        function = try values.decode(String.self, forKey: .function)
        address = try values.decode(String.self, forKey: .address)
        salt = try values.decode(String.self, forKey: .salt)
        parameters = try values.decodeIfPresent([ParameterResponse].self, forKey: .parameters)
        assetBalanceChanges = try values.decodeIfPresent([AssetBalanceChange].self, forKey: .assetBalanceChanges)
        try super.init(from: decoder)
    }
}

/// Represents a parameter passed to a Soroban contract function.
public final class ParameterResponse: Decodable, Sendable {

    /// Parameter type.
    public let type:String

    /// Parameter value.
    public let value:String
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try values.decode(String.self, forKey: .type)
        value = try values.decode(String.self, forKey: .value)
        
    }
}

/// Represents an asset balance change resulting from a Soroban contract invocation.
public final class AssetBalanceChange: Decodable, Sendable {

    /// Asset type (native / alphanum4 / alphanum12).
    public let assetType:String

    /// Asset code (if not native).
    public let assetCode:String?

    /// Asset issuer (if not native).
    public let assetIssuer:String?

    /// Type of balance change (transfer, mint, burn, etc.).
    public let type:String

    /// Source account of the transfer (if applicable).
    public let from:String?

    /// Destination account of the transfer.
    public let to:String

    /// Amount transferred or changed.
    public let amount:String

    /// Multiplexed ID of the destination account (if used).
    public let destinationMuxedId:String?
   
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case type
        case from
        case to
        case amount
        case destinationMuxedId = "destination_muxed_id"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        type = try values.decode(String.self, forKey: .type)
        from = try values.decodeIfPresent(String.self, forKey: .from)
        to = try values.decode(String.self, forKey: .to)
        amount = try values.decode(String.self, forKey: .amount)
        destinationMuxedId = try values.decodeIfPresent(String.self, forKey: .destinationMuxedId)
    }
}
