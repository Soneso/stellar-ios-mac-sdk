//
//  LiquidityPoolsService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Result enum for liquidity pool details requests.
public enum LiquidityPoolDetailsResponseEnum {
    /// Successfully retrieved liquidity pool details from Horizon
    case success(details: LiquidityPoolResponse)
    /// Failed to retrieve liquidity pool details, contains error information
    case failure(error: HorizonRequestError)
}

/// Result enum for liquidity pool trades requests.
public enum LiquidityPoolTradesResponseEnum {
    /// Successfully retrieved liquidity pool trade history
    case success(details: LiquidityPoolTradesResponse)
    /// Failed to retrieve liquidity pool trades, contains error information
    case failure(error: HorizonRequestError)
}

/// Callback closure for retrieving liquidity pool details from the Stellar network.
public typealias LiquidityPoolDetailsResponseClosure = (_ response:LiquidityPoolDetailsResponseEnum) -> (Void)
/// Callback closure for retrieving liquidity pool trade history from the Stellar network.
public typealias LiquidityPoolTradesResponseClosure = (_ response:LiquidityPoolTradesResponseEnum) -> (Void)

/// Service for querying liquidity pools from the Stellar Horizon API.
///
/// Liquidity pools enable automated market making (AMM) on Stellar. Each pool contains
/// reserves of two assets and allows swapping between them at algorithmically determined prices.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get liquidity pool details
/// let response = await sdk.liquidityPools.getLiquidityPoolDetails(
///     liquidityPoolId: "L..."
/// )
/// switch response {
/// case .success(let pool):
///     print("Total shares: \(pool.totalShares)")
///     for reserve in pool.reserves {
///         print("\(reserve.asset): \(reserve.amount)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - LiquidityPoolDepositOperation and LiquidityPoolWithdrawOperation
public class LiquidityPoolsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Retrieves details for a specific liquidity pool by its ID.
    @available(*, renamed: "getLiquidityPool(poolId:)")
    open func getLiquidityPool(poolId:String, response:@escaping LiquidityPoolDetailsResponseClosure) {
        Task {
            let result = await getLiquidityPool(poolId: poolId)
            response(result)
        }
    }

    /// Retrieves details for a specific liquidity pool by its ID.
    open func getLiquidityPool(poolId:String) async -> LiquidityPoolDetailsResponseEnum {
        var lidHex = poolId
        if poolId.hasPrefix("L"), let idHex = try? poolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let requestPath = "/liquidity_pools/" + lidHex
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let value = try self.jsonDecoder.decode(LiquidityPoolResponse.self, from: data)
                return .success(details: value)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    /// Retrieves all liquidity pools with optional pagination parameters.
    @available(*, renamed: "getLiquidityPools(cursor:order:limit:)")
    open func getLiquidityPools(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        Task {
            let result = await getLiquidityPools(cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }

    /// Retrieves all liquidity pools with optional pagination parameters.
    open func getLiquidityPools(cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<LiquidityPoolResponse>.ResponseEnum {
        var requestPath = "/liquidity_pools"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getLiquidityPoolsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves liquidity pools filtered by reserve assets with optional pagination parameters.
    @available(*, renamed: "getLiquidityPools(reserveAssetA:reserveAssetB:cursor:order:limit:)")
    open func getLiquidityPools(reserveAssetA:Asset, reserveAssetB:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        Task {
            let result = await getLiquidityPools(reserveAssetA: reserveAssetA, reserveAssetB: reserveAssetB, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }

    /// Retrieves liquidity pools filtered by reserve assets with optional pagination parameters.
    open func getLiquidityPools(reserveAssetA:Asset, reserveAssetB:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<LiquidityPoolResponse>.ResponseEnum {
        var requestPath = "/liquidity_pools"
        
        var params = Dictionary<String,String>()
        params["reserves"] = reserveAssetA.toCanonicalForm() + "," + reserveAssetB.toCanonicalForm()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getLiquidityPoolsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves trade history for a specific liquidity pool.
    @available(*, renamed: "getLiquidityPoolTrades(poolId:)")
    open func getLiquidityPoolTrades(poolId:String, response:@escaping LiquidityPoolTradesResponseClosure) {
        Task {
            let result = await getLiquidityPoolTrades(poolId: poolId)
            response(result)
        }
    }

    /// Retrieves trade history for a specific liquidity pool.
    open func getLiquidityPoolTrades(poolId:String) async -> LiquidityPoolTradesResponseEnum {
        let requestPath = "/liquidity_pools/" + poolId + "/trades"
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let value = try self.jsonDecoder.decode(LiquidityPoolTradesResponse.self, from: data)
                return .success(details: value)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    /// Retrieves liquidity pools from a specific Horizon URL.
    @available(*, renamed: "getLiquidityPoolsFromUrl(url:)")
    open func getLiquidityPoolsFromUrl(url:String, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        Task {
            let result = await getLiquidityPoolsFromUrl(url: url)
            response(result)
        }
    }

    /// Retrieves liquidity pools from a specific Horizon URL.
    open func getLiquidityPoolsFromUrl(url:String) async -> PageResponse<LiquidityPoolResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                // print(String(data: data, encoding: .utf8)!)
                let values = try self.jsonDecoder.decode(PageResponse<LiquidityPoolResponse>.self, from: data)
                return .success(page: values)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
