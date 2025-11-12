//
//  ManageDataOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a manage data operation response.
///  See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#manage-data "Manage Data Operation")
public class ManageDataOperationResponse: OperationResponse {
    
    /// Name of the data entry (key in the name/value pair).
    public var name:String

    /// Base64-encoded value of the data entry. Empty string to delete the entry.
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
