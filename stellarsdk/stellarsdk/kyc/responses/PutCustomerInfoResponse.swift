//
//  PutCustomerInfoResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response returned after successfully uploading customer information.
///
/// This response is returned by PUT /customer requests in SEP-12 when the anchor has
/// successfully received and stored the customer information. The response contains an ID
/// that can be used in future requests to retrieve or update the customer's information.
///
/// The anchor responds with HTTP 202 Accepted or 200 Success along with this response body.
///
/// See [SEP-12 Customer PUT](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put)
public struct PutCustomerInfoResponse: Decodable , Sendable {

    /// An identifier for the updated or created customer
    public let id:String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
    }
}
