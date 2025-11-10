//
//  ResolveAddressResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 22/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a federation server response according to SEP-0002.
///
/// This structure contains the resolved information for a Stellar address, mapping human-readable
/// addresses like "alice*example.com" to account IDs and optional memo fields required for payments.
///
/// Federation servers return this response when successfully resolving addresses through name lookup,
/// account ID reverse lookup, transaction ID lookup, or forward lookup requests.
///
/// ## Example Response
///
/// ```swift
/// {
///     "stellar_address": "alice*testanchor.stellar.org",
///     "account_id": "GACCOUNT...",
///     "memo_type": "id",
///     "memo": "12345"
/// }
/// ```
///
/// ## Usage
///
/// ```swift
/// let result = await Federation.resolve(stellarAddress: "alice*example.com")
/// if case .success(let response) = result {
///     // Use account ID for payment
///     let destination = response.accountId
///
///     // Attach memo if present
///     if let memoType = response.memoType, let memoValue = response.memo {
///         // Create appropriate memo based on type
///     }
/// }
/// ```
///
/// See [SEP-0002 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md)
public struct ResolveAddressResponse: Decodable {

    /// The Stellar address in the format "username*domain.tld".
    ///
    /// Examples: "alice*testanchor.stellar.org", "bob@email.com*example.com", "+14155550100*stellar.org"
    public var stellarAddress:String?

    /// The Stellar account ID (public key) associated with the address.
    ///
    /// Format: G followed by 55 additional characters (56 total), e.g., "GACCOUNT..."
    public var accountId:String?

    /// The type of memo that must be attached to transactions sent to this address.
    ///
    /// Optional field. Valid values:
    /// - "text": Plain text memo (up to 28 bytes)
    /// - "id": Unsigned 64-bit integer memo
    /// - "hash": 32-byte hash memo (base64-encoded in this response)
    ///
    /// When present, the corresponding memo value must be included in all transactions
    /// to this destination to ensure proper crediting.
    public var memoType:String?

    /// The memo value that must be attached to transactions sent to this address.
    ///
    /// Optional field. The format depends on memoType:
    /// - For "text": A string value (up to 28 bytes)
    /// - For "id": A string representation of an unsigned 64-bit integer
    /// - For "hash": A base64-encoded 32-byte hash
    ///
    /// Always provided as a string type, even for "id" memoType, to support parsing in
    /// languages without native big number support. Required when memoType is present.
    public var memo:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case stellarAddress = "stellar_address"
        case accountId = "account_id"
        case memoType = "memo_type"
        case memo = "memo"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stellarAddress = try values.decodeIfPresent(String.self, forKey: .stellarAddress)
        accountId = try values.decodeIfPresent(String.self, forKey: .accountId)
        memoType = try values.decodeIfPresent(String.self, forKey: .memoType)
        memo = try values.decodeIfPresent(String.self, forKey: .memo)
    }
}
