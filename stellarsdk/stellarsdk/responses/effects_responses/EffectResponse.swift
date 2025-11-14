//
//  EffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Enumeration of all available effect types on the Stellar network.
/// Effects represent specific changes that occur to the ledger as a result of operations in successfully submitted transactions.
/// See [Stellar developer docs](https://developers.stellar.org)
public enum EffectType: Int {
    /// Account was created with a starting balance.
    case accountCreated = 0
    /// Account was removed from the ledger.
    case accountRemoved = 1
    /// Account received a payment or incoming balance.
    case accountCredited = 2
    /// Account sent a payment or had balance deducted.
    case accountDebited = 3
    /// Account signing thresholds were updated.
    case accountThresholdsUpdated = 4
    /// Account home domain was updated.
    case accountHomeDomainUpdated = 5
    /// Account flags were updated.
    case accountFlagsUpdated = 6
    /// Account inflation destination was updated.
    case accountInflationDestinationUpdated = 7
    /// Signer was added to an account.
    case signerCreated = 10
    /// Signer was removed from an account.
    case signerRemoved = 11
    /// Signer weight was updated.
    case signerUpdated = 12
    /// Trustline was created for an asset.
    case trustlineCreated = 20
    /// Trustline was removed.
    case trustlineRemoved = 21
    /// Trustline limit or flags were updated.
    case trustlineUpdated = 22
    /// Trustline was authorized by the asset issuer.
    case trustlineAuthorized = 23
    /// Trustline authorization was revoked by the asset issuer.
    case trustlineDeauthorized = 24
    /// Trustline was authorized to maintain liabilities only.
    case trustlineAuthorizedToMaintainLiabilities = 25
    /// Trustline authorization flags were updated.
    case trustlineFlagsUpdated = 26
    /// Offer was created on the decentralized exchange.
    case offerCreated = 30
    /// Offer was removed from the decentralized exchange.
    case offerRemoved = 31
    /// Offer was updated on the decentralized exchange.
    case offerUpdated = 32
    /// Trade was executed between two parties.
    case tradeEffect = 33
    /// Data entry was added to an account.
    case dataCreatedEffect = 40
    /// Data entry was removed from an account.
    case dataRemovedEffect = 41
    /// Data entry was updated on an account.
    case dataUpdatedEffect = 42
    /// Account sequence number was bumped.
    case sequenceBumpedEffect = 43
    /// Claimable balance was created.
    case claimableBalanceCreatedEffect = 50
    /// Claimant was added to a claimable balance.
    case claimableBalanceClaimantCreatedEffect = 51
    /// Claimable balance was claimed by a claimant.
    case claimableBalanceClaimedEffect = 52
    /// Sponsorship for an account was created.
    case accountSponsorshipCreated = 60
    /// Sponsorship for an account was updated.
    case accountSponsorshipUpdated = 61
    /// Sponsorship for an account was removed.
    case accountSponsorshipRemoved = 62
    /// Sponsorship for a trustline was created.
    case trustlineSponsorshipCreated = 63
    /// Sponsorship for a trustline was updated.
    case trustlineSponsorshipUpdated = 64
    /// Sponsorship for a trustline was removed.
    case trustlineSponsorshipRemoved = 65
    /// Sponsorship for a data entry was created.
    case dataSponsorshipCreated = 66
    /// Sponsorship for a data entry was updated.
    case dataSponsorshipUpdated = 67
    /// Sponsorship for a data entry was removed.
    case dataSponsorshipRemoved = 68
    /// Sponsorship for a claimable balance was created.
    case claimableBalanceSponsorshipCreated = 69
    /// Sponsorship for a claimable balance was updated.
    case claimableBalanceSponsorshipUpdated = 70
    /// Sponsorship for a claimable balance was removed.
    case claimableBalanceSponsorshipRemoved = 71
    /// Sponsorship for a signer was created.
    case signerBalanceSponsorshipCreated = 72
    /// Sponsorship for a signer was updated.
    case signerBalanceSponsorshipUpdated = 73
    /// Sponsorship for a signer was removed.
    case signerBalanceSponsorshipRemoved = 74
    /// Claimable balance was clawed back by the asset issuer.
    case claimablaBalanceClawedBack = 80
    /// Assets were deposited into a liquidity pool.
    case liquidityPoolDeposited = 90
    /// Assets were withdrawn from a liquidity pool.
    case liquidityPoolWithdrew = 91
    /// Trade occurred within a liquidity pool.
    case liquidityPoolTrade = 92
    /// Liquidity pool was created.
    case liquidityPoolCreated = 93
    /// Liquidity pool was removed.
    case liquidityPoolRemoved = 94
    /// Liquidity pool trustline was revoked.
    case liquidityPoolRevoked = 95
    /// Contract balance was credited.
    case contractCredited = 96
    /// Contract balance was debited.
    case contractDebited = 97
}

/// Base class for all effect responses from the Horizon API.
/// Effects represent specific changes that occur to the ledger as a result of operations in successfully submitted transactions.
/// Each operation can produce multiple effects, and this class provides common properties shared by all effect types.
/// See [Stellar developer docs](https://developers.stellar.org)
public class EffectResponse: NSObject, Decodable {
    
    /// A list of links related to this effect.
    public var links:EffectLinksResponse
    
    /// ID of the effect.
    public var id:String
    
    /// Date of the effect.
    public var createdAt:String
    
    /// A paging token, specifying where the returned records start from.
    public var pagingToken:String
    
    /// Account ID of the account the effect belongs to.
    public var account:String

    /// The multiplexed account address if the account is a muxed account.
    public var accountMuxed:String?

    /// The multiplexed account ID if the account is a muxed account.
    public var accountMuxedId:String?
    
    /// Type of the effect as a human readable string.
    public var effectTypeString:String
    
    /// Type of the effect (int) see enum EffectType.
    public var effectType:EffectType
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case account
        case accountMuxed = "account_muxed"
        case accountMuxedId = "account_muxed_id"
        case effectTypeString = "type"
        case effectType = "type_i"
        case createdAt = "created_at"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(EffectLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        createdAt = try values.decode(String.self, forKey: .createdAt)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        account = try values.decode(String.self, forKey: .account)
        accountMuxed = try values.decodeIfPresent(String.self, forKey: .accountMuxed)
        accountMuxedId = try values.decodeIfPresent(String.self, forKey: .accountMuxedId)
        effectTypeString = try values.decode(String.self, forKey: .effectTypeString)
        let typeIInt = try values.decode(Int.self, forKey: .effectType) as Int
        effectType = EffectType(rawValue: typeIInt)!
    }
}
