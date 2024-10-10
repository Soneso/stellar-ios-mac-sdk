//
//  TradesService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/8/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum TradesChange {
    case allTrades(baseAssetType:String?,
                   baseAssetCode:String?,
                   baseAssetIssuer:String?,
                   counterAssetType:String?,
                   counterAssetCode:String?,
                   counterAssetIssuer:String?,
                   cursor:String?,
                   order:Order?,
                   limit: Int?)
    case tradesForAccount(account:String, cursor:String?)
}

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
    
    @available(*, renamed: "getTrades(baseAssetType:baseAssetCode:baseAssetIssuer:counterAssetType:counterAssetCode:counterAssetIssuer:offerId:tradeType:cursor:order:limit:)")
    open func getTrades(baseAssetType:String? = nil, baseAssetCode:String? = nil, baseAssetIssuer:String? = nil, counterAssetType:String? = nil, counterAssetCode:String? = nil, counterAssetIssuer:String? = nil, offerId:String? = nil, tradeType:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TradeResponse>.ResponseClosure) {
        Task {
            let result = await getTrades(baseAssetType: baseAssetType, baseAssetCode: baseAssetCode, baseAssetIssuer: baseAssetIssuer, counterAssetType: counterAssetType, counterAssetCode: counterAssetCode, counterAssetIssuer: counterAssetIssuer, offerId: offerId, tradeType: tradeType, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getTrades(forAccount:from:order:limit:)")
    open func getTrades(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TradeResponse>.ResponseClosure) {
        Task {
            let result = await getTrades(forAccount: accountId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getTradesFromUrl(url:)")
    func getTradesFromUrl(url:String, response:@escaping PageResponse<TradeResponse>.ResponseClosure) {
        Task {
            let result = await getTradesFromUrl(url: url)
            response(result)
        }
    }
    
    
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
    
    /// Allows to stream SSE events from horizon.
    /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events. This mode will keep the connection to horizon open and horizon will continue to return responses as ledgers close.
    ///
    open func stream(for tradesType:TradesChange) -> TradesStreamItem {
        var subpath:String!
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
