//
//  GetAccountResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response for fetching current info about a stellar account.
public class GetAccountResponse: NSObject, Decodable, TransactionAccount {
    
    /// Account Id of the account
    public var id:String
    
    /// Current sequence number of the account
    public var sequenceNumber:Int64
    
    // needed for TransactionAccount impl.
    public var keyPair:KeyPair
    
    private enum CodingKeys: String, CodingKey {
        case id
        case sequence
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        do {
            keyPair = try KeyPair(accountId: id)
        } catch {
            throw StellarSDKError.decodingError(message: "invalid account id")
        }
        
        if let val = Int64(try values.decode(String.self, forKey: .sequence)) {
            sequenceNumber = val
        } else {
            throw StellarSDKError.decodingError(message: "invalid sequence id")
        }
    }
    
    public func incrementedSequenceNumber() -> Int64 {
        return sequenceNumber + 1
    }
    
    /// Increments sequence number in this object by one.
    public func incrementSequenceNumber() {
        sequenceNumber += 1
    }
}
