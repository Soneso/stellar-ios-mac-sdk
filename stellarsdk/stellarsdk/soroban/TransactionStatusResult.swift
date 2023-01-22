//
//  TransactionStatusResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Used as a part of get transaction status and send transaction.
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
    
    public var value:SCValXDR? {
        try? SCValXDR.fromXdr(base64: xdr)
    }
}

public struct TransactionStatus {
    public static let SUCCESS: String = "success"
    public static let PENDING: String = "pending"
    public static let ERROR: String = "error"
}
