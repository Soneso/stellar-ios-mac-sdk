//
//  EffectsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class EffectsService: NSObject {
    let serviceHelper: ServiceHelper
    let effectsFactory = EffectsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getEffects(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/accounts/" + accountId + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/ledgers/" + ledger + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forOperation operation:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/operations/" + operation + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/transactions/" + hash + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    private func getEffects(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getEffectsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    open func getEffectsFromUrl(url:String, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let effects = try self.effectsFactory.effectsFromResponseData(data: data)
                    response(.success(details: effects))
                } catch {
                    response(.failure(error: error as! HorizonRequestError))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
