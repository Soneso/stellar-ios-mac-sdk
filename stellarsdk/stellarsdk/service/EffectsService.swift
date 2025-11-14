//
//  EffectsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Defines effect stream filter options for real-time effect updates.
public enum EffectsChange {
    /// Streams all effects from the network
    case allEffects(cursor:String?)
    /// Streams effects that changed the specified account
    case effectsForAccount(account:String, cursor:String?)
    /// Streams effects that occurred in the specified ledger
    case effectsForLedger(ledger:String, cursor:String?)
    /// Streams effects produced by the specified operation
    case effectsForOperation(operation:String, cursor:String?)
    /// Streams effects produced by the specified transaction
    case effectsForTransaction(transaction:String, cursor:String?)
    /// Streams effects affecting the specified liquidity pool
    case effectsForLiquidityPool(liquidityPool:String, cursor:String?)
}

/// Service for querying effects from the Stellar Horizon API.
///
/// Effects represent specific changes to the ledger caused by operations. Each operation
/// produces one or more effects. Examples include account created, account credited,
/// trustline created, signer added, etc.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get effects for an account
/// let response = await sdk.effects.getEffects(
///     forAccount: "GACCOUNT...",
///     limit: 20
/// )
/// switch response {
/// case .success(let page):
///     for effect in page.records {
///         print("Effect type: \(effect.effectType)")
///         if let credited = effect as? AccountCreditedEffectResponse {
///             print("Credited: \(credited.amount)")
///         }
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - EffectResponse for effect data structures
public class EffectsService: NSObject {
    let serviceHelper: ServiceHelper
    let effectsFactory = EffectsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// This function calls the endpoint that represents all effects.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getEffects(from:order:limit:)")
    open func getEffects(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// This function calls the endpoint that represents all effects.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// This function calls the endpoint represents all effects that changed a given account. It will return relevant effects from the creation of the account to the current ledger.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter accountId: Stellar account ID of the account.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getEffects(forAccount:from:order:limit:)")
    open func getEffects(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(forAccount: accountId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }

    /// Retrieves all effects that changed a specific account with pagination support.
    /// - Parameters:
    ///   - accountId: The Stellar account ID
    ///   - cursor: Pagination cursor for next page
    ///   - order: Sort order (.ascending or .descending)
    ///   - limit: Maximum number of records to return (default 10, max 200)
    /// - Returns: PageResponse containing effects for the account or error
    open func getEffects(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/accounts/" + accountId + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Effects are the specific ways that the ledger was changed by any operation. This function calls the endpoint that represents all effects that occurred in the given ledger.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter ledger: Stellar ledger ID of the ledger.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getEffects(forLedger:from:order:limit:)")
    open func getEffects(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(forLedger: ledger, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// Effects are the specific ways that the ledger was changed by any operation. This function calls the endpoint that represents all effects that occurred in the given ledger.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter ledger: Stellar ledger ID of the ledger.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// This function calls the endpoint that represents all effects that occurred as a result of a given operation.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter operation: Stellar operation ID of the operation.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getEffects(forOperation:from:order:limit:)")
    open func getEffects(forOperation operation:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(forOperation: operation, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// This function calls the endpoint that represents all effects that occurred as a result of a given operation.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter operation: Stellar operation ID of the operation.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forOperation operation:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/operations/" + operation + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// This function calls the endpoint that represents all effects that occurred as a result of a given transaction.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter hash: A transaction hash, hex-encoded.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getEffects(forTransaction:from:order:limit:)")
    open func getEffects(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(forTransaction: hash, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// This function calls the endpoint that represents all effects that occurred as a result of a given transaction.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter hash: A transaction hash, hex-encoded.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/transactions/" + hash + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// This function calls the endpoint represents all effects that changed a given liquidity pool.
    ///
    /// - Parameter liquidityPoolId: Liquidity Pool ID
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getEffects(forLiquidityPool:from:order:limit:)")
    open func getEffects(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(forLiquidityPool: liquidityPoolId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// This function calls the endpoint represents all effects that changed a given liquidity pool.
    ///
    /// - Parameter liquidityPoolId: Liquidity Pool ID
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        var lidHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L"), let idHex = try? liquidityPoolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let path = "/liquidity_pools/" + lidHex + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Streams real-time effect updates via Server-Sent Events from Horizon.
    open func stream(for transactionsType:EffectsChange) -> EffectsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allEffects(let cursor):
            subpath = "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForOperation(let operation, let cursor):
            subpath = "/operations/" + operation + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForTransaction(let transaction, let cursor):
            subpath = "/transactions/" + transaction + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForLiquidityPool(let liquidityPool, let cursor):
            var lidHex = liquidityPool
            if liquidityPool.hasPrefix("L"), let idHex = try? liquidityPool.decodeLiquidityPoolIdToHex() {
                lidHex = idHex
            }
            subpath = "/liquidity_pools/" + lidHex + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        let streamItem = EffectsStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
    
    /// Loads effects for a given url if valid. E.g. for a "next" link from a PageResponse<EffectResponse> object.
    ///
    /// - Parameter url: The url to be used to load the effects.
    ///
    @available(*, renamed: "getEffects(onPath:from:order:limit:)")
    private func getEffects(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffects(onPath: path, from: cursor, order: order, limit: limit)
            response(result)
        }
    }

    /// Internal method to retrieve effects from a specific path with pagination parameters.
    /// - Parameters:
    ///   - path: The request path for the effects endpoint
    ///   - cursor: Pagination cursor for next page
    ///   - order: Sort order (.ascending or .descending)
    ///   - limit: Maximum number of records to return
    /// - Returns: PageResponse containing effects or error
    private func getEffects(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getEffectsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }

    /// Loads effects from a specific URL with callback closure. Deprecated in favor of async/await version.
    @available(*, renamed: "getEffectsFromUrl(url:)")
    open func getEffectsFromUrl(url:String, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        Task {
            let result = await getEffectsFromUrl(url: url)
            response(result)
        }
    }

    /// Loads effects from a specific URL for pagination.
    /// - Parameter url: The complete URL to fetch effects from (typically from PageResponse links)
    /// - Returns: PageResponse containing effects or error
    open func getEffectsFromUrl(url:String) async -> PageResponse<EffectResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let effects = try self.effectsFactory.effectsFromResponseData(data: data)
                return .success(page: effects)
            } catch {
                return .failure(error: error as! HorizonRequestError)
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
