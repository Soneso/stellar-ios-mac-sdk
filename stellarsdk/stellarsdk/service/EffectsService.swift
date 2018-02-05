//
//  EffectsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum EffectsResponseEnum {
    case success(details: EffectsResponse)
    case failure(error: EffectsError)
}

public typealias EffectsResponseClosure = (_ response:EffectsResponseEnum) -> (Void)

public class EffectsService: NSObject {
    let serviceHelper: ServiceHelper
    let effectsFactory = EffectsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getEffects(from pagingToken:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping EffectsResponseClosure) {
        let path = "/effects?"
        getEffects(onPath: path, from:pagingToken, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forAccount accountId:String, from pagingToken:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping EffectsResponseClosure) {
        let path = "/accounts/" + accountId + "/effects?"
        getEffects(onPath: path, from:pagingToken, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forLedger ledger:String, from pagingToken:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping EffectsResponseClosure) {
        let path = "/ledgers/" + ledger + "/effects?"
        getEffects(onPath: path, from:pagingToken, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forOperation operation:String, from pagingToken:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping EffectsResponseClosure) {
        let path = "/operations/" + operation + "/effects?"
        getEffects(onPath: path, from:pagingToken, order:order, limit:limit, response:response)
    }
    
    open func getEffects(forTransaction hash:String, from pagingToken:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping EffectsResponseClosure) {
        let path = "/transactions/" + hash + "/effects?"
        getEffects(onPath: path, from:pagingToken, order:order, limit:limit, response:response)
    }
    
    private func getEffects(onPath path:String, from pagingToken:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping EffectsResponseClosure) {
        var requestPath = path
        
        if let pagingToken = pagingToken {
            requestPath += "cursor=" + pagingToken
        }
        
        if let order = order {
            requestPath += "order=" + order.rawValue
        }
        
        if let limit = limit {
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
