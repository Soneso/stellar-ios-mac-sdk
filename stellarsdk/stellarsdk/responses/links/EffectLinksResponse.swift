//
//  EffectLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for effect-related resources.
///
/// Provides hypermedia links to resources associated with an effect, including
/// the operation that produced it and chronologically adjacent effects.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - EffectResponse for complete effect details
/// - LinkResponse for individual link structure
public struct EffectLinksResponse: Decodable, Sendable {

    /// Link to the operation that produced this effect.
    public let operation:LinkResponse

    /// Templated link to effects that occurred chronologically after this one.
    public let precedes:LinkResponse

    /// Templated link to effects that occurred chronologically before this one.
    public let succeeds:LinkResponse
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case operation
        case precedes
        case succeeds
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        operation = try values.decode(LinkResponse.self, forKey: .operation)
        precedes = try values.decode(LinkResponse.self, forKey: .precedes)
        succeeds = try values.decode(LinkResponse.self, forKey: .succeeds)
    }
}
