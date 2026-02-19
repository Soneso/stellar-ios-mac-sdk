//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Enumeration of all Stellar operation types.
/// Each operation type corresponds to a specific action that can be performed on the Stellar network.
public enum OperationType: Int32, Sendable {
    /// Creates and funds a new account with a starting balance.
    case accountCreated = 0
    /// Sends native or non-native assets from source account to destination account.
    case payment = 1
    /// Sends assets along a path while receiving a specific destination amount (deprecated, use pathPaymentStrictReceive).
    case pathPayment = 2
    /// Creates or updates an offer to sell an asset at a specific price.
    case manageSellOffer = 3
    /// Creates a passive sell offer that does not take existing offers at the same price.
    case createPassiveSellOffer = 4
    /// Sets various account options including signers, thresholds, and flags.
    case setOptions = 5
    /// Creates, updates, or deletes a trustline for an asset.
    case changeTrust = 6
    /// Authorizes or deauthorizes another account to hold an asset (deprecated, use setTrustLineFlags).
    case allowTrust = 7
    /// Merges source account into destination account, transferring all funds.
    case accountMerge = 8
    /// Runs the weekly inflation process (deprecated and removed from protocol).
    case inflation = 9
    /// Sets, modifies, or deletes a key-value data entry on an account.
    case manageData = 10
    /// Bumps forward the sequence number of the source account.
    case bumpSequence = 11
    /// Creates or updates an offer to buy an asset with a specific buying amount.
    case manageBuyOffer = 12
    /// Sends a specific amount of an asset along a path, allowing destination amount to vary.
    case pathPaymentStrictSend = 13
    /// Creates a claimable balance entry that can be claimed by specified claimants.
    case createClaimableBalance = 14
    /// Claims a claimable balance, transferring funds to the claiming account.
    case claimClaimableBalance = 15
    /// Begins sponsoring the reserves of operations in a transaction.
    case beginSponsoringFutureReserves = 16
    /// Ends the sponsorship context started by beginSponsoringFutureReserves.
    case endSponsoringFutureReserves = 17
    /// Revokes sponsorship of a ledger entry or signer, transferring reserve responsibility.
    case revokeSponsorship = 18
    /// Claws back a specified amount of an asset from a holding account.
    case clawback = 19
    /// Claws back a claimable balance, returning funds to the asset issuer.
    case clawbackClaimableBalance = 20
    /// Sets flags on a trustline including authorized, authorized to maintain liabilities, and clawback enabled.
    case setTrustLineFlags = 21
    /// Deposits assets into a liquidity pool in exchange for pool shares.
    case liquidityPoolDeposit = 22
    /// Withdraws assets from a liquidity pool by redeeming pool shares.
    case liquidityPoolWithdraw = 23
    /// Invokes a smart contract function on the Soroban runtime.
    case invokeHostFunction = 24
    /// Extends the time-to-live of Soroban contract data or code entries.
    case extendFootprintTTL = 25
    /// Restores archived Soroban contract data or code entries.
    case restoreFootprint = 26
}

/// Represents an operation response. Superclass for all other operation response classes.
/// See [Stellar developer docs](https://developers.stellar.org)
public class OperationResponse: Decodable, @unchecked Sendable {

     /// A list of links related to this operation.
    public let links:OperationLinksResponse

    /// ID of the operation.
    public let id:String

    /// A paging token, specifying where the returned records start from.
    public let pagingToken:String

    /// Account ID of the source account that originated this operation.
    public let sourceAccount:String

    /// Multiplexed account address of the source account (if used).
    public let sourceAccountMuxed:String?

    /// ID of the multiplexed source account (if used).
    public let sourceAccountMuxedId:String?

    /// Type of the operation as a human readable string.
    public let operationTypeString:String

    /// Type of the operation. See OperationType enum.
    public let operationType:OperationType

    /// Date when the operation was created.
    public let createdAt:Date

    /// Transaction hash containing this operation.
    public let transactionHash:String

    /// Indicates whether the transaction containing this operation was successful.
    public let transactionSuccessful:Bool

    /// The transaction containing this operation (included if requested via join parameter).
    public let transaction: TransactionResponse?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case sourceAccount = "source_account"
        case sourceAccountMuxed = "source_account_muxed"
        case sourceAccountMuxedId = "source_account_muxed_id"
        case operationTypeString = "type"
        case operationType = "type_i"
        case createdAt = "created_at"
        case transactionHash = "transaction_hash"
        case transactionSuccessful = "transaction_successful"
        case transaction = "transaction"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(OperationLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        sourceAccount = try values.decode(String.self, forKey: .sourceAccount)
        sourceAccountMuxed = try values.decodeIfPresent(String.self, forKey: .sourceAccountMuxed)
        sourceAccountMuxedId = try values.decodeIfPresent(String.self, forKey: .sourceAccountMuxedId)
        operationTypeString = try values.decode(String.self, forKey: .operationTypeString)
        let typeIInt = try values.decode(Int.self, forKey: .operationType) as Int
        guard let opType = OperationType(rawValue: Int32(typeIInt)) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Unknown operation type: \(typeIInt)")
        }
        operationType = opType
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        transactionSuccessful = try values.decode(Bool.self, forKey: .transactionSuccessful)
        transaction = try values.decodeIfPresent(TransactionResponse.self, forKey: .transaction)
    }
}
