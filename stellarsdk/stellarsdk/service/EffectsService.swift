//
//  EffectsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum AllEffectsResponseEnum {
    case success(details: AllEffectsResponse)
    case failure(error: EffectsError)
}

public typealias AllEffectsResponseClosure = (_ response:AllEffectsResponseEnum) -> (Void)

public class EffectsService: NSObject {
    let serviceHelper: ServiceHelper
    let effectsFactory = EffectsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getEffects(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllEffectsResponseClosure) {
        let path = "/effects?"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllEffectsResponseClosure) {
        let path = "/accounts/" + accountId + "/effects?"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllEffectsResponseClosure) {
        let path = "/ledgers/" + ledger + "/effects?"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forOperation operation:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllEffectsResponseClosure) {
        let path = "/operations/" + operation + "/effects?"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllEffectsResponseClosure) {
        let path = "/transactions/" + hash + "/effects?"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    private func getEffects(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllEffectsResponseClosure) {
        var requestPath = path
        var hasFirstParam = false
        
        if let cursor = cursor {
            requestPath += "cursor=" + cursor
            hasFirstParam = true;
        }
        
        if let order = order {
            if hasFirstParam {
                requestPath += "&"
            } else {
                hasFirstParam = true;
            }
            requestPath += "order=" + order.rawValue
        }
        
        if let limit = limit {
            if hasFirstParam {
                requestPath += "&"
            }
            requestPath += "limit=" + String(limit)
        }
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let effects = try self.effectsFactory.effectsFromResponseData(data: data)
                    response(.success(details: effects))
                } catch {
                    response(.failure(error: error as! EffectsError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .effectNotFound(response: message)))
                case .requestFailed(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .internalError(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .emptyResponse:
                    response(.failure(error: .requestFailed(response: "The response came back empty")))
                }
            }
        }
    }
}
