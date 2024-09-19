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
    
    open func getLiquidityPool(poolId:String, response:@escaping LiquidityPoolDetailsResponseClosure) {
        let requestPath = "/liquidity_pools/" + poolId
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let value = try self.jsonDecoder.decode(LiquidityPoolResponse.self, from: data)
                    response(.success(details: value))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    open func getLiquidityPools(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        var requestPath = "/liquidity_pools"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getLiquidityPoolsFromUrl(url:serviceHelper.requestUrlWithPath(path: requestPath), response:response)
    }
    
    open func getLiquidityPools(reserveAssetA:Asset, reserveAssetB:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
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
        
        getLiquidityPoolsFromUrl(url:serviceHelper.requestUrlWithPath(path: requestPath), response:response)
    }
    
    open func getLiquidityPoolTrades(poolId:String, response:@escaping LiquidityPoolTradesResponseClosure) {
        let requestPath = "/liquidity_pools/" + poolId + "/trades"
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let value = try self.jsonDecoder.decode(LiquidityPoolTradesResponse.self, from: data)
                    response(.success(details: value))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    open func getLiquidityPoolsFromUrl(url:String, response:@escaping PageResponse<LiquidityPoolResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    // print(String(data: data, encoding: .utf8)!)
                    let values = try self.jsonDecoder.decode(PageResponse<LiquidityPoolResponse>.self, from: data)
                    response(.success(page: values))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
