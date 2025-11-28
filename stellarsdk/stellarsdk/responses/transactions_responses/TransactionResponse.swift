//
//  TransactionResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a transaction on the Stellar network with all its details and metadata.
///
/// Contains complete transaction information including operations, fees, signatures, source account,
/// and XDR-encoded transaction data. Returned when querying transaction details or lists from Horizon.
///
/// A transaction is a collection of operations that are atomically applied to the ledger.
/// If any operation fails, the entire transaction fails and no changes are made.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// let response = await sdk.transactions.getTransactionDetails(transactionHash: "abc123...")
/// switch response {
/// case .success(let tx):
///     print("Transaction Hash: \(tx.transactionHash)")
///     print("Source Account: \(tx.sourceAccount)")
///     print("Fee Charged: \(tx.feeCharged ?? "N/A") stroops")
///     print("Operations: \(tx.operationCount)")
///     print("Ledger: \(tx.ledger)")
///
///     if let memo = tx.memo {
///         print("Memo: \(memo)")
///     }
///
///     // Check if fee bump transaction
///     if let feeBump = tx.feeBumpTransactionResponse {
///         print("Fee Bump Hash: \(feeBump.transactionHash)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TransactionsService for querying transactions
public struct TransactionResponse: Decodable, Sendable {

    /// Navigation links related to this transaction (self, account, ledger, operations, effects, precedes, succeeds).
    public let links:TransactionLinksResponse

    /// Unique identifier for this transaction in Horizon's database.
    public let id:String

    /// Paging token for cursor-based pagination.
    public let pagingToken:String

    /// Hex-encoded SHA-256 hash of the transaction's XDR-encoded form. This is the transaction ID.
    public let transactionHash:String

    /// Ledger sequence number in which this transaction was included and applied.
    public let ledger:Int

    /// Timestamp when this transaction was included in the ledger (ISO 8601).
    public let createdAt:Date

    /// Account ID (public key) that originated this transaction.
    public let sourceAccount:String

    /// Multiplexed account address if the source account uses muxed accounts. Nil otherwise.
    public let sourceAccountMuxed:String?

    /// Muxed account ID component if the source account uses muxed accounts. Nil otherwise.
    public let sourceAccountMuxedId:String?

    /// Sequence number of the source account when this transaction was submitted.
    public let sourceAccountSequence:String

    /// Maximum fee (in stroops) the source account was willing to pay for this transaction.
    public let maxFee:String?

    /// Actual fee (in stroops) charged for this transaction. May be less than maxFee.
    public let feeCharged:String?

    /// Account that paid the transaction fee. Usually same as source account unless fee bump was used.
    public let feeAccount:String

    /// Multiplexed account address if the fee account uses muxed accounts. Nil otherwise.
    public let feeAccountMuxed:String?

    /// Muxed account ID component if the fee account uses muxed accounts. Nil otherwise.
    public let feeAccountMuxedId:String?

    /// Number of operations contained in this transaction.
    public let operationCount:Int

    /// Type of memo attached to this transaction: "none", "text", "id", "hash", or "return".
    public let memoType:String

    /// Parsed memo object. Nil for memo type "none".
    public let memo:Memo?

    /// Array of base64-encoded signatures (decorated signatures) for this transaction.
    public let signatures:[String]

    /// Complete transaction envelope containing the transaction and all signatures (XDR decoded).
    public let transactionEnvelope: TransactionEnvelopeXDR

    /// Result of transaction execution indicating success or specific error codes (XDR decoded).
    public let transactionResult: TransactionResultXDR

    /// Metadata about ledger state changes caused by this transaction (XDR decoded). Nil if not available.
    public let transactionMeta: TransactionMetaXDR?

    /// Metadata about ledger changes from paying the transaction fee (XDR decoded). Nil if not available.
    public let feeMeta: LedgerEntryChangesXDR?

    /// Details about the fee bump transaction if this transaction was wrapped in a fee bump. Nil otherwise.
    public let feeBumpTransactionResponse:FeeBumpTransactionResponse?

    /// Details about the inner transaction if this response is for a fee bump transaction. Nil otherwise.
    public let innerTransactionResponse:InnerTransactionResponse?

    /// Preconditions that must be met for this transaction to be valid (time bounds, ledger bounds, etc.). Nil if none.
    public let preconditions:TransactionPreconditionsResponse?
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case transactionHash = "hash"
        case ledger
        case createdAt = "created_at"
        case sourceAccount = "source_account"
        case sourceAccountMuxed = "source_account_muxed"
        case sourceAccountMuxedId = "source_account_muxed_id"
        case sourceAccountSequence = "source_account_sequence"
        case maxFee = "max_fee"
        case feeCharged = "fee_charged"
        case feeAccount = "fee_account"
        case feeAccountMuxed = "fee_account_muxed"
        case feeAccountMuxedId = "fee_account_muxed_id"
        case operationCount = "operation_count"
        case memoType = "memo_type"
        case memo = "memo"
        case signatures
        case envelopeXDR = "envelope_xdr"
        case transactionResult = "result_xdr"
        case transactionMeta = "result_meta_xdr"
        case feeMeta = "fee_meta_xdr"
        case feeBumpTransaction = "fee_bump_transaction"
        case innerTransaction = "inner_transaction"
        case preconditions = "preconditions"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(TransactionLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        ledger = try values.decode(Int.self, forKey: .ledger)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        sourceAccount = try values.decode(String.self, forKey: .sourceAccount)
        sourceAccountMuxed = try values.decodeIfPresent(String.self, forKey: .sourceAccountMuxed)
        sourceAccountMuxedId = try values.decodeIfPresent(String.self, forKey: .sourceAccountMuxedId)
        sourceAccountSequence = try values.decode(String.self, forKey: .sourceAccountSequence)
        feeAccount = try values.decode(String.self, forKey: .feeAccount)
        feeAccountMuxed = try values.decodeIfPresent(String.self, forKey: .feeAccountMuxed)
        feeAccountMuxedId = try values.decodeIfPresent(String.self, forKey: .feeAccountMuxedId)
        if let makeFeeStr = try? values.decodeIfPresent(String.self, forKey: .maxFee) {
            maxFee = makeFeeStr
        } else if let makeFeeInt = try? values.decodeIfPresent(Int.self, forKey: .maxFee) {
            maxFee = String(makeFeeInt)
        } else {
            maxFee = nil
        }
        if let feeChargedStr = try? values.decodeIfPresent(String.self, forKey: .feeCharged) {
            feeCharged = feeChargedStr
        } else if let feeChargedInt = try? values.decodeIfPresent(Int.self, forKey: .feeCharged) {
            feeCharged = String(feeChargedInt)
        } else {
            feeCharged = nil
        }
        operationCount = try values.decode(Int.self, forKey: .operationCount)
        memoType = try values.decode(String.self, forKey: .memoType)

        if memoType == "none" {
            memo = Memo.none
        } else {
            let memo = try values.decodeIfPresent(String.self, forKey: .memo)
            if memoType == "text" {
                try self.memo = Memo(text: memo ?? "")
            } else if memoType == "id" {
                if let m = memo, let memoId = UInt64(m) {
                    self.memo = .id(memoId)
                } else {
                    self.memo = nil
                }
            } else if memoType == "hash" {
                if let m = memo , let data = Data(base64Encoded: m) {
                    try self.memo = Memo(hash: data)
                } else {
                    self.memo = nil
                }
            } else if memoType == "return" {
                if let m = memo , let data = Data(base64Encoded: m) {
                    try self.memo = Memo(returnHash: data)
                } else {
                    self.memo = nil
                }
            } else {
                throw StellarSDKError.decodingError(message: "Unknown memo type.")
            }
        }
        
        signatures = try values.decode([String].self, forKey: .signatures)

        let encodedEnvelope = try values.decode(String.self, forKey: .envelopeXDR)
        guard let data = Data(base64Encoded: encodedEnvelope) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid base64 in envelope_xdr")
        }
        transactionEnvelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data:data)

        let encodedResult = try values.decode(String.self, forKey: .transactionResult)
        guard let resultData = Data(base64Encoded: encodedResult) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid base64 in result_xdr")
        }
        transactionResult = try XDRDecoder.decode(TransactionResultXDR.self, data:resultData)

        let encodedMeta = try values.decodeIfPresent(String.self, forKey: .transactionMeta)
        if let eMeta = encodedMeta, let metaData = Data(base64Encoded: eMeta) {
            transactionMeta = try? XDRDecoder.decode(TransactionMetaXDR.self, data:metaData)
        } else {
            transactionMeta = nil
        }

        let encodedFeeMeta = try values.decodeIfPresent(String.self, forKey: .feeMeta)
        if let feeMetaXdrStr = encodedFeeMeta {
            guard let feeMetaData = Data(base64Encoded: feeMetaXdrStr) else {
                throw HorizonRequestError.parsingResponseFailed(message: "Invalid base64 in fee_meta")
            }
            feeMeta = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data:feeMetaData)
        } else {
            feeMeta = nil
        }
        
        feeBumpTransactionResponse = try values.decodeIfPresent(FeeBumpTransactionResponse.self, forKey: .feeBumpTransaction)
        innerTransactionResponse = try values.decodeIfPresent(InnerTransactionResponse.self, forKey: .innerTransaction)
        preconditions = try values.decodeIfPresent(TransactionPreconditionsResponse.self, forKey: .preconditions)
    }
}
