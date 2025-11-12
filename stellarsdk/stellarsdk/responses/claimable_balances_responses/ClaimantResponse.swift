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
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/claimablebalance "Claimable Balance")
public class ClaimantResponse: NSObject, Decodable {

    /// The account ID who can claim the balance.
    public var destination:String

    /// The condition which must be satisfied for the destination account to claim the balance.
    public var predicate:ClaimantPredicateResponse
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case destination
        case predicate
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        destination = try values.decode(String.self, forKey: .destination)
        predicate = try values.decode(ClaimantPredicateResponse.self, forKey: .predicate)
    }
}
