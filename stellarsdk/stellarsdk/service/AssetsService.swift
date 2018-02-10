//
//  AssetsService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllAssetsResponseEnum {
    case success(details: AllAssetsResponse)
    case failure(error: HorizonRequestError)
}

public typealias AllAssetsResponseClosure = (_ response:AllAssetsResponseEnum) -> (Void)

public class AssetsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getAssets(from assetCode:String? = nil, assetIssuer:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllAssetsResponseClosure) {
        var requestPath = "/assets"
        
        var params = Dictionary<String,String>()
        params["asset_code"] = assetCode
        params["asset_issuer"] = assetIssuer
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let assets = try self.jsonDecoder.decode(AllAssetsResponse.self, from: data)
                    response(.success(details: assets))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
