//
//  CustomerInformationNeededNonInteractive.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Response indicating that customer information is needed through a non-interactive flow.
///
/// This response is returned by GET /deposit or GET /withdraw requests in SEP-6 when
/// the anchor needs specific KYC fields from the user. The wallet should collect these
/// fields and submit them via SEP-12.
///
/// This approach allows wallets to collect information directly without redirecting users
/// to an external web interface.
///
/// See [SEP-6 Customer Information Needed](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#response-3)
public struct CustomerInformationNeededNonInteractive: Decodable , Sendable {

    /// Always set to non_interactive_customer_info_needed
    public let type:String

    /// A list of field names that need to be transmitted to the /customer endpoint for the deposit to proceed.
    public let fields:[String]
    
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
