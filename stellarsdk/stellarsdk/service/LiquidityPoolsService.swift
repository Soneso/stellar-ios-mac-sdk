//
//  LiquidityPoolsService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum LiquidityPoolDetailsResponseEnum {
    case success(details: LiquidityPoolResponse)
    case failure(error: HorizonRequestError)
}

public enum LiquidityPoolTradesResponseEnum {
    case success(details: LiquidityPoolTradesResponse)
    case failure(error: HorizonRequestError)
}

public typealias LiquidityPoolDetailsResponseClosure = (_ response:LiquidityPoolDetailsResponseEnum) -> (Void)
public typealias LiquidityPoolTradesResponseClosure = (_ response:LiquidityPoolTradesResponseEnum) -> (Void)

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
    
    @available(*, renamed: "getLiquidityPool(poolId:)")
    open func getLiquidityPool(poolId:String, response:@escaping LiquidityPoolDetailsResponseClosure) {
        Task {
            let result = await getLiquidityPool(poolId: poolId)
            response(result)
        }
    }
    
    
    open func getLiquidityPool(poolId:String) async -> LiquidityPoolDetailsResponseEnum {
        let requestPath = "/liquidity_pools/" + poolId
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
    
    @available(*, renamed: "getLiquidityPools(cursor:order:limit:)")
    open func getLiquidityPools(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        Task {
            let result = await getLiquidityPools(cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getLiquidityPools(reserveAssetA:reserveAssetB:cursor:order:limit:)")
    open func getLiquidityPools(reserveAssetA:Asset, reserveAssetB:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        Task {
            let result = await getLiquidityPools(reserveAssetA: reserveAssetA, reserveAssetB: reserveAssetB, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getLiquidityPoolTrades(poolId:)")
    open func getLiquidityPoolTrades(poolId:String, response:@escaping LiquidityPoolTradesResponseClosure) {
        Task {
            let result = await getLiquidityPoolTrades(poolId: poolId)
            response(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getLiquidityPoolsFromUrl(url:)")
    open func getLiquidityPoolsFromUrl(url:String, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        Task {
            let result = await getLiquidityPoolsFromUrl(url: url)
            response(result)
        }
    }
    
    
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
