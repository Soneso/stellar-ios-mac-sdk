//
//  AccountResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account response, containing information and links relating to a single account.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html "Account Details")
public class AccountResponse: NSObject, Decodable, TransactionAccount {

    /// A list of Links related to this account.
    public var links:AccountLinksResponse
    
    /// The account’s id / public key.
    public var accountId:String
    
    /// Keypair of the account containing the public key.
    public var keyPair: KeyPair
    
    /// The current sequence number that can be used when submitting a transaction from this account.
    public private (set) var sequenceNumber: Int64
    
    /// The number of account subentries.
    public var subentryCount:UInt
    
    /// A paging token, specifying where the returned records start from.
    public var pagingToken:String

    /// Account designated to receive inflation if any.
    public var inflationDestination:String?
    
    /// The home domain added to this account if any.
    public var homeDomain:String?
    
    /// An object of account flags.
    public var thresholds:AccountThresholdsResponse
    
    /// Flags used by the issuers of assets.
    public var flags:AccountFlagsResponse
    
    /// An array of the native asset or credits this account holds.
    public var balances:[AccountBalanceResponse]
    
    /// An array of account signers with their weights.
    public var signers:[AccountSignerResponse]
    
    /// An array of account data fields. The values are base64 encoded.
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
        links = try values.decode(AccountLinksResponse.self, forKey: .links)
        accountId = try values.decode(String.self, forKey: .accountId)
        self.keyPair = try KeyPair(accountId: accountId)
        let sequenceNumberString = try values.decode(String.self, forKey: .sequenceNumber)
        sequenceNumber = Int64(sequenceNumberString)!
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        subentryCount = try values.decode(UInt.self, forKey: .subentryCount)
        thresholds = try values.decode(AccountThresholdsResponse.self, forKey: .thresholds)
        flags = try values.decode(AccountFlagsResponse.self, forKey: .flags)
        balances = try values.decode(Array.self, forKey: .balances)
        signers = try values.decode(Array.self, forKey: .signers)
        data = try values.decode([String:String].self, forKey: .data)
        homeDomain = try values.decodeIfPresent(String.self, forKey: .homeDomain)
        inflationDestination = try values.decodeIfPresent(String.self, forKey: .inflationDestination)
    }
    
    ///  Returns sequence number incremented by one, but does not increment internal counter.
    public func incrementedSequenceNumber() -> Int64 {
        return sequenceNumber + 1
    }
    
    /// Increments sequence number in this object by one.
    public func incrementSequenceNumber() {
        sequenceNumber += 1
    }
}
