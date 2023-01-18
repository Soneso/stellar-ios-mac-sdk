//
//  TransactionStatusError.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class TransactionStatusError: NSObject, Decodable {
    
    /// Short unique string representing the type of error
    public var code:String
    
    /// Human friendly summary of the error
    public var message:String
    
    /// (optional) More data related to the error if available
    public var data:[String:Any]?
    
    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(String.self, forKey: .code)
        message = try values.decode(String.self, forKey: .message)
        do {
            data = try values.decodeIfPresent([String:Any].self, forKey: .data)
        } catch {}
    }
}
