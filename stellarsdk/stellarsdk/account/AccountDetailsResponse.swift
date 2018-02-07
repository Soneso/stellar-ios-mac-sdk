//
//  AccountDetailsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an account response, containing information and links relating to a single account.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html "Account Details")
public class AccountDetailsResponse: NSObject, Codable {

    /// A list of Links related to this account.
    public var links:AccountLinks
    
    /// The account’s id / public key.
    public var accountId:String
    
    /// The current sequence number that can be used when submitting a transaction from this account.
    public var sequenceNumber:String
    
    /// The number of account subentries.
    public var subentryCount:UInt
    
    /// A paging token, specifying where the returnned records start from.
    public var pagingToken:String

    /// Account designated to receive inflation if any.
    public var inflationDestination:String?
    
    /// The home domain added to this account if any.
    public var homeDomain:String?
    
    /// An object of account flags.
    public var thresholds:Thresholds
    
    /// Flags used by the issuers of assets.
    public var flags:Flags
    
    /// An array of the native asset or credits this account holds.
    public var balances:[Balance]
    
    /// An array of account signers with their weights.
    public var signers:[Signer]
    
    /// An array of account data fields.
    public var data:[String:String]

    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
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
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
    */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(AccountLinks.self, forKey: .links)
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
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
    */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
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
