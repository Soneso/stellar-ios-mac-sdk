//
//  AssetsService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class AssetsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// This function calls the endpoint that represents all assets. It will give you all the assets in the system along with various statistics about each.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/assets-all.html "All Assets")
     
    /// This fuction responds with a page of assets. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter assetCode: Optional. Code of the Asset to filter by.
    /// - Parameter assetIssuer: Optional. Issuer of the Asset to filter by.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getAssets(for assetCode:String? = nil, assetIssuer:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<AssetResponse>.ResponseClosure) {
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
        
        getAssetsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    /// Loads assets for a given url if valid. E.g. for a "next" link from a PageResponse<AssetResponse> object.
    ///
    /// - Parameter url: The url to be used to load the assets.
    ///
    open func getAssetsFromUrl(url:String, response:@escaping PageResponse<AssetResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let assets = try self.jsonDecoder.decode(PageResponse<AssetResponse>.self, from: data)
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
