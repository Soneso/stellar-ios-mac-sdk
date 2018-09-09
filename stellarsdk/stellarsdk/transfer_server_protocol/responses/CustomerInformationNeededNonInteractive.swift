//
//  CustomerInformationNeededNonInteractive.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct CustomerInformationNeededNonInteractive: Decodable {

    /// Always set to non_interactive_customer_info_needed
    public var type:String
    
    /// A list of field names that need to be transmitted to the /customer endpoint for the deposit to proceed.
    public var fields:[String]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case fields = "fields"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        fields = try values.decode([String].self, forKey: .fields)
    }
    
}
