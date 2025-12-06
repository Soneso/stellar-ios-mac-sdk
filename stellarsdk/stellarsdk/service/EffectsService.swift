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
public class EffectsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let effectsFactory = EffectsFactory()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves all effects from the Stellar network with pagination support.
    ///
    /// Effects are the specific ways that the ledger was changed by any operation.
    /// This function responds with a page of effects. Pages represent a subset of a larger collection
    /// of objects to avoid returning millions of records in a single request.
    ///
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing effects or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getEffects(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves all effects that changed a specific account with pagination support.
    ///
    /// Returns relevant effects from the creation of the account to the current ledger.
    ///
    /// - Parameter accountId: The Stellar account ID
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing effects for the account or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getEffects(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/accounts/" + accountId + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves all effects that occurred in a specific ledger with pagination support.
    ///
    /// Effects are the specific ways that the ledger was changed by any operation.
    /// This function responds with a page of effects. Pages represent a subset of a larger collection
    /// of objects to avoid returning millions of records in a single request.
    ///
    /// - Parameter ledger: The Stellar ledger sequence number
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing effects for the ledger or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getEffects(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves all effects that occurred as a result of a specific operation with pagination support.
    ///
    /// This function responds with a page of effects. Pages represent a subset of a larger collection
    /// of objects to avoid returning millions of records in a single request.
    ///
    /// - Parameter operation: The Stellar operation ID
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing effects for the operation or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getEffects(forOperation operation:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/operations/" + operation + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves all effects that occurred as a result of a specific transaction with pagination support.
    ///
    /// This function responds with a page of effects. Pages represent a subset of a larger collection
    /// of objects to avoid returning millions of records in a single request.
    ///
    /// - Parameter hash: The transaction hash (hex-encoded)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing effects for the transaction or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getEffects(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        let path = "/transactions/" + hash + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Retrieves all effects that changed a specific liquidity pool with pagination support.
    ///
    /// - Parameter liquidityPoolId: The liquidity pool ID (L-address or hex format)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing effects for the liquidity pool or error
    open func getEffects(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<EffectResponse>.ResponseEnum {
        var lidHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L"), let idHex = try? liquidityPoolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let path = "/liquidity_pools/" + lidHex + "/effects"
        return await getEffects(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    /// Streams real-time effect updates via Server-Sent Events from Horizon.
    ///
    /// - Parameter transactionsType: The filter specifying which effects to stream (all, by account, ledger, operation, transaction, or liquidity pool)
    /// - Returns: EffectsStreamItem for receiving streaming effect updates
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
