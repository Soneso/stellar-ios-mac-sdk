//
//  CustomerInformationNeededInteractive.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct CustomerInformationNeededInteractive: Decodable {

    /// Always set to non_interactive_customer_info_needed
    public var type:String
    
    /// URL hosted by the anchor. The wallet should show this URL to the user either as a popup or an iframe.
    public var url:String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case url = "url"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        url = try values.decode(String.self, forKey: .url)
    }
    
}
