//
//  TradeAggregationsService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class TradeAggregationsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    @available(*, renamed: "getTradeAggregations(startTime:endTime:resolution:baseAssetType:baseAssetCode:baseAssetIssuer:counterAssetType:counterAssetCode:counterAssetIssuer:order:limit:)")
    open func getTradeAggregations(startTime:Int64? = nil, endTime:Int64? = nil, resolution:Int64? = nil, baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TradeAggregationResponse>.ResponseClosure) {
        Task {
            let result = await getTradeAggregations(startTime: startTime, endTime: endTime, resolution: resolution, baseAssetType: baseAssetType, baseAssetCode: baseAssetCode, baseAssetIssuer: baseAssetIssuer, counterAssetType: counterAssetType, counterAssetCode: counterAssetCode, counterAssetIssuer: counterAssetIssuer, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getTradeAggregations(startTime:Int64? = nil, endTime:Int64? = nil, resolution:Int64? = nil, baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TradeAggregationResponse>.ResponseEnum {
        
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
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getTradeAggregationsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getTradeAggregationsFromUrl(url:)")
    open func getTradeAggregationsFromUrl(url:String, response:@escaping PageResponse<TradeAggregationResponse>.ResponseClosure) {
        Task {
            let result = await getTradeAggregationsFromUrl(url: url)
            response(result)
        }
    }
    
    
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
