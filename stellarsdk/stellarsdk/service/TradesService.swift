//
//  TradesService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/8/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Defines trade stream filter options for real-time DEX trade updates.
public enum TradesChange {
    /// Streams all trades filtered by base and counter asset pair
    case allTrades(baseAssetType:String?,
                   baseAssetCode:String?,
                   baseAssetIssuer:String?,
                   counterAssetType:String?,
                   counterAssetCode:String?,
                   counterAssetIssuer:String?,
                   cursor:String?,
                   order:Order?,
                   limit: Int?)
    /// Streams trades where the specified account participated
    case tradesForAccount(account:String, cursor:String?)
}

/// Service for querying trade history from the Stellar Horizon API.
///
/// Trades represent completed exchanges between two assets on the Stellar decentralized exchange.
/// Can filter trades by asset pair, account, offer, or liquidity pool.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get trades for a trading pair
/// let response = await sdk.trades.getTrades(
///     forAssetPair: (selling: Asset(canonicalForm: "USD:GISSUER...")!,
///                    buying: Asset(type: AssetType.ASSET_TYPE_NATIVE)!),
///     limit: 50
/// )
/// switch response {
/// case .success(let page):
///     for trade in page.records {
///         print("Price: \(trade.price)")
///         print("Amount: \(trade.baseAmount)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TradeAggregationsService for aggregated trade statistics
public class TradesService: @unchecked Sendable {
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
    
    /// Retrieves trades filtered by asset pair, offer ID, account, liquidity pool, or trade type with optional pagination parameters.
    ///
    /// - Parameter baseAssetType: Optional. Type of the base asset: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter baseAssetCode: Optional. Asset code of the base asset (required if base_asset_type is not "native")
    /// - Parameter baseAssetIssuer: Optional. Account ID of the base asset issuer (required if base_asset_type is not "native")
    /// - Parameter counterAssetType: Optional. Type of the counter asset: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter counterAssetCode: Optional. Asset code of the counter asset (required if counter_asset_type is not "native")
    /// - Parameter counterAssetIssuer: Optional. Account ID of the counter asset issuer (required if counter_asset_type is not "native")
    /// - Parameter offerId: Optional. Filter for trades involving a specific offer ID
    /// - Parameter forAccount: Optional. Filter for trades where the specified account participated
    /// - Parameter forLiquidityPool: Optional. Filter for trades from a specific liquidity pool (L-address or hex format)
    /// - Parameter tradeType: Optional. Filter by trade type: "all", "orderbook", or "liquidity_pool". Default: "all"
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing trade records or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getTrades(baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, offerId:String? = nil, forAccount:String? = nil, forLiquidityPool:String? = nil, tradeType:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TradeResponse>.ResponseEnum {

        var requestPath = "/trades"
        var params = Dictionary<String,String>()
        params["base_asset_type"] = baseAssetType
        params["base_asset_code"] = baseAssetCode
        params["base_asset_issuer"] = baseAssetIssuer
        params["counter_asset_type"] = counterAssetType
        params["counter_asset_code"] = counterAssetCode
        params["counter_asset_issuer"] = counterAssetIssuer
        params["offer_id"] = offerId
        params["account_id"] = forAccount

        var lidHex = forLiquidityPool
        if forLiquidityPool != nil && forLiquidityPool!.hasPrefix("L"),
            let id = try? forLiquidityPool!.decodeLiquidityPoolIdToHex() {
            lidHex = id
        }
        params["liquidity_pool_id"] = lidHex

        params["trade_type"] = tradeType
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }

        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }

        return await getTradesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves all trades for a specific account with optional pagination parameters.
    ///
    /// - Parameter accountId: The Stellar account ID to get trades for
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing trade records for the account or error
    open func getTrades(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TradeResponse>.ResponseEnum {
        var requestPath = "/accounts/" + accountId + "/trades"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getTradesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves trades from a specific Horizon URL.
    ///
    /// Useful for pagination with "next" or "prev" links from a PageResponse.
    ///
    /// - Parameter url: The complete URL to fetch trades from
    /// - Returns: PageResponse containing trade records or error
    func getTradesFromUrl(url:String) async -> PageResponse<TradeResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let trades = try self.jsonDecoder.decode(PageResponse<TradeResponse>.self, from: data)
                return .success(page: trades)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// Streams real-time trade updates via Server-Sent Events from Horizon.
    ///
    /// - Parameter tradesType: The filter specifying which trades to stream (all trades with asset filters, or trades for a specific account)
    /// - Returns: TradesStreamItem for receiving streaming trade updates
    open func stream(for tradesType:TradesChange) -> TradesStreamItem {
        var subpath: String
        switch tradesType {
        case .allTrades(let baseAssetType,
                        let baseAssetCode,
                        let baseAssetIssuer,
                        let counterAssetType,
                        let counterAssetCode,
                        let counterAssetIssuer,
                        let cursor,
                        let order,
                        let limit):
            
            var params = Dictionary<String,String>()
            params["base_asset_type"] = baseAssetType
            params["base_asset_code"] = baseAssetCode
            params["base_asset_issuer"] = baseAssetIssuer
            params["counter_asset_type"] = counterAssetType
            params["counter_asset_code"] = counterAssetCode
            params["counter_asset_issuer"] = counterAssetIssuer
            params["cursor"] = cursor
            params["order"] = order?.rawValue
            if let limit = limit { params["limit"] = String(limit) }
            
            subpath = "/trades"
            
            if let pathParams = params.stringFromHttpParameters(),
                pathParams.count > 0 {
                subpath += "?\(pathParams)"
            }
            
        case .tradesForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/trades"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
    
        let streamItem = TradesStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
}
