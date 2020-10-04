//
//  CreateClaimableBalanceOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class CreateClaimableBalanceOperationResponse: OperationResponse {
    
    public var sponsor:String
    public var asset:Asset
    public var amount:String
    public var claimants: [ClaimantResponse]
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sponsor
        case asset
        case amount
        case claimants
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sponsor = try values.decode(String.self, forKey: .sponsor)
        let canonicalAsset = try values.decode(String.self, forKey: .asset)
        if let a = Asset(canonicalForm: canonicalAsset) {
            asset = a
        } else {
            throw StellarSDKError.decodingError(message: "not a valid asset in horizon response")
        }
        amount = try values.decode(String.self, forKey: .amount)
        claimants = try values.decode([ClaimantResponse].self, forKey: .claimants)
        try super.init(from: decoder)
    }
}

