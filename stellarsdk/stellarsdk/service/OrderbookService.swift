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

/// Service for querying orderbook information from the Stellar Horizon API.
///
/// The orderbook shows current bids and asks for a given asset pair on the Stellar DEX.
/// Provides a snapshot of available offers at different price levels.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get orderbook for USD/XLM
/// let response = await sdk.orderbook.getOrderbook(
///     sellingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
///     sellingAssetCode: "USD",
///     sellingAssetIssuer: "GISSUER...",
///     buyingAssetType: AssetTypeAsString.NATIVE,
///     limit: 20
/// )
/// switch response {
/// case .success(let orderbook):
///     print("Bids: \(orderbook.bids.count)")
///     print("Asks: \(orderbook.asks.count)")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Horizon Orderbook API](https://developers.stellar.org/api/horizon/reference/endpoints/orderbook-details)
/// - OffersService for individual offers
public class OrderbookService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    @available(*, renamed: "getOrderbook(sellingAssetType:sellingAssetCode:sellingAssetIssuer:buyingAssetType:buyingAssetCode:buyingAssetIssuer:limit:)")
    open func getOrderbook(sellingAssetType:String, sellingAssetCode:String? = nil, sellingAssetIssuer:String? = nil, buyingAssetType:String, buyingAssetCode:String? = nil, buyingAssetIssuer:String? = nil, limit:Int? = nil, response:@escaping OrderbookResponseClosure) {
        Task {
            let result = await getOrderbook(sellingAssetType: sellingAssetType, sellingAssetCode: sellingAssetCode, sellingAssetIssuer: sellingAssetIssuer, buyingAssetType: buyingAssetType, buyingAssetCode: buyingAssetCode, buyingAssetIssuer: buyingAssetIssuer, limit: limit)
            response(result)
        }
    }
    
    
    open func getOrderbook(sellingAssetType:String, sellingAssetCode:String? = nil, sellingAssetIssuer:String? = nil, buyingAssetType:String, buyingAssetCode:String? = nil, buyingAssetIssuer:String? = nil, limit:Int? = nil) async -> OrderbookResponseEnum {
        
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
        
        return await getOrderbookFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getOrderbookFromUrl(url:)")
    func getOrderbookFromUrl(url:String, response:@escaping OrderbookResponseClosure) {
        Task {
            let result = await getOrderbookFromUrl(url: url)
            response(result)
        }
    }
    
    
    func getOrderbookFromUrl(url:String) async -> OrderbookResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let orderbook = try self.jsonDecoder.decode(OrderbookResponse.self, from: data)
                return .success(details: orderbook)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
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

