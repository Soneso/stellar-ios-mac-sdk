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
        var requestPath = "/effects?"
        
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
