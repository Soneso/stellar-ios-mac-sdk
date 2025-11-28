//
//  CustomerFileResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Response returned when uploading or retrieving customer files.
///
/// This response is returned by POST /customer/files and GET /customer/files requests in SEP-12.
/// It contains metadata about uploaded files including the file ID that can be used to reference
/// the file in subsequent PUT /customer requests.
///
/// Files can be referenced in PUT /customer requests using the pattern {field_name}_file_id.
/// For example, if uploading a photo ID front, use "photo_id_front_file_id" in the request.
///
/// See [SEP-12 Customer Files](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files)
public struct CustomerFileResponse: Decodable , Sendable {

    /// Unique identifier for the object.
    public let fileId:String
    
    /// The Content-Type of the file.
    public let contentType:String
    
    /// The size in bytes of the file object.
    public let size:Int
    
    /// (optional) The date and time the file will be discarded by the server if not referenced by the client in a PUT /customer request.
    public let expiresAt:Date?
    
    /// (optional) The id of the customer this file is associated with. If the customer record does not yet exist this will be null.
    public let customerId:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case contentType = "content_type"
        case size
        case expiresAt = "expires_at"
        case customerId = "customer_id"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try values.decode(String.self, forKey: .fileId)
        contentType = try values.decode(String.self, forKey: .contentType)
        size = try values.decode(Int.self, forKey: .size)
        if let expiresAtStr = try values.decodeIfPresent(String.self, forKey: .expiresAt),
           let expiresAtDate = ISO8601DateFormatter.full.date(from: expiresAtStr) {
            expiresAt = expiresAtDate
        } else {
            expiresAt = try values.decodeIfPresent(Date.self, forKey: .expiresAt)
        }
        customerId = try values.decodeIfPresent(String.self, forKey: .customerId)
    }
}
