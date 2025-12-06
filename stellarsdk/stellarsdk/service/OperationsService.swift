//
//  OperationsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for operation details requests.
public enum OperationDetailsResponseEnum {
    /// Successfully retrieved operation details from Horizon.
    case success(details: OperationResponse)
    /// Failed to retrieve operation details due to a network or server error.
    case failure(error: HorizonRequestError)
}

/// Defines operation stream filter options for real-time operation updates.
public enum OperationsChange {
    /// Streams all operations from the network
    case allOperations(cursor:String?)
    /// Streams operations where the specified account is the source
    case operationsForAccount(account:String, cursor:String?)
    /// Streams operations affecting the specified claimable balance
    case operationsForClaimableBalance(claimableBalanceId:String, cursor:String?)
    /// Streams operations that occurred in the specified ledger
    case operationsForLedger(ledger:String, cursor:String?)
    /// Streams operations that are part of the specified transaction
    case operationsForTransaction(transaction:String, cursor:String?)
    /// Streams operations affecting the specified liquidity pool
    case operationsForLiquidityPool(liquidityPoolId:String, cursor:String?)
}


/// Service for querying operation history from the Stellar Horizon API.
///
/// The OperationsService provides methods to retrieve operations (individual actions within transactions)
/// filtered by account, ledger, transaction, claimable balance, or liquidity pool. Supports pagination
/// and streaming of real-time operation updates.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get operations for an account
/// let response = await sdk.operations.getOperations(
///     forAccount: "GACCOUNT...",
///     limit: 20,
///     order: .descending
/// )
/// switch response {
/// case .success(let page):
///     for operation in page.records {
///         print("Type: \(operation.operationType)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - OperationResponse for operation data structures
public class OperationsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let operationsFactory = OperationsFactory()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves all operations from Horizon API with pagination support.
    ///
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: PageResponse containing operations or error
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific account with pagination support.
    ///
    /// - Parameter accountId: The Stellar account ID to get operations for
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: PageResponse containing operations for the account or error
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/accounts/" + accountId + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific claimable balance with pagination support.
    ///
    /// Supports both encoded (B-prefixed) and hex claimable balance IDs.
    ///
    /// - Parameter claimableBalanceId: The claimable balance ID (B-address or hex format)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: PageResponse containing operations for the claimable balance or error
    open func getOperations(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        var id = claimableBalanceId
        if claimableBalanceId.hasPrefix("B"),
            let cid = try? claimableBalanceId.decodeClaimableBalanceIdToHex() {
            id = cid
        }
        let path = "/claimable_balances/" + id + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific ledger with pagination support.
    ///
    /// - Parameter ledger: The ledger sequence number
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: PageResponse containing operations for the ledger or error
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific transaction with pagination support.
    ///
    /// - Parameter hash: The transaction hash (hex-encoded)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: PageResponse containing operations for the transaction or error
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/transactions/" + hash + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific liquidity pool with pagination support.
    ///
    /// Supports both encoded (L-prefixed) and hex liquidity pool IDs.
    ///
    /// - Parameter liquidityPoolId: The liquidity pool ID (L-address or hex format)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: PageResponse containing operations for the liquidity pool or error
    open func getOperations(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        var lidHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L"), let idHex = try? liquidityPoolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let path = "/liquidity_pools/" + lidHex + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves detailed information for a specific operation by ID.
    ///
    /// Returns operation details including type-specific data.
    ///
    /// - Parameter operationId: The operation ID
    /// - Parameter includeFailed: Optional. Set to true to include failed operations
    /// - Parameter join: Optional. Set to "transactions" to include transaction data in response
    /// - Returns: OperationDetailsResponseEnum with operation details or error
    open func getOperationDetails(operationId:String, includeFailed:Bool? = nil, join:String? = nil) async -> OperationDetailsResponseEnum {
        var requestPath = "/operations/" + operationId
        
        var params = Dictionary<String,String>()
        if let isIncludeFailed = includeFailed, isIncludeFailed { params["include_failed"] = "true" }
        if let join = join { params["join"] = join }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let operation = try self.operationsFactory.operationFromData(data: data)
                return .success(details: operation)
            } catch {
                return .failure(error: error as! HorizonRequestError)
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// Streams real-time operation updates via Server-Sent Events from Horizon.
    ///
    /// - Parameter transactionsType: The filter specifying which operations to stream (all, by account, ledger, transaction, claimable balance, or liquidity pool)
    /// - Returns: OperationsStreamItem for receiving streaming operation updates
    open func stream(for transactionsType:OperationsChange) -> OperationsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allOperations(let cursor):
            subpath = "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForClaimableBalance(let claimableBalanceId, let cursor):
            var idHex = claimableBalanceId
            if claimableBalanceId.hasPrefix("B"),
                let cid = try? claimableBalanceId.decodeClaimableBalanceIdToHex() {
                idHex = cid
            }
            subpath = "/claimable_balances/" + idHex + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForTransaction(let transaction, let cursor):
            subpath = "/transactions/" + transaction + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForLiquidityPool(let liquidityPool, let cursor):
            var lidHex = liquidityPool
            if liquidityPool.hasPrefix("L"), let idHex = try? liquidityPool.decodeLiquidityPoolIdToHex() {
                lidHex = idHex
            }
            subpath = "/liquidity_pools/" + lidHex + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = OperationsStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }

    /// Internal helper method to retrieve operations from a specific Horizon API path.
    ///
    /// Constructs request URL with pagination and filter parameters, then fetches operations from the specified endpoint.
    ///
    /// - Parameter path: The API endpoint path
    /// - Parameter cursor: Optional paging token
    /// - Parameter order: Optional sort order
    /// - Parameter limit: Optional maximum records
    /// - Parameter includeFailed: Optional include failed flag
    /// - Parameter join: Optional join parameter
    /// - Returns: PageResponse containing operations or error
    private func getOperations(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
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
        
        return await getOperationsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }

    /// Retrieves operations from a complete URL.
    ///
    /// Useful for pagination navigation with next/prev links from PageResponse.
    ///
    /// - Parameter url: The complete URL to fetch operations from
    /// - Returns: PageResponse containing operations or error
    open func getOperationsFromUrl(url:String) async -> PageResponse<OperationResponse>.ResponseEnum {
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
}
