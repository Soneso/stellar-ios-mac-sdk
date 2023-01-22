//
//  GetAccountResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response for fetching current info about a stellar account.
public class GetAccountResponse: NSObject, Decodable {
    /// Account Id of the account
    public var id:String
    /// Current sequence number of the account
    public var sequence:String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case sequence
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        sequence = try values.decode(String.self, forKey: .sequence)
    }
}
