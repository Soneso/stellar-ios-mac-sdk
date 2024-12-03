//
//  GetCustomerFilesResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.12.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public struct GetCustomerFilesResponse: Decodable {
    
    /// A list of file objects
    public var files:[CustomerFileResponse]
    
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
