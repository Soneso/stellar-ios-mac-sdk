//
//  PaymentsService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 10.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Defines payment stream filter options for real-time payment updates.
public enum PaymentsChange {
    /// Streams all payment operations from the network
    case allPayments(cursor:String?)
    /// Streams payments where the specified account is sender or receiver
    case paymentsForAccount(account:String, cursor:String?)
    /// Streams payments that occurred in the specified ledger
    case paymentsForLedger(ledger:String, cursor:String?)
    /// Streams payments that are part of the specified transaction
    case paymentsForTransaction(transaction:String, cursor:String?)
}

/// Service for querying payment operations from the Stellar Horizon API.
///
/// The PaymentsService provides methods to retrieve payment-related operations including
/// payments, path payments, create account operations, and account merges. These are the
/// operations that transfer value between accounts.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get payment history for an account
/// let response = await sdk.payments.getPayments(
///     forAccount: "GACCOUNT...",
///     limit: 50,
///     order: .descending
/// )
/// switch response {
/// case .success(let page):
///     for payment in page.records {
///         if let paymentOp = payment as? PaymentOperationResponse {
///             print("Amount: \(paymentOp.amount) \(paymentOp.assetCode ?? "XLM")")
///         }
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - OperationResponse for payment operation types
public class PaymentsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let operationsFactory = OperationsFactory()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves all payment operations that are part of validated transactions.
    ///
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, "asc" or "desc".
    /// - Parameter limit: Maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Set to true to include payments of failed transactions in results.
    /// - Parameter join: Set to "transactions" to include transaction data in response.
    /// - Returns: PageResponse containing payment operations or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getPayments(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/payments"
        return await getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    /// Retrieves payment operations where the given account was either the sender or receiver.
    ///
    /// - Parameter accountId: The Stellar account ID of the account used to constrain results.
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, "asc" or "desc".
    /// - Parameter limit: Maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Set to true to include payments of failed transactions in results.
    /// - Parameter join: Set to "transactions" to include transaction data in response.
    /// - Returns: PageResponse containing payment operations for the account or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getPayments(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/accounts/" + accountId + "/payments"
        return await getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    /// Retrieves all payment operations that are part of valid transactions in a given ledger.
    ///
    /// - Parameter ledger: The ledger sequence number used to constrain results.
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, "asc" or "desc".
    /// - Parameter limit: Maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Set to true to include payments of failed transactions in results.
    /// - Parameter join: Set to "transactions" to include transaction data in response.
    /// - Returns: PageResponse containing payment operations for the ledger or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getPayments(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/payments"
        return await getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    /// Retrieves all payment operations that are part of a given transaction.
    ///
    /// - Parameter hash: A transaction hash, hex-encoded.
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, "asc" or "desc".
    /// - Parameter limit: Maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Set to true to include payments of failed transactions in results.
    /// - Parameter join: Set to "transactions" to include transaction data in response.
    /// - Returns: PageResponse containing payment operations for the transaction or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getPayments(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/transactions/" + hash + "/payments"
        return await getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Internal helper method to retrieve payments for a specific Horizon endpoint path.
    ///
    /// - Parameter path: The API endpoint path
    /// - Parameter cursor: Optional paging token
    /// - Parameter order: Optional sort order
    /// - Parameter limit: Optional maximum records
    /// - Parameter includeFailed: Optional include failed flag
    /// - Parameter join: Optional join parameter
    /// - Returns: PageResponse containing payment operations or error
    private func getPayments(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        if let isIncludeFailed = includeFailed, isIncludeFailed { params["include_failed"] = "true" }
        if let join = join { params["join"] = join }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getPaymentsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Loads payments from a given URL.
    ///
    /// Useful for pagination with "next" or "prev" links from a PageResponse.
    ///
    /// - Parameter url: The URL to be used to load the payments.
    /// - Returns: PageResponse containing payment operations or error
    open func getPaymentsFromUrl(url:String) async -> PageResponse<OperationResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let operations = try self.operationsFactory.operationsFromResponseData(data: data)
                return .success(page: operations)
            } catch {
                return .failure(error: error as! HorizonRequestError)
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// Streams real-time payment operation updates via Server-Sent Events from Horizon.
    ///
    /// - Parameter transactionsType: The filter specifying which payments to stream (all, by account, ledger, or transaction)
    /// - Returns: OperationsStreamItem for receiving streaming payment updates
    open func stream(for transactionsType:PaymentsChange) -> OperationsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allPayments(let cursor):
            subpath = "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .paymentsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .paymentsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .paymentsForTransaction(let transaction, let cursor):
            subpath = "/transactions/" + transaction + "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
    
        let streamItem = OperationsStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
}
