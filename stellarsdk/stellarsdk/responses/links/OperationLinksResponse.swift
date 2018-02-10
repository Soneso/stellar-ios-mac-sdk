//
//  OperationLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to an operation response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html "Operation")
public class OperationLinksResponse: NSObject, Decodable {
    
    /// Link to the effects of this operation.
    public var effects:LinkResponse
    
    /// Link to the current operation respones.
    public var selfLink:LinkResponse
    
    /// Link to the transaction of this operation.
    public var transaction:LinkResponse
    
    /// Link to the next operation.
    public var precedes:LinkResponse
    
    /// Link to the previous operation.
    public var succeeds:LinkResponse
    
    
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
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        effects = try values.decode(LinkResponse.self, forKey: .effects)
        selfLink = try values.decode(LinkResponse.self, forKey: .selfLink)
        transaction = try values.decode(LinkResponse.self, forKey: .transaction)
        precedes = try values.decode(LinkResponse.self, forKey: .precedes)
        succeeds = try values.decode(LinkResponse.self, forKey: .succeeds)
    }
}
