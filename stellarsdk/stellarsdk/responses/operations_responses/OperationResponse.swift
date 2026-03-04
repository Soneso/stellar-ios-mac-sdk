//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

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
