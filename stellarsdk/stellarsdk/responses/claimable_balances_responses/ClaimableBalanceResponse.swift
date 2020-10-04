//
//  ClaimableBalanceResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class ClaimableBalanceResponse: NSObject, Decodable {
    
    /// A list of links related to this claimable balance.
    public var links:ClaimableBalanceLinksResponse
    
    public var balanceId:String
    public var asset:Asset
    public var amount:String
    public var sponsor:String
    public var lastModifiedLedger:Int
    public var lastModifiedTime:String
    public var pagingToken:String
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
        lastModifiedTime = try values.decode(String.self, forKey: .lastModifiedTime)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
    }
}
