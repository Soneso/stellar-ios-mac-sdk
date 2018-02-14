//
//  PathPaymentService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/14/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class PaymentPathsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getPaymentPaths(destinationAccount:String, destinationAssetType:String, destinationAssetCode:String? = nil, destinationAssetIssuer:String? = nil, destinationAmount:String, sourceAccount:String, response:@escaping PageResponse<PaymentPathResponse>.ResponseClosure) {
        
        var requestPath = "/paths"
        var params = Dictionary<String,String>()
        params["destination_account"] = destinationAccount
        params["destination_asset_type"] = destinationAssetType
        params["destination_asset_code"] = destinationAssetCode
        params["destination_asset_issuer"] = destinationAssetIssuer
        params["destination_amount"] = destinationAmount
        params["source_account"] = sourceAccount
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getPaymentPathsFrom(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    func getPaymentPathsFrom(url:String, response:@escaping PageResponse<PaymentPathResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let paymentPaths = try self.jsonDecoder.decode(PageResponse<PaymentPathResponse>.self, from: data)
                    response(.success(details: paymentPaths))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
