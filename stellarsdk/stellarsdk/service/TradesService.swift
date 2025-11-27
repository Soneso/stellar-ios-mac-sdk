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
public class TradesService: NSObject {
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
    
    /// Retrieves trades filtered by asset pair, offer ID, or trade type with optional pagination parameters.
    @available(*, renamed: "getTrades(baseAssetType:baseAssetCode:baseAssetIssuer:counterAssetType:counterAssetCode:counterAssetIssuer:offerId:tradeType:cursor:order:limit:)")
    open func getTrades(baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, offerId:String? = nil, tradeType:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TradeResponse>.ResponseClosure) {
        Task {
            let result = await getTrades(baseAssetType: baseAssetType, baseAssetCode: baseAssetCode, baseAssetIssuer: baseAssetIssuer, counterAssetType: counterAssetType, counterAssetCode: counterAssetCode, counterAssetIssuer: counterAssetIssuer, offerId: offerId, tradeType: tradeType, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }

    /// Retrieves trades filtered by asset pair, offer ID, or trade type with optional pagination parameters.
    open func getTrades(baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, offerId:String? = nil, tradeType:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TradeResponse>.ResponseEnum {
        
        var requestPath = "/trades"
        var params = Dictionary<String,String>()
        params["base_asset_type"] = baseAssetType
        params["base_asset_code"] = baseAssetCode
        params["base_asset_issuer"] = baseAssetIssuer
        params["counter_asset_type"] = counterAssetType
        params["counter_asset_code"] = counterAssetCode
        params["counter_asset_issuer"] = counterAssetIssuer
        params["offer_id"] = offerId
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
    @available(*, renamed: "getTrades(forAccount:from:order:limit:)")
    open func getTrades(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TradeResponse>.ResponseClosure) {
        Task {
            let result = await getTrades(forAccount: accountId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }

    /// Retrieves all trades for a specific account with optional pagination parameters.
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
    @available(*, renamed: "getTradesFromUrl(url:)")
    func getTradesFromUrl(url:String, response:@escaping PageResponse<TradeResponse>.ResponseClosure) {
        Task {
            let result = await getTradesFromUrl(url: url)
            response(result)
        }
    }

    /// Retrieves trades from a specific Horizon URL.
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
