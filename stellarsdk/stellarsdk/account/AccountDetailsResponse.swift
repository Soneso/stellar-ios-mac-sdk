//
//  AccountDetailsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class AccountDetailsResponse: NSObject, Codable {

    public var links:Links
    public var id:String
    public var accountId:String
    public var sequenceNumber:String
    public var pagingToken:String
    public var subentryCount:UInt
    public var inflationDestination:String?
    public var homeDomain:String?
    public var thresholds:Thresholds
    public var flags:Flags
    public var balances:[Balance]
    public var signers:[Signer]
    public var data:[String:String]

    
    enum CodingKeys: String, CodingKey {
        case id
        case links = "_links"
        case accountId = "account_id"
        case sequenceNumber = "sequence"
        case pagingToken = "paging_token"
        case subentryCount = "subentry_count"
        case inflationDestination = "inflation_destination"
        case homeDomain = "home_domain"
        case thresholds
        case flags
        case balances
        case signers
        case data

    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        links = try values.decode(Links.self, forKey: .links)
        accountId = try values.decode(String.self, forKey: .accountId)
        sequenceNumber = try values.decode(String.self, forKey: .sequenceNumber)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        subentryCount = try values.decode(UInt.self, forKey: .subentryCount)
        thresholds = try values.decode(Thresholds.self, forKey: .thresholds)
        flags = try values.decode(Flags.self, forKey: .flags)
        balances = try values.decode(Array.self, forKey: .balances)
        signers = try values.decode(Array.self, forKey: .signers)
        data = try values.decode([String:String].self, forKey: .data)
        homeDomain = try values.decodeIfPresent(String.self, forKey: .homeDomain)
        inflationDestination = try values.decodeIfPresent(String.self, forKey: .inflationDestination)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(links, forKey: .links)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(sequenceNumber, forKey: .sequenceNumber)
        try container.encode(pagingToken, forKey: .pagingToken)
        try container.encode(subentryCount, forKey: .subentryCount)
        try container.encode(thresholds, forKey: .thresholds)
        try container.encode(flags, forKey: .flags)
        try container.encode(balances, forKey: .balances)
        try container.encode(signers, forKey: .signers)
        try container.encode(data, forKey: .data)
    }
    
}
