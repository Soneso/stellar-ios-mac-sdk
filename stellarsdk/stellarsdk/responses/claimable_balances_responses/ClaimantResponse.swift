//
//  ClaimantResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimant entry for a claimable balance.
/// Each claimant specifies an account that can claim the balance and the conditions under which they can claim it.
/// See [Stellar developer docs](https://developers.stellar.org)
public struct ClaimantResponse: Decodable, Sendable {

    /// The account ID who can claim the balance.
    public let destination: String

    /// The condition which must be satisfied for the destination account to claim the balance.
    public let predicate: ClaimantPredicateResponse


    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case destination
        case predicate
    }

    /**
        Initializer - creates a new instance by decoding from the given decoder.

        - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        destination = try values.decode(String.self, forKey: .destination)
        predicate = try values.decode(ClaimantPredicateResponse.self, forKey: .predicate)
    }
}
