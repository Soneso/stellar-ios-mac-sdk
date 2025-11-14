//
//  CustomerInformationNeededInteractive.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Response indicating that customer information is needed through an interactive flow.
///
/// This response is returned by GET /deposit or GET /withdraw requests in SEP-6 when
/// the anchor needs to collect KYC information from the user through a web interface.
/// The wallet should display the provided URL in a popup or iframe.
///
/// Note: Interactive components of SEP-6 are deprecated in favor of SEP-24.
///
/// See [SEP-6 Customer Information Needed](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#response-3)
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
