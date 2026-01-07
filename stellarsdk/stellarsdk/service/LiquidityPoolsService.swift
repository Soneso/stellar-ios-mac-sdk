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
public class LiquidityPoolsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Retrieves details for a specific liquidity pool by its ID.
    ///
    /// - Parameter poolId: The liquidity pool ID (L-address or hex format)
    /// - Returns: LiquidityPoolDetailsResponseEnum with pool details or error
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
    
    /// Retrieves all liquidity pools with optional filtering and pagination parameters.
    ///
    /// - Parameter account: Optional account ID (G... address) to filter pools by participation.
    ///                      When provided, returns only liquidity pools the account participates in.
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing liquidity pools or error
    open func getLiquidityPools(account:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<LiquidityPoolResponse>.ResponseEnum {
        var requestPath = "/liquidity_pools"

        var params = Dictionary<String,String>()
        params["account"] = account
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
    ///
    /// - Parameter reserveAssetA: First reserve asset to filter by
    /// - Parameter reserveAssetB: Second reserve asset to filter by
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing liquidity pools matching the reserve assets or error
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
    
    /// Retrieves trade history for a specific liquidity pool with optional pagination parameters.
    ///
    /// - Parameter poolId: The liquidity pool ID (L-address or hex format)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: LiquidityPoolTradesResponseEnum with trade history or error
    open func getLiquidityPoolTrades(poolId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> LiquidityPoolTradesResponseEnum {
        var requestPath = "/liquidity_pools/" + poolId + "/trades"

        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }

        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }

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

    /// Streams real-time trade updates for a specific liquidity pool.
    ///
    /// Creates a Server-Sent Events (SSE) stream that delivers live trade updates as they occur
    /// on the Stellar network for the specified liquidity pool. The stream provides continuous
    /// updates until explicitly closed.
    ///
    /// Example usage:
    /// ```swift
    /// let sdk = StellarSDK()
    /// let poolId = "L..." // Liquidity pool ID (L-address or hex format)
    /// let tradesStream = sdk.liquidityPools.streamTrades(forPoolId: poolId)
    ///
    /// tradesStream.onReceive { response in
    ///     switch response {
    ///     case .open:
    ///         print("Stream opened")
    ///     case .response(id: let id, data: let trade):
    ///         print("New trade: \(trade.baseAmount) for \(trade.counterAmount)")
    ///     case .error(let error):
    ///         print("Error: \(error)")
    ///     }
    /// }
    ///
    /// // Close when done
    /// tradesStream.closeStream()
    /// ```
    ///
    /// - Parameter poolId: The liquidity pool ID (L-address or hex format)
    /// - Returns: LiquidityPoolTradesStreamItem for receiving live trade updates
    open func streamTrades(forPoolId poolId: String) -> LiquidityPoolTradesStreamItem {
        var lidHex = poolId
        if poolId.hasPrefix("L"), let idHex = try? poolId.decodeLiquidityPoolIdToHex() {
            lidHex = idHex
        }
        let requestPath = "/liquidity_pools/" + lidHex + "/trades"
        let streamUrl = serviceHelper.requestUrlWithPath(path: requestPath)
        return LiquidityPoolTradesStreamItem(requestUrl: streamUrl)
    }
    
    /// Retrieves liquidity pools from a specific Horizon URL.
    ///
    /// Used for pagination. Pass URLs from PageResponse links (e.g., next, prev).
    ///
    /// - Parameter url: The complete URL to fetch liquidity pools from
    /// - Returns: PageResponse containing liquidity pools or error
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
