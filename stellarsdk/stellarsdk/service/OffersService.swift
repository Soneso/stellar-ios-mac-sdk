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
    
    /// People on the Stellar network can make offers to buy or sell assets. This endpoint represents all the current offers, allowing filtering by seller, selling_asset or buying_asset.
    
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/offers.html "Offers")
    
    /// This fuction responds with a page of accounts. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter seller: Optional. Account ID of the offer creator.
    /// - Parameter sellingAssetType: Required. Type of the Asset being sold e.g."native" or "credit_alphanum4" or "credit_alphanum12"
    /// - Parameter sellingAssetCode: Required if selling_asset_type is not "native".
    /// - Parameter sellingAssetIssuer: Required if selling_asset_type is not "native".
    /// - Parameter buyingAssetType: Required. Type of the Asset being bought e.g."native" or "credit_alphanum4" or "credit_alphanum12"
    /// - Parameter buyingAssetCode: Required if buying_asset_type is not "native".
    /// - Parameter buyingAssetIssuer: Required if buying_asset_type is not "native".
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getOffers(seller:String?, sellingAssetType:String, sellingAssetCode:String? = nil, sellingAssetIssuer:String? = nil, buyingAssetType:String, buyingAssetCode:String? = nil, buyingAssetIssuer:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OfferResponse>.ResponseClosure) {
        var requestPath = "/offers"
        
        var params = Dictionary<String,String>()
        params["seller"] = seller
        params["selling_asset_type"] = sellingAssetType
        params["selling_asset_code"] = sellingAssetCode
        params["selling_asset_issuer"] = sellingAssetIssuer
        params["buying_asset_type"] = buyingAssetType
        params["buying_asset_code"] = buyingAssetCode
        params["buying_asset_issuer"] = buyingAssetIssuer
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
