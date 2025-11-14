//
//  ClaimableBalanceResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance response from the Horizon API.
/// Claimable balances are held on the ledger until they are claimed by authorized claimants
/// or until the conditions for claiming them expire.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimableBalanceResponse: NSObject, Decodable {

    /// A list of links related to this claimable balance.
    public var links:ClaimableBalanceLinksResponse

    /// Unique identifier for this claimable balance.
    public var balanceId:String

    /// The asset available to be claimed.
    public var asset:Asset

    /// The amount of the asset that can be claimed.
    public var amount:String

    /// The account ID of the sponsor who is paying the reserves for this claimable balance.
    public var sponsor:String

    /// The sequence number of the ledger in which this claimable balance was last modified.
    public var lastModifiedLedger:Int

    /// An ISO 8601 formatted string of when this claimable balance was last modified.
    public var lastModifiedTime:String?

    /// Paging token suitable for use as a cursor parameter.
    public var pagingToken:String

    /// The list of entries which could claim this balance and their conditions for claiming.
    public var claimants:[ClaimantResponse]
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case balanceId = "id"
        case claimants
        case asset
        case amount
        case sponsor
        case lastModifiedLedger = "last_modified_ledger"
        case lastModifiedTime = "last_modified_time"
        case pagingToken = "paging_token"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(ClaimableBalanceLinksResponse.self, forKey: .links)
        balanceId = try values.decode(String.self, forKey: .balanceId)
        claimants = try values.decode([ClaimantResponse].self, forKey: .claimants)
        let canonicalAsset = try values.decode(String.self, forKey: .asset)
        if let a = Asset(canonicalForm: canonicalAsset) {
            asset = a
        } else {
            throw StellarSDKError.decodingError(message: "not a valid asset in horizon response")
        }
        amount = try values.decode(String.self, forKey: .amount)
        sponsor = try values.decode(String.self, forKey: .sponsor)
        lastModifiedLedger = try values.decode(Int.self, forKey: .lastModifiedLedger)
        lastModifiedTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedTime)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
    }
}
