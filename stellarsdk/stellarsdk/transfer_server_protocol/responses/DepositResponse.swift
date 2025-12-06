//
//  DepositResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Response returned when initiating a deposit transaction.
///
/// This response is returned by GET /deposit and GET /deposit-exchange requests in SEP-6.
/// It provides instructions for how to complete the deposit, including where to send the
/// off-chain funds and any additional information needed.
///
/// The wallet should use the transaction ID to query the GET /transaction endpoint to check
/// the status of the deposit.
///
/// See [SEP-6 Deposit](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#deposit-2)
public struct DepositResponse: Decodable , Sendable {

    /// (Deprecated, use instructions instead) Terse but complete instructions for how to deposit the asset. In the case of most cryptocurrencies it is just an address to which the deposit should be sent.
    public let how:String
    
    /// (optional) JSON object containing the SEP-9 financial account fields that describe how to complete the off-chain deposit.
    /// If the anchor cannot provide this information in the response, the wallet should query the /transaction endpoint to get this asynchonously.
    public let instructions:[String:DepositInstruction]?
    
    /// (optional) The anchor's ID for this deposit. The wallet will use this ID to query the /transaction endpoint to check status of the request.
    public let id:String?
    
    /// (optional) Estimate of how long the deposit will take to credit in seconds.
    public let eta:Int?
    
    /// (optional) Minimum amount of an asset that a user can deposit.
    public let minAmount:Double?
    
    /// (optional) Maximum amount of asset that a user can deposit.
    public let maxAmount:Double?
    
    /// (optional) Fixed fee (if any). In units of the deposited asset.
    public let feeFixed:Double?
    
    /// (optional) Percentage fee (if any). In units of percentage points.
    public let feePercent:Double?
    
    /// (optional) Any additional data needed as an input for this deposit, example: Bank Name
    public let extraInfo:ExtraInfo?
        
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case how = "how"
        case id = "id"
        case eta = "eta"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case feeFixed = "fee_fixed"
        case feePercent = "fee_percent"
        case extraInfo = "extra_info"
        case instructions
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        how = try values.decode(String.self, forKey: .how)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        eta = try values.decodeIfPresent(Int.self, forKey: .eta)
        minAmount = try values.decodeIfPresent(Double.self, forKey: .minAmount)
        maxAmount = try values.decodeIfPresent(Double.self, forKey: .maxAmount)
        feeFixed = try values.decodeIfPresent(Double.self, forKey: .feeFixed)
        feePercent = try values.decodeIfPresent(Double.self, forKey: .feePercent)
        extraInfo = try values.decodeIfPresent(ExtraInfo.self, forKey: .extraInfo)
        instructions = try values.decodeIfPresent([String:DepositInstruction].self, forKey: .instructions)
    }
    
}

/// Instruction for completing the off-chain deposit.
///
/// Contains SEP-9 financial account fields that describe how to complete the deposit.
/// Each instruction provides a value and description for a specific field.
///
/// See [SEP-6 Deposit Response](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#response)
public struct DepositInstruction: Decodable , Sendable {

    /// The value of the field.
    public let value:String

    /// A human-readable description of the field. This can be used by an anchor
    /// to provide any additional information about fields that are not defined
    /// in the SEP-9 standard.
    public let description:String
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case value
        case description
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decode(String.self, forKey: .value)
        description = try values.decode(String.self, forKey: .description)
    }
}


/// Additional information about the deposit process.
///
/// Contains optional messages or details that provide context about the deposit.
///
/// See [SEP-6 Deposit Response](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#response)
public struct ExtraInfo: Decodable , Sendable {

    /// (optional) Additional details about the deposit process.
    public let message:String?
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case message
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}
