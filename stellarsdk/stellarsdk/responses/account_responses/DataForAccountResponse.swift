//
//  DataForAccountResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a data for account response from the Horizon API, conating a single data value associated with a given account and requested key.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/data-for-account.html "Data for account")
public class DataForAccountResponse: NSObject, Decodable {
    
    /// The base64-encoded value for the requested key.
    public var value:String
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case value
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decode(String.self, forKey: .value)
    }
}
