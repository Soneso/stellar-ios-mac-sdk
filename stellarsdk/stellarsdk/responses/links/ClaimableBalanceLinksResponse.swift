//
//  ClaimableBalanceLinksResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for claimable balance-related resources.
///
/// Provides hypermedia links to resources associated with a claimable balance.
/// Currently only includes a self reference to the claimable balance resource.
///
/// See also:
/// - [Claimable Balance](https://developers.stellar.org/api/horizon/reference/resources/claimablebalance)
/// - [Claimable Balances Guide](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/claimable-balances)
/// - ClaimableBalanceResponse for complete details
public class ClaimableBalanceLinksResponse: NSObject, Decodable {

    /// Link to this claimable balance resource (self reference).
    public var selflink:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
    }
}
