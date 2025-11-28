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

/// Callback closure for retrieving operation details from the Stellar network.
public typealias OperationDetailsResponseClosure = (_ response:OperationDetailsResponseEnum) -> (Void)

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
    
    /// Retrieves all operations from Horizon API with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(from:order:limit:includeFailed:join:)")
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves all operations from Horizon API with pagination support using async/await pattern.
    /// Returns paginated list of operations filtered by cursor, order, limit, and optional join parameter for related resources.
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific account with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(forAccount:from:order:limit:includeFailed:join:)")
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forAccount: accountId, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves operations for a specific account using async/await pattern.
    /// Returns paginated operations filtered by account ID, cursor, order, limit, and optional parameters for failed transactions and related resources.
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/accounts/" + accountId + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific claimable balance with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(forClaimableBalance:from:order:limit:includeFailed:join:)")
    open func getOperations(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forClaimableBalance: claimableBalanceId, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves operations for a specific claimable balance using async/await pattern. Supports both encoded and hex claimable balance IDs.
    /// Returns paginated operations filtered by claimable balance ID, cursor, order, limit, and optional parameters for failed transactions and related resources.
    open func getOperations(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        var id = claimableBalanceId
        if claimableBalanceId.hasPrefix("B"),
            let cid = try? claimableBalanceId.decodeClaimableBalanceIdToHex() {
            id = cid
        }
        let path = "/claimable_balances/" + id + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific ledger sequence with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(forLedger:from:order:limit:includeFailed:join:)")
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forLedger: ledger, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves operations for a specific ledger sequence using async/await pattern.
    /// Returns paginated operations filtered by ledger sequence number, cursor, order, limit, and optional parameters for failed transactions and related resources.
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific transaction hash with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(forTransaction:from:order:limit:includeFailed:join:)")
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forTransaction: hash, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves operations for a specific transaction hash using async/await pattern.
    /// Returns paginated operations filtered by transaction hash, cursor, order, limit, and optional parameters for failed transactions and related resources.
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/transactions/" + hash + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves operations for a specific liquidity pool with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(forLiquidityPool:from:order:limit:includeFailed:join:)")
    open func getOperations(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forLiquidityPool: liquidityPoolId, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves operations for a specific liquidity pool using async/await pattern. Supports both encoded and hex liquidity pool IDs.
    /// Returns paginated operations filtered by liquidity pool ID, cursor, order, limit, and optional parameters for failed transactions and related resources.
    open func getOperations(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        var lidHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L"), let idHex = try? liquidityPoolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let path = "/liquidity_pools/" + lidHex + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }

    /// Retrieves detailed information for a specific operation by ID. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperationDetails(operationId:includeFailed:join:)")
    open func getOperationDetails(operationId:String, includeFailed:Bool? = nil, join:String? = nil, response:@escaping OperationDetailsResponseClosure) {
        Task {
            let result = await getOperationDetails(operationId: operationId, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Retrieves detailed information for a specific operation by ID using async/await pattern.
    /// Returns operation details including type-specific data, with optional parameters for failed transactions and related resources.
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

    /// Internal helper method to retrieve operations from a specific path with pagination support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperations(onPath:from:order:limit:includeFailed:join:)")
    private func getOperations(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(onPath: path, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }

    /// Internal helper method to retrieve operations from a specific Horizon API path using async/await pattern.
    /// Constructs request URL with pagination and filter parameters, then fetches operations from the specified endpoint.
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

    /// Retrieves operations from a complete URL with pagination navigation support. Deprecated in favor of async/await version.
    @available(*, renamed: "getOperationsFromUrl(url:)")
    open func getOperationsFromUrl(url:String, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperationsFromUrl(url: url)
            response(result)
        }
    }

    /// Retrieves operations from a complete URL using async/await pattern. Useful for pagination navigation with next/prev links.
    /// Fetches and parses operations from the specified Horizon API URL, returning paginated results or error.
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
