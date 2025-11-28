//
//  TransactionsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for transaction details requests.
public enum TransactionDetailsResponseEnum {
    /// Successfully retrieved transaction details from Horizon.
    case success(details: TransactionResponse)
    /// Failed to retrieve transaction details due to a network or server error.
    case failure(error: HorizonRequestError)
}

/// Result enum for transaction submission requests.
///
/// Includes a special case for SEP-29 compliance when a destination requires a memo.
public enum TransactionPostResponseEnum {
    /// Successfully submitted transaction and received confirmation from Horizon.
    case success(details: SubmitTransactionResponse)
    /// Transaction rejected because destination account requires a memo per SEP-29.
    case destinationRequiresMemo(destinationAccountId: String)
    /// Failed to submit transaction due to a network, validation, or server error.
    case failure(error: HorizonRequestError)
}

/// Result enum for async transaction submission requests.
///
/// Async submission returns immediately after validation without waiting for ledger inclusion.
public enum TransactionPostAsyncResponseEnum {
    /// Successfully validated and queued transaction for async processing.
    case success(details: SubmitTransactionAsyncResponse)
    /// Transaction rejected because destination account requires a memo per SEP-29.
    case destinationRequiresMemo(destinationAccountId: String)
    /// Failed to validate or queue transaction due to a network or validation error.
    case failure(error: HorizonRequestError)
}

/// Result enum for SEP-29 memo requirement checks.
public enum CheckMemoRequiredResponseEnum {
    /// Destination accounts do not require memos per SEP-29.
    case noMemoRequired
    /// Destination account has config.memo_required set and requires a memo.
    case memoRequired(destination: String)
    /// Failed to check memo requirements due to a network or server error.
    case failure(error: HorizonRequestError)
}

/// Defines transaction stream filter options for real-time transaction updates.
public enum TransactionsChange {
    /// Streams all transactions from the network
    case allTransactions(cursor:String?)
    /// Streams transactions where the specified account is the source
    case transactionsForAccount(account:String, cursor:String?)
    /// Streams transactions affecting the specified claimable balance
    case transactionsForClaimableBalance(claimableBalanceId:String, cursor:String?)
    /// Streams transactions that occurred in the specified ledger
    case transactionsForLedger(ledger:String, cursor:String?)
}

/// Callback closure for retrieving transaction details from the Stellar network.
public typealias TransactionDetailsResponseClosure = (_ response:TransactionDetailsResponseEnum) -> (Void)
/// Callback closure for synchronous transaction submission operations.
public typealias TransactionPostResponseClosure = (_ response:TransactionPostResponseEnum) -> (Void)
/// Callback closure for asynchronous transaction submission operations.
public typealias TransactionPostAsyncResponseClosure = (_ response:TransactionPostAsyncResponseEnum) -> (Void)
/// Callback closure for checking if destination accounts require memos.
public typealias CheckMemoRequiredResponseClosure = (_ response:CheckMemoRequiredResponseEnum) -> (Void)

/// Service for querying and submitting transactions on the Stellar network.
///
/// The TransactionsService provides methods to retrieve transaction history, submit new
/// transactions to the network, and check SEP-29 memo requirements. Supports both synchronous
/// and asynchronous transaction submission modes.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get transaction details
/// let txResponse = await sdk.transactions.getTransactionDetails(
///     transactionHash: "abc123..."
/// )
///
/// // Submit a transaction
/// let submitResponse = await sdk.transactions.submitTransaction(
///     transaction: myTransaction
/// )
/// switch submitResponse {
/// case .success(let result):
///     print("Transaction successful: \(result.hash)")
/// case .destinationRequiresMemo(let accountId):
///     print("Destination \(accountId) requires a memo (SEP-29)")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [SEP-29 Memo Required](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)
public class TransactionsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves a paginated list of all transactions from Horizon.
    /// - Parameters:
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactions(cursor:order:limit:)")
    open func getTransactions(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Retrieves a paginated list of all transactions from Horizon using async/await.
    /// - Parameters:
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    /// - Returns: Page response containing transaction records or error.
    open func getTransactions(cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let path = "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves transactions for a specific account.
    /// - Parameters:
    ///   - accountId: The Stellar account ID to query transactions for.
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactions(forAccount:from:order:limit:)")
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forAccount: accountId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Retrieves transactions for a specific account using async/await.
    /// - Parameters:
    ///   - accountId: The Stellar account ID to query transactions for.
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    /// - Returns: Page response containing transaction records or error.
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum
    {
        let path = "/accounts/" + accountId + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves transactions for a specific claimable balance.
    /// - Parameters:
    ///   - claimableBalanceId: The claimable balance ID (hex or B-prefixed format).
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactions(forClaimableBalance:from:order:limit:)")
    open func getTransactions(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forClaimableBalance: claimableBalanceId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Retrieves transactions for a specific claimable balance using async/await.
    /// - Parameters:
    ///   - claimableBalanceId: The claimable balance ID (hex or B-prefixed format, auto-decoded).
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    /// - Returns: Page response containing transaction records or error.
    open func getTransactions(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        var id = claimableBalanceId
        if claimableBalanceId.hasPrefix("B"),
            let cid = try? claimableBalanceId.decodeClaimableBalanceIdToHex() {
            id = cid
        }
        let path = "/claimable_balances/" + id + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves transactions for a specific liquidity pool.
    /// - Parameters:
    ///   - liquidityPoolId: The liquidity pool ID (hex or L-prefixed format).
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactions(forLiquidityPool:from:order:limit:)")
    open func getTransactions(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forLiquidityPool: liquidityPoolId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Retrieves transactions for a specific liquidity pool using async/await.
    /// - Parameters:
    ///   - liquidityPoolId: The liquidity pool ID (hex or L-prefixed format, auto-decoded).
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    /// - Returns: Page response containing transaction records or error.
    open func getTransactions(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        var lidHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L"), let idHex = try? liquidityPoolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let path = "/liquidity_pools/" + lidHex + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves transactions for a specific ledger sequence.
    /// - Parameters:
    ///   - ledger: The ledger sequence number or "latest" for the most recent ledger.
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactions(forLedger:from:order:limit:)")
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forLedger: ledger, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Retrieves transactions for a specific ledger sequence using async/await.
    /// - Parameters:
    ///   - ledger: The ledger sequence number or "latest" for the most recent ledger.
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return (default 10, max 200).
    /// - Returns: Page response containing transaction records or error.
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves detailed information for a specific transaction by hash.
    /// - Parameters:
    ///   - transactionHash: The unique transaction hash identifier.
    ///   - response: Callback with transaction details or error.
    @available(*, renamed: "getTransactionDetails(transactionHash:)")
    open func getTransactionDetails(transactionHash:String, response:@escaping TransactionDetailsResponseClosure) {
        Task {
            let result = await getTransactionDetails(transactionHash: transactionHash)
            response(result)
        }
    }
    
    /// Retrieves detailed information for a specific transaction by hash using async/await.
    /// - Parameter transactionHash: The unique transaction hash identifier.
    /// - Returns: Transaction details or error.
    open func getTransactionDetails(transactionHash:String) async -> TransactionDetailsResponseEnum {
        let requestPath = "/transactions/" + transactionHash

        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let transaction = try self.jsonDecoder.decode(TransactionResponse.self, from: data)
                return .success(details: transaction)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    /// Submits a transaction to the Stellar network with optional SEP-29 memo validation.
    /// - Parameters:
    ///   - transaction: The signed transaction to submit.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    ///   - response: Callback with submission result, memo requirement notice, or error.
    @available(*, renamed: "submitTransaction(transaction:skipMemoRequiredCheck:)")
    open func submitTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await submitTransaction(transaction: transaction, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    /// Submits a transaction to the Stellar network with optional SEP-29 memo validation using async/await.
    /// - Parameters:
    ///   - transaction: The signed transaction to submit.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    /// - Returns: Submission result, memo requirement notice, or error.
    open func submitTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false) async -> TransactionPostResponseEnum {
        let envelope: String
        do {
            envelope = try transaction.encodedEnvelope()
        } catch {
            return .failure(error: .requestFailed(message: "could not encode transaction", horizonErrorResponse: nil))
        }
        return await postTransaction(transactionEnvelope: envelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
    }
    
    /// Submits a transaction asynchronously, returning immediately after validation without waiting for ledger inclusion.
    /// - Parameters:
    ///   - transaction: The signed transaction to submit.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    ///   - response: Callback with async submission result, memo requirement notice, or error.
    @available(*, renamed: "submitAsyncTransaction(transaction:skipMemoRequiredCheck:)")
    open func submitAsyncTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await submitAsyncTransaction(transaction: transaction, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    /// Submits a transaction asynchronously using async/await, returning immediately after validation.
    /// - Parameters:
    ///   - transaction: The signed transaction to submit.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    /// - Returns: Async submission result, memo requirement notice, or error.
    open func submitAsyncTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false) async -> TransactionPostAsyncResponseEnum {
        let envelope: String
        do {
            envelope = try transaction.encodedEnvelope()
        } catch {
            return .failure(error: .requestFailed(message: "could not encode transaction", horizonErrorResponse: nil))
        }
        return await postTransactionAsync(transactionEnvelope: envelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
    }
    
    /// Submits a fee-bump transaction to replace an existing transaction with higher fees.
    /// - Parameters:
    ///   - transaction: The signed fee-bump transaction to submit.
    ///   - response: Callback with submission result or error.
    @available(*, renamed: "submitFeeBumpTransaction(transaction:)")
    open func submitFeeBumpTransaction(transaction:FeeBumpTransaction, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await submitFeeBumpTransaction(transaction: transaction)
            response(result)
        }
    }
    
    /// Submits a fee-bump transaction using async/await to replace an existing transaction with higher fees.
    /// - Parameter transaction: The signed fee-bump transaction to submit.
    /// - Returns: Submission result or error.
    open func submitFeeBumpTransaction(transaction:FeeBumpTransaction) async -> TransactionPostResponseEnum {
        let envelope: String
        do {
            envelope = try transaction.encodedEnvelope()
        } catch {
            return .failure(error: .requestFailed(message: "could not encode fee bump transaction", horizonErrorResponse: nil))
        }
        return await postTransactionCore(transactionEnvelope: envelope)
    }
    
    /// Submits a fee-bump transaction asynchronously, returning immediately after validation.
    /// - Parameters:
    ///   - transaction: The signed fee-bump transaction to submit.
    ///   - response: Callback with async submission result or error.
    @available(*, renamed: "submitFeeBumpAsyncTransaction(transaction:)")
    open func submitFeeBumpAsyncTransaction(transaction:FeeBumpTransaction, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await submitFeeBumpAsyncTransaction(transaction: transaction)
            response(result)
        }
    }
    
    /// Submits a fee-bump transaction asynchronously using async/await, returning immediately after validation.
    /// - Parameter transaction: The signed fee-bump transaction to submit.
    /// - Returns: Async submission result or error.
    open func submitFeeBumpAsyncTransaction(transaction:FeeBumpTransaction) async -> TransactionPostAsyncResponseEnum {
        var envelope:String? = nil
        do {
            envelope = try transaction.encodedEnvelope()
        } catch {
            return .failure(error: .requestFailed(message: "could not encode transaction", horizonErrorResponse: nil))
        }
        return await postTransactionAsyncCore(transactionEnvelope: envelope!)
    }
    
    /// Posts a transaction envelope directly to Horizon with optional SEP-29 memo validation.
    /// - Parameters:
    ///   - transactionEnvelope: The base64-encoded transaction envelope XDR.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    ///   - response: Callback with submission result, memo requirement notice, or error.
    @available(*, renamed: "postTransaction(transactionEnvelope:skipMemoRequiredCheck:)")
    open func postTransaction(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await postTransaction(transactionEnvelope: transactionEnvelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    /// Posts a transaction envelope directly to Horizon with optional SEP-29 memo validation using async/await.
    /// - Parameters:
    ///   - transactionEnvelope: The base64-encoded transaction envelope XDR.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    /// - Returns: Submission result, memo requirement notice, or error.
    open func postTransaction(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false) async -> TransactionPostResponseEnum {
        if !skipMemoRequiredCheck, let transaction = try? Transaction(envelopeXdr: transactionEnvelope) {
            let checkMemoRequiredEnum = await checkMemoRequired(transaction: transaction)
            switch checkMemoRequiredEnum {
            case .noMemoRequired:
                return await postTransactionCore(transactionEnvelope: transactionEnvelope)
            case .memoRequired(let destination):
                return .destinationRequiresMemo(destinationAccountId: destination)
            case .failure(let error):
                return .failure(error: error)
            }
        } else {
            return await postTransactionCore(transactionEnvelope: transactionEnvelope)
        }
    }
    
    /// Posts a transaction envelope asynchronously, returning immediately after validation.
    /// - Parameters:
    ///   - transactionEnvelope: The base64-encoded transaction envelope XDR.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    ///   - response: Callback with async submission result, memo requirement notice, or error.
    @available(*, renamed: "postTransactionAsync(transactionEnvelope:skipMemoRequiredCheck:)")
    open func postTransactionAsync(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await postTransactionAsync(transactionEnvelope: transactionEnvelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    /// Posts a transaction envelope asynchronously using async/await, returning immediately after validation.
    /// - Parameters:
    ///   - transactionEnvelope: The base64-encoded transaction envelope XDR.
    ///   - skipMemoRequiredCheck: Set to true to bypass SEP-29 memo requirement validation.
    /// - Returns: Async submission result, memo requirement notice, or error.
    open func postTransactionAsync(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false) async -> TransactionPostAsyncResponseEnum {

        if !skipMemoRequiredCheck, let transaction = try? Transaction(envelopeXdr: transactionEnvelope) {
            let checkMemoRequiredEnum = await checkMemoRequired(transaction: transaction)
            switch checkMemoRequiredEnum {
            case .noMemoRequired:
                return await postTransactionAsyncCore(transactionEnvelope: transactionEnvelope)
            case .memoRequired(let destination):
                return .destinationRequiresMemo(destinationAccountId: destination)
            case .failure(let error):
                return .failure(error: error)
            }
        } else {
            return await postTransactionAsyncCore(transactionEnvelope: transactionEnvelope)
        }
    }
    
    /// Checks if a transaction requires a memo according to SEP-29 requirements.
    /// - Parameters:
    ///   - transaction: The transaction to validate for memo requirements.
    ///   - response: Callback indicating if memo is required, not required, or error.
    @available(*, renamed: "checkMemoRequired(transaction:)")
    private func checkMemoRequired(transaction: Transaction, response:@escaping CheckMemoRequiredResponseClosure) {
        Task {
            let result = await checkMemoRequired(transaction: transaction)
            response(result)
        }
    }
    
    /// Checks if a transaction requires a memo according to SEP-29 requirements using async/await.
    /// - Parameter transaction: The transaction to validate for memo requirements.
    /// - Returns: Indication if memo is required, not required, or error.
    private func checkMemoRequired(transaction: Transaction) async -> CheckMemoRequiredResponseEnum {
        if transaction.memo != Memo.none {
            return .noMemoRequired
        }

        var destinations = [String]()
        for operation in transaction.operations {

            var destination = ""
            if let paymentOp = operation as? PaymentOperation, paymentOp.destinationAccountId.hasPrefix("G") {
                destination = paymentOp.destinationAccountId
            } else if let paymentOp = operation as? PathPaymentOperation, paymentOp.destinationAccountId.hasPrefix("G") {
                destination = paymentOp.destinationAccountId
            } else if let accountMergeOp = operation as? AccountMergeOperation, accountMergeOp.destinationAccountId.hasPrefix("G") {
                destination = accountMergeOp.destinationAccountId
            }

            if destination.isEmpty || destinations.contains(destination) {
                continue
            }

            destinations.append(destination)
        }

        if (destinations.count == 0) {
            return .noMemoRequired
        }

        return await checkMemoRequiredForDestinations(destinations: destinations)
    }
    
    /// Recursively checks destination accounts for SEP-29 memo requirements.
    /// - Parameters:
    ///   - destinations: Array of destination account IDs to check.
    ///   - response: Callback indicating if memo is required, not required, or error.
    @available(*, renamed: "checkMemoRequiredForDestinations(destinations:)")
    private func checkMemoRequiredForDestinations(destinations: [String], response:@escaping CheckMemoRequiredResponseClosure) {
        Task {
            let result = await checkMemoRequiredForDestinations(destinations: destinations)
            response(result)
        }
    }
    
    /// Recursively checks destination accounts for SEP-29 memo requirements using async/await.
    /// - Parameter destinations: Array of destination account IDs to check.
    /// - Returns: Indication if memo is required, not required, or error.
    private func checkMemoRequiredForDestinations(destinations: [String]) async -> CheckMemoRequiredResponseEnum {

        var remainingDestinations = destinations
        if let firstDestination = remainingDestinations.first {
            let requestPath = "/accounts/\(firstDestination)"

            let result = await serviceHelper.GETRequestWithPath(path: requestPath)
            switch result {
            case .success(let data):
                do {
                    let accountDetails = try self.jsonDecoder.decode(AccountResponse.self, from: data)
                    // "MQ==" is the base64 encoding of "1".
                    if let value = accountDetails.data["config.memo_required"], value == "MQ==" {
                        return .memoRequired(destination: accountDetails.accountId)
                    } else {
                        remainingDestinations.removeFirst()
                        return await checkMemoRequiredForDestinations(destinations: remainingDestinations);
                    }
                } catch {
                    return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
                }

            case .failure(let error):
                switch error {
                case .notFound( _, _):
                    // account not found => no memo required for this account.
                    remainingDestinations.removeFirst()
                    return await checkMemoRequiredForDestinations(destinations: remainingDestinations);
                default:
                    return .failure(error:error)
                }
            }
        } else {
            return .noMemoRequired
        }
    }
    
    /// Core transaction submission to Horizon without SEP-29 validation.
    /// - Parameters:
    ///   - transactionEnvelope: The base64-encoded transaction envelope XDR.
    ///   - response: Callback with submission result or error.
    @available(*, renamed: "postTransactionCore(transactionEnvelope:)")
    private func postTransactionCore(transactionEnvelope:String, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await postTransactionCore(transactionEnvelope: transactionEnvelope)
            response(result)
        }
    }
    
    /// Core transaction submission to Horizon without SEP-29 validation using async/await.
    /// - Parameter transactionEnvelope: The base64-encoded transaction envelope XDR.
    /// - Returns: Submission result or error.
    private func postTransactionCore(transactionEnvelope:String) async -> TransactionPostResponseEnum {

        let requestPath = "/transactions"
        if let encoded = transactionEnvelope.urlEncoded {
            let data1 = ("tx=" + encoded).data(using: .utf8)

            let result = await serviceHelper.POSTRequestWithPath(path: requestPath, body: data1)
            switch result {
            case .success(let data):
                do {
                    //print("SUCCESS: " + String(data: data, encoding: .utf8)!)
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transaction = try self.jsonDecoder.decode(SubmitTransactionResponse.self, from: data)
                    return .success(details: transaction)
                } catch {
                    return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
                }
            case .failure(let error):
                return .failure(error:error)
            }
        } else {
            return .failure(error: .parsingResponseFailed(message: "Failed to URL encode the xdr enveloper"))
        }
    }
    
    /// Core async transaction submission to Horizon without SEP-29 validation.
    /// - Parameters:
    ///   - transactionEnvelope: The base64-encoded transaction envelope XDR.
    ///   - response: Callback with async submission result or error.
    @available(*, renamed: "postTransactionAsyncCore(transactionEnvelope:)")
    private func postTransactionAsyncCore(transactionEnvelope:String, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await postTransactionAsyncCore(transactionEnvelope: transactionEnvelope)
            response(result)
        }
    }
    
    /// Core async transaction submission to Horizon without SEP-29 validation using async/await.
    /// - Parameter transactionEnvelope: The base64-encoded transaction envelope XDR.
    /// - Returns: Async submission result or error.
    private func postTransactionAsyncCore(transactionEnvelope:String) async -> TransactionPostAsyncResponseEnum {

        let requestPath = "/transactions_async"
        if let encoded = transactionEnvelope.urlEncoded {
            let data1 = ("tx=" + encoded).data(using: .utf8)

            let result = await serviceHelper.POSTRequestWithPath(path: requestPath, body: data1)
            switch result {
            case .success(let data):
                do {
                    //print("SUCCESS: " + String(data: data, encoding: .utf8)!)
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transaction = try self.jsonDecoder.decode(SubmitTransactionAsyncResponse.self, from: data)
                    return .success(details: transaction)
                } catch {
                    return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
                }
            case .failure(let error):
                var responseData:Data? = nil

                switch error {
                case .badRequest(let message, _):
                    responseData = message.data(using: .utf8)
                case .duplicate(let message, _):
                    responseData = message.data(using: .utf8)
                case .staleHistory(let message, _):
                    responseData = message.data(using: .utf8)
                default:
                    break
                }
                if let data = responseData {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    if let transaction = try? self.jsonDecoder.decode(SubmitTransactionAsyncResponse.self, from: data) {
                        return .success(details: transaction)
                    }
                }
                return .failure(error:error)
            }
        } else {
            return .failure(error: .parsingResponseFailed(message: "Failed to URL encode the xdr enveloper"))
        }
    }

    /// Streams real-time transaction updates via Server-Sent Events from Horizon.
    open func stream(for transactionsType:TransactionsChange) -> TransactionsStreamItem {
        var subpath: String
        switch transactionsType {
        case .allTransactions(let cursor):
            subpath = "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .transactionsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .transactionsForClaimableBalance(let claimableBalanceId, let cursor):
            var idHex = claimableBalanceId
            if claimableBalanceId.hasPrefix("B"),
                let cid = try? claimableBalanceId.decodeClaimableBalanceIdToHex() {
                idHex = cid
            }
            subpath = "/balances/" + idHex + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .transactionsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }

        let streamItem = TransactionsStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
    
    /// Internal method to retrieve transactions from a specific Horizon API path.
    /// - Parameters:
    ///   - path: The Horizon API path to query.
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return.
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactions(onPath:from:order:limit:)")
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(onPath: path, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Internal method to retrieve transactions from a specific Horizon API path using async/await.
    /// - Parameters:
    ///   - path: The Horizon API path to query.
    ///   - cursor: Optional cursor for pagination continuation.
    ///   - order: Optional sort order (ascending or descending by ledger sequence).
    ///   - limit: Optional maximum number of records to return.
    /// - Returns: Page response containing transaction records or error.
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        var requestPath = path

        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }

        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }

        return await getTransactionsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves transactions from a complete Horizon URL, useful for pagination navigation.
    /// - Parameters:
    ///   - url: The complete Horizon URL to fetch transactions from.
    ///   - response: Callback with paginated transaction results or error.
    @available(*, renamed: "getTransactionsFromUrl(url:)")
    open func getTransactionsFromUrl(url:String, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactionsFromUrl(url: url)
            response(result)
        }
    }
    
    /// Retrieves transactions from a complete Horizon URL using async/await, useful for pagination navigation.
    /// - Parameter url: The complete Horizon URL to fetch transactions from.
    /// - Returns: Page response containing transaction records or error.
    open func getTransactionsFromUrl(url:String) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let transactions = try self.jsonDecoder.decode(PageResponse<TransactionResponse>.self, from: data)
                return .success(page: transactions)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
