//
//  RevokeSponsorshipOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class RevokeSponsorshipOperationResponse: OperationResponse {
    
    public var accountId:String?
    public var claimableBalanceId:String?
    public var dataAccountId:String?
    public var dataName:String?
    public var offerId:String?
    public var trustlineAccountId:String?
    public var trustlineAsset:String?
    public var signerAccountId:String?
    public var signerKey:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case claimableBalanceId = "claimable_balance_id"
        case dataAccountId = "data_account_id"
        case dataName = "data_name"
        case offerId = "offer_id"
        case trustlineAccountId = "trustline_account_id"
        case trustlineAsset = "trustline_asset"
        case signerAccountId = "signer_account_id"
        case signerKey = "signer_key"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try values.decodeIfPresent(String.self, forKey: .accountId)
        claimableBalanceId = try values.decodeIfPresent(String.self, forKey: .claimableBalanceId)
        dataAccountId = try values.decodeIfPresent(String.self, forKey: .dataAccountId)
        dataName = try values.decodeIfPresent(String.self, forKey: .dataName)
        offerId = try values.decodeIfPresent(String.self, forKey: .offerId)
        trustlineAccountId = try values.decodeIfPresent(String.self, forKey: .trustlineAccountId)
        trustlineAsset = try values.decodeIfPresent(String.self, forKey: .trustlineAsset)
        signerAccountId = try values.decodeIfPresent(String.self, forKey: .signerAccountId)
        signerKey = try values.decodeIfPresent(String.self, forKey: .signerKey)
        try super.init(from: decoder)
    }
}
