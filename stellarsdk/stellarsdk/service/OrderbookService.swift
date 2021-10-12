//
//  OrderbookService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum OrderbookResponseEnum {
    case success(details: OrderbookResponse)
    case failure(error: HorizonRequestError)
}

public enum OrderbookChange {
    case orderbook(sellingAssetType:String,
                   sellingAssetCode:String?,
                   sellingAssetIssuer:String?,
                   buyingAssetType:String,
                   buyingAssetCode:String?,
                   buyingAssetIssuer:String?,
                   limit:Int?,
                   cursor: String?)
}

/// A closure to be called with the response from an orderbook request
public typealias OrderbookResponseClosure = (_ response:OrderbookResponseEnum) -> (Void)

public class OrderbookService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getOrderbook(sellingAssetType:String, sellingAssetCode:String? = nil, sellingAssetIssuer:String? = nil, buyingAssetType:String, buyingAssetCode:String? = nil, buyingAssetIssuer:String? = nil, limit:Int? = nil, response:@escaping OrderbookResponseClosure) {
        
        var requestPath = "/order_book"
        var params = Dictionary<String,String>()
        params["selling_asset_type"] = sellingAssetType
        params["selling_asset_code"] = sellingAssetCode
        params["selling_asset_issuer"] = sellingAssetIssuer
        params["buying_asset_type"] = buyingAssetType
        params["buying_asset_code"] = buyingAssetCode
        params["buying_asset_issuer"] = buyingAssetIssuer
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getOrderbookFromUrl(url:serviceHelper.requestUrlWithPath(path: requestPath), response:response)
    }
    
    func getOrderbookFromUrl(url:String, response:@escaping OrderbookResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let orderbook = try self.jsonDecoder.decode(OrderbookResponse.self, from: data)
                    response(.success(details: orderbook))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    /// Allows to stream SSE events from horizon.
    /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events. This mode will keep the connection to horizon open and horizon will continue to return responses as ledgers close.
    ///
    open func stream(for orderbookType:OrderbookChange) -> OrderbookStreamItem {
        var subpath:String!
        switch orderbookType {
        case .orderbook(let sellingAssetType,
                        let sellingAssetCode,
                        let sellingAssetIssuer,
                        let buyingAssetType,
                        let buyingAssetCode,
                        let buyingAssetIssuer,
                        let limit,
                        let cursor):
            
            var params = Dictionary<String,String>()
            params["selling_asset_type"] = sellingAssetType
            params["selling_asset_code"] = sellingAssetCode
            params["selling_asset_issuer"] = sellingAssetIssuer
            params["buying_asset_type"] = buyingAssetType
            params["buying_asset_code"] = buyingAssetCode
            params["buying_asset_issuer"] = buyingAssetIssuer
            if let limit = limit { params["limit"] = String(limit) }
            params["cursor"] = cursor
            
            subpath = "/order_book"
            
            if let pathParams = params.stringFromHttpParameters(),
                pathParams.count > 0 {
                subpath += "?\(pathParams)"
            }
        }
    
        let streamItem = OrderbookStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
}

