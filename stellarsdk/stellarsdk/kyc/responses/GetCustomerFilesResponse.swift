//
//  GetCustomerFilesResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Response returned when retrieving customer files.
///
/// This response is returned by GET /customer/files requests in SEP-12 and contains a list
/// of files associated with a customer. The request can filter by file_id or customer_id.
///
/// If no files are found for the specified identifier, an empty list is returned.
///
/// See [SEP-12 Customer Files GET](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#get-request)
public struct GetCustomerFilesResponse: Decodable , Sendable {

    /// A list of file objects
    public let files:[CustomerFileResponse]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case files
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        files = try values.decode([CustomerFileResponse].self, forKey: .files)
    }
}
