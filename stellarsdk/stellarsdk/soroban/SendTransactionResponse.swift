//
//  SendTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SendTransactionResponse: NSObject, Decodable {
    
    /// The transaction hash (in an hex-encoded string), and the initial transaction status, ("pending" or something)
    public var transactionId:String
    
    /// the current status of the transaction by hash, one of: pending, success, error
    public var status:String
    
    /// (optional) If the transaction was rejected immediately, this will be an error object.
    public var error:TransactionStatusError?
    
    private enum CodingKeys: String, CodingKey {
        case transactionId = "id"
        case status
        case error
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        status = try values.decode(String.self, forKey: .status)
        error = try values.decodeIfPresent(TransactionStatusError.self, forKey: .error)
    }
}
