//
//  OffersService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class OffersService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getOffers(forAccount accountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OfferResponse>.ResponseClosure) {
        var requestPath = "/accounts/" + accountId + "/offers"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getOffersFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    func getOffersFromUrl(url:String, response:@escaping PageResponse<OfferResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let trades = try self.jsonDecoder.decode(PageResponse<OfferResponse>.self, from: data)
                    response(.success(details: trades))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
