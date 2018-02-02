//
//  AssetsService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum AssetsResponseEnum {
    case success(details: AssetsResponse)
    case failure(error: AssetsError)
}

public typealias AssetsResponseClosure = (_ response:AssetsResponseEnum) -> (Void)

public class AssetsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getAssets(from assetCode:String? = nil, assetIssuer:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AssetsResponseClosure) {
        var requestPath = "/assets?"
        
        if let assetCode = assetCode {
            requestPath += "asset_code=" + assetCode
        }
        
        if let assetIssuer = assetIssuer {
            requestPath += "asset_issuer=" + assetIssuer
        }
        
        if let cursor = cursor {
            requestPath += "cursor=" + cursor
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
                    let assets = try self.jsonDecoder.decode(AssetsResponse.self, from: data)
                    response(.success(details: assets))
                } catch {
                    response(.failure(error: error as! AssetsError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .assetsNotFound(response: message)))
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

