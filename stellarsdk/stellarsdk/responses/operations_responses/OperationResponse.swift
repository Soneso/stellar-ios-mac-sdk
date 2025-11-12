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
public enum OperationType: Int32 {
    case accountCreated = 0
    case payment = 1
    case pathPayment = 2
    case manageSellOffer = 3
    case createPassiveSellOffer = 4
    case setOptions = 5
    case changeTrust = 6
    case allowTrust = 7
    case accountMerge = 8
    case inflation = 9
    case manageData = 10
    case bumpSequence = 11
    case manageBuyOffer = 12
    case pathPaymentStrictSend = 13
    case createClaimableBalance = 14
    case claimClaimableBalance = 15
    case beginSponsoringFutureReserves = 16
    case endSponsoringFutureReserves = 17
    case revokeSponsorship = 18
    case clawback = 19
    case clawbackClaimableBalance = 20
    case setTrustLineFlags = 21
    case liquidityPoolDeposit = 22
    case liquidityPoolWithdraw = 23
    case invokeHostFunction = 24
    case extendFootprintTTL = 25
    case restoreFootprint = 26
}

/// Represents an operation response. Superclass for all other operation response classes.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html "Operation")
public class OperationResponse: NSObject, Decodable {

     /// A list of links related to this operation.
    public var links:OperationLinksResponse
    
    /// ID of the operation.
    public var id:String

    /// A paging token, specifying where the returned records start from.
    public var pagingToken:String

    /// Account ID of the source account that originated this operation.
    public var sourceAccount:String

    /// Multiplexed account address of the source account (if used).
    public var sourceAccountMuxed:String?

    /// ID of the multiplexed source account (if used).
    public var sourceAccountMuxedId:String?

    /// Type of the operation as a human readable string.
    public var operationTypeString:String

    /// Type of the operation. See OperationType enum.
    public var operationType:OperationType

    /// Date when the operation was created.
    public var createdAt:Date

    /// Transaction hash containing this operation.
    public var transactionHash:String

    /// Indicates whether the transaction containing this operation was successful.
    public var transactionSuccessful:Bool

    /// The transaction containing this operation (included if requested via join parameter).
    public var transaction: TransactionResponse?
    
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
        operationType = OperationType(rawValue: Int32(typeIInt))!
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        transactionSuccessful = try values.decode(Bool.self, forKey: .transactionSuccessful)
        transaction = try values.decodeIfPresent(TransactionResponse.self, forKey: .transaction)
    }
}
