//
//  ResolveAddressResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 22/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct ResolveAddressResponse: Decodable {

    /// stellar address in the format <username*domain.tld>
    public var stellarAddress:String?
    
    /// the public key of the account
    public var accountId:String?
    
    /// (optional) - Memo type that needs to be attached to a transaction
    public var memoType:String?
    
    /// (optional) - Memo value that needs to be attached to a transaction
    public var memo:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case stellarAddress = "stellar_address"
        case accountId = "account_id"
        case memoType = "memo_type"
        case memo = "memo"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stellarAddress = try values.decodeIfPresent(String.self, forKey: .stellarAddress)
        accountId = try values.decodeIfPresent(String.self, forKey: .accountId)
        memoType = try values.decodeIfPresent(String.self, forKey: .memoType)
        memo = try values.decodeIfPresent(String.self, forKey: .memo)
    }
}
