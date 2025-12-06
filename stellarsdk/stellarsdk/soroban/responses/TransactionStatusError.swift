//
//  TransactionStatusError.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Internal error used within some of the responses.
public struct TransactionStatusError: Decodable, Sendable {

    /// Short unique string representing the type of error
    public let code:String

    /// Human friendly summary of the error
    public let message:String

    /// (optional) More data related to the error if available
    public let data: String?

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(String.self, forKey: .code)
        message = try values.decode(String.self, forKey: .message)
        data = try values.decodeIfPresent(String.self, forKey: .data)
    }
}
