//
//  AccountDetailsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class AccountDetailsResponse: NSObject, Codable {
    var id:String
    var pagingToken:String
    var accountId:String
    var sequence:String
    var subentryCount:UInt
    var thresholds:Thresholds
    var flags:[String:Bool]
    var balances:[Balance]
    var signers:[Signer]
    var data:[String:String]
    var homeDomain:String?
    var inflationDestination:String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case pagingToken = "paging_token"
        case accountId = "account_id"
        case sequence
        case subentryCount = "subentry_count"
        case thresholds
        case flags
        case balances
        case signers
        case data
        case homeDomain = "home_domain"
        case inflationDestination = "inflation_destination"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        accountId = try values.decode(String.self, forKey: .accountId)
        sequence = try values.decode(String.self, forKey: .sequence)
        subentryCount = try values.decode(UInt.self, forKey: .subentryCount)
        thresholds = try values.decode(Thresholds.self, forKey: .thresholds)
        flags = try values.decode([String:Bool].self, forKey: .flags)
        balances = try values.decode(Array.self, forKey: .balances)
        signers = try values.decode(Array.self, forKey: .signers)
        data = try values.decode([String:String].self, forKey: .data)
        homeDomain = try values.decodeIfPresent(String.self, forKey: .homeDomain)
        inflationDestination = try values.decodeIfPresent(String.self, forKey: .inflationDestination)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pagingToken, forKey: .pagingToken)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(sequence, forKey: .sequence)
        try container.encode(subentryCount, forKey: .subentryCount)
        try container.encode(thresholds, forKey: .thresholds)
        try container.encode(flags, forKey: .flags)
        try container.encode(balances, forKey: .balances)
        try container.encode(signers, forKey: .signers)
        try container.encode(data, forKey: .data)
    }
    
}
