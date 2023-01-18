//
//  TransactionStatusResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class TransactionStatusResult: NSObject, Decodable {
    
    /// xdr-encoded return value of the contract call
    public var xdr:String
    
    private enum CodingKeys: String, CodingKey {
        case xdr
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        xdr = try values.decode(String.self, forKey: .xdr)
    }
}
