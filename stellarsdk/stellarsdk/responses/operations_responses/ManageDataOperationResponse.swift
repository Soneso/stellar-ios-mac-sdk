//
//  ManageDataOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a manage data operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#manage-data "Manage Data Operation")
public class ManageDataOperationResponse: OperationResponse {
    
    /// Name from the (name/value pair) for an account.
    public var name:String
    
    /// Value from the (name/value pair) for an account.
    public var value:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
        case value
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        value = try values.decode(String.self, forKey: .value)
        
        try super.init(from: decoder)
    }
}
