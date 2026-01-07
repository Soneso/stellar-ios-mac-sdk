//
//  TradeAggregationsService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Service for querying aggregated trade statistics from the Stellar Horizon API.
///
/// Trade aggregations provide OHLCV (Open, High, Low, Close, Volume) candlestick data for
/// asset pairs over specified time intervals. Useful for charts and market analysis.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get hourly trade aggregations for the last 24 hours
/// let oneDayAgo = Int64(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
/// let now = Int64(Date().timeIntervalSince1970 * 1000)
///
/// let response = await sdk.tradeAggregations.getTradeAggregations(
///     startTime: oneDayAgo,
///     endTime: now,
///     resolution: 3600000, // 1 hour in milliseconds
///     baseAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
///     baseAssetCode: "USD",
///     baseAssetIssuer: "GISSUER...",
///     counterAssetType: AssetTypeAsString.NATIVE,
///     limit: 24
/// )
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TradesService for individual trade records
public class TradeAggregationsService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves aggregated trade statistics for an asset pair over a time interval.
    ///
    /// Returns OHLCV (Open, High, Low, Close, Volume) candlestick data for the specified trading pair.
    ///
    /// - Parameter startTime: Lower time boundary for the aggregations, in milliseconds since Unix epoch
    /// - Parameter endTime: Upper time boundary for the aggregations, in milliseconds since Unix epoch
    /// - Parameter resolution: The segment duration in milliseconds. Supported values: 1 minute (60000), 5 minutes (300000), 15 minutes (900000), 1 hour (3600000), 1 day (86400000), 1 week (604800000)
    /// - Parameter baseAssetType: Type of the base asset: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter baseAssetCode: Asset code of the base asset (required if not native)
    /// - Parameter baseAssetIssuer: Account ID of the base asset issuer (required if not native)
    /// - Parameter counterAssetType: Type of the counter asset: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter counterAssetCode: Asset code of the counter asset (required if not native)
    /// - Parameter counterAssetIssuer: Account ID of the counter asset issuer (required if not native)
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing trade aggregation records or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getTradeAggregations(startTime:Int64? = nil, endTime:Int64? = nil, resolution:Int64? = nil, baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TradeAggregationResponse>.ResponseEnum {

        var requestPath = "/trade_aggregations"
        var params = Dictionary<String,String>()
        if let start = startTime { params["start_time"] = String(start) }
        if let end = endTime { params["end_time"] = String(end) }
        if let res = resolution { params["resolution"] = String(res) }
        params["base_asset_type"] = baseAssetType
        params["base_asset_code"] = baseAssetCode
        params["base_asset_issuer"] = baseAssetIssuer
        params["counter_asset_type"] = counterAssetType
        params["counter_asset_code"] = counterAssetCode
        params["counter_asset_issuer"] = counterAssetIssuer
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }

        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }

        return await getTradeAggregationsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves trade aggregations from a specific Horizon URL.
    ///
    /// Useful for pagination with "next" or "prev" links from a PageResponse.
    ///
    /// - Parameter url: The complete URL to fetch trade aggregations from
    /// - Returns: PageResponse containing trade aggregation records or error
    open func getTradeAggregationsFromUrl(url:String) async -> PageResponse<TradeAggregationResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let tradeAggregations = try self.jsonDecoder.decode(PageResponse<TradeAggregationResponse>.self, from: data)
                return .success(page: tradeAggregations)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
