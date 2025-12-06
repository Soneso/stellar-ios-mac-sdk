//
//  OrderbookService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for orderbook requests.
public enum OrderbookResponseEnum {
    /// Successful orderbook retrieval with bid and ask details.
    case success(details: OrderbookResponse)
    /// Request failed with Horizon error.
    case failure(error: HorizonRequestError)
}

/// Configuration for orderbook streaming filters.
public enum OrderbookChange {
    /// Stream orderbook updates for a specific trading pair.
    case orderbook(sellingAssetType:String,
                   sellingAssetCode:String?,
                   sellingAssetIssuer:String?,
                   buyingAssetType:String,
                   buyingAssetCode:String?,
                   buyingAssetIssuer:String?,
                   limit:Int?,
                   cursor: String?)
}

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
/// - [Stellar developer docs](https://developers.stellar.org)
/// - OffersService for individual offers
public class OrderbookService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves current orderbook bids and asks for a trading pair.
    ///
    /// - Parameter sellingAssetType: Type of the asset being sold: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter sellingAssetCode: Asset code if selling_asset_type is not "native"
    /// - Parameter sellingAssetIssuer: Asset issuer if selling_asset_type is not "native"
    /// - Parameter buyingAssetType: Type of the asset being bought: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter buyingAssetCode: Asset code if buying_asset_type is not "native"
    /// - Parameter buyingAssetIssuer: Asset issuer if buying_asset_type is not "native"
    /// - Parameter limit: Optional maximum number of bids/asks to return. Default: 20
    /// - Returns: OrderbookResponseEnum with bids and asks or error
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

    /// Loads orderbook data from a specific URL.
    ///
    /// - Parameter url: The complete URL to fetch the orderbook from
    /// - Returns: OrderbookResponseEnum with bids and asks or error
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

    /// Streams real-time orderbook updates via Server-Sent Events for a trading pair.
    ///
    /// - Parameter orderbookType: The orderbook configuration specifying the trading pair to stream
    /// - Returns: OrderbookStreamItem for receiving streaming orderbook updates
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

