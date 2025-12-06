//
//  OperationLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for operation-related resources.
///
/// Provides hypermedia links to resources associated with an operation, including
/// effects, the containing transaction, and chronologically adjacent operations.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - OperationResponse for complete operation details
/// - LinkResponse for individual link structure
public struct OperationLinksResponse: Decodable, Sendable {

    /// Templated link to effects produced by this operation. Supports cursor, order, and limit.
    public let effects:LinkResponse

    /// Link to this operation resource (self reference).
    public let selfLink:LinkResponse

    /// Link to the transaction containing this operation.
    public let transaction:LinkResponse

    /// Templated link to operations that occurred chronologically after this one.
    public let precedes:LinkResponse

    /// Templated link to operations that occurred chronologically before this one.
    public let succeeds:LinkResponse
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case effects
        case selfLink = "self"
        case transaction
        case precedes
        case succeeds
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        effects = try values.decode(LinkResponse.self, forKey: .effects)
        selfLink = try values.decode(LinkResponse.self, forKey: .selfLink)
        transaction = try values.decode(LinkResponse.self, forKey: .transaction)
        precedes = try values.decode(LinkResponse.self, forKey: .precedes)
        succeeds = try values.decode(LinkResponse.self, forKey: .succeeds)
    }
}
