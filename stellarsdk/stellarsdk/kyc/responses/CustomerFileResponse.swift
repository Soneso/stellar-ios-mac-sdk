//
//  CustomerFileResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public struct CustomerFileResponse: Decodable {
    
    /// Unique identifier for the object.
    public var fileId:String
    
    /// The Content-Type of the file.
    public var contentType:String
    
    /// The size in bytes of the file object.
    public var size:Int
    
    /// (optional) The date and time the file will be discarded by the server if not referenced by the client in a PUT /customer request.
    public var expiresAt:Date?
    
    /// (optional) The id of the customer this file is associated with. If the customer record does not yet exist this will be null.
    public var customerId:String?
    
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
