//
//  RevokeSponsorshipOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a revoke sponsorship operation response.
/// This operation revokes sponsorship of a ledger entry or signer, transferring reserve responsibility back to the sponsored account.
/// See [Stellar developer docs](https://developers.stellar.org)
public class RevokeSponsorshipOperationResponse: OperationResponse, @unchecked Sendable {

    /// Account ID if revoking account sponsorship.
    public let accountId:String?

    /// Claimable balance ID if revoking claimable balance sponsorship.
    public let claimableBalanceId:String?

    /// Account ID if revoking data entry sponsorship.
    public let dataAccountId:String?

    /// Data entry name if revoking data entry sponsorship.
    public let dataName:String?

    /// Offer ID if revoking offer sponsorship.
    public let offerId:String?

    /// Account ID if revoking trustline sponsorship.
    public let trustlineAccountId:String?

    /// Asset if revoking trustline sponsorship.
    public let trustlineAsset:String?

    /// Account ID if revoking signer sponsorship.
    public let signerAccountId:String?

    /// Signer key if revoking signer sponsorship.
    public let signerKey:String?
    
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
