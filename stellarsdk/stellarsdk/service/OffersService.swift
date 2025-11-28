//
//  OffersService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Defines offer stream filter options for real-time DEX offer updates.
public enum OffersChange {
    /// Streams all offers filtered by asset pair, seller, or sponsor
    case allOffers(seller:String?,
                   sellingAssetType:String,
                   sellingAssetCode:String?,
                   sellingAssetIssuer:String?,
                   buyingAssetType:String,
                   buyingAssetCode:String?,
                   buyingAssetIssuer:String?,
                   sponsor:String?,
                   cursor:String?,
                   order:Order?)
    /// Streams offers created by the specified account
    case offersForAccount(account:String,
                          cursor:String?)
}

/// Result enum for offer details requests.
public enum OfferResponseEnum {
    /// Successfully retrieved offer details
    case success(details: OfferResponse)
    /// Failed to retrieve offer, contains error details
    case failure(error: HorizonRequestError)
}

/// Service for querying offer information from the Stellar Horizon API.
///
/// Offers represent open orders on the Stellar decentralized exchange (DEX). Each offer specifies
/// an amount and price to buy or sell an asset. Can query offers by account, asset pair, or sponsor.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get all offers for an account
/// let response = await sdk.offers.getOffers(forAccount: "GACCOUNT...")
/// switch response {
/// case .success(let page):
///     for offer in page.records {
///         print("Selling: \(offer.amount) \(offer.selling.assetCode ?? "XLM")")
///         print("Buying: \(offer.buying.assetCode ?? "XLM")")
///         print("Price: \(offer.price)")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - OrderbookService for orderbook snapshots
public class OffersService: @unchecked Sendable {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Retrieves all offers created by a specific account with optional pagination parameters.
    ///
    /// - Parameter accountId: The Stellar account ID of the offer creator
    /// - Parameter cursor: Optional paging token, specifying where to start returning records from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return. Default: 10, max: 200
    /// - Returns: PageResponse containing offers for the account or error
    open func getOffers(forAccount accountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<OfferResponse>.ResponseEnum {
        var requestPath = "/accounts/" + accountId + "/offers"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getOffersFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves all current offers, allowing filtering by seller, selling_asset or buying_asset.
    ///
    /// People on the Stellar network can make offers to buy or sell assets. This endpoint represents all the
    /// current offers. This function responds with a page of offers. Pages represent a subset of a larger
    /// collection of objects to avoid returning millions of records in a single request.
    ///
    /// - Parameter seller: Optional. Account ID of the offer creator.
    /// - Parameter sellingAssetType: Required. Type of the Asset being sold: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter sellingAssetCode: Required if selling_asset_type is not "native".
    /// - Parameter sellingAssetIssuer: Required if selling_asset_type is not "native".
    /// - Parameter buyingAssetType: Required. Type of the Asset being bought: "native", "credit_alphanum4", or "credit_alphanum12"
    /// - Parameter buyingAssetCode: Required if buying_asset_type is not "native".
    /// - Parameter buyingAssetIssuer: Required if buying_asset_type is not "native".
    /// - Parameter sponsor: Optional. Account ID of the sponsor.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, "asc" or "desc", ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    /// - Returns: PageResponse containing offers matching the filters or error
    ///
    /// See: [Stellar developer docs](https://developers.stellar.org)
    open func getOffers(seller:String?, sellingAssetType:String, sellingAssetCode:String? = nil, sellingAssetIssuer:String? = nil, buyingAssetType:String, buyingAssetCode:String? = nil, buyingAssetIssuer:String? = nil, sponsor:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<OfferResponse>.ResponseEnum {
        var requestPath = "/offers"
        
        var params = Dictionary<String,String>()
        params["seller"] = seller
        params["selling_asset_type"] = sellingAssetType
        params["selling_asset_code"] = sellingAssetCode
        params["selling_asset_issuer"] = sellingAssetIssuer
        params["buying_asset_type"] = buyingAssetType
        params["buying_asset_code"] = buyingAssetCode
        params["sponsor"] = sponsor
        params["buying_asset_issuer"] = buyingAssetIssuer
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getOffersFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Retrieves offers from a specific Horizon URL.
    ///
    /// Used for pagination. Pass URLs from PageResponse links (e.g., next, prev).
    ///
    /// - Parameter url: The complete URL to fetch offers from
    /// - Returns: PageResponse containing offers or error
    func getOffersFromUrl(url:String) async -> PageResponse<OfferResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let trades = try self.jsonDecoder.decode(PageResponse<OfferResponse>.self, from: data)
                return .success(page: trades)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// Streams real-time offer updates via Server-Sent Events from Horizon.
    ///
    /// - Parameter offersType: The filter specifying which offers to stream (all offers with filters, or by account)
    /// - Returns: OffersStreamItem for receiving streaming offer updates
    open func stream(for offersType:OffersChange) -> OffersStreamItem {
        var subpath:String!
        switch offersType {
        case .allOffers(let seller,
                        let sellingAssetType,
                        let sellingAssetCode,
                        let sellingAssetIssuer,
                        let buyingAssetType,
                        let buyingAssetCode,
                        let buyingAssetIssuer,
                        let sponsor,
                        let cursor,
                        let order):

            var params = Dictionary<String,String>()
            params["seller"] = seller
            params["selling_asset_type"] = sellingAssetType
            params["selling_asset_code"] = sellingAssetCode
            params["selling_asset_issuer"] = sellingAssetIssuer
            params["buying_asset_type"] = buyingAssetType
            params["buying_asset_code"] = buyingAssetCode
            params["buying_asset_issuer"] = buyingAssetIssuer
            params["sponsor"] = sponsor
            params["cursor"] = cursor
            params["order"] = order?.rawValue

            subpath = "/offers"

            if let pathParams = params.stringFromHttpParameters(),
                pathParams.count > 0 {
                subpath += "?\(pathParams)"
            }

        case .offersForAccount(let accountId,
                               let cursor):
            subpath = "/accounts/" + accountId + "/offers"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }

        let streamItem = OffersStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }

    /// Streams real-time trade updates for a specific offer via Server-Sent Events.
    ///
    /// - Parameter offerId: The ID of the Offer to stream trades for
    /// - Parameter cursor: Optional paging token, specifying where to start streaming from
    /// - Parameter order: Optional sort order - .ascending or .descending
    /// - Parameter limit: Optional maximum number of records to return
    /// - Returns: TradesStreamItem for receiving streaming trade updates
    open func streamTrades(forOffer offerId: String, cursor: String? = nil, order: Order? = nil, limit: Int? = nil) -> TradesStreamItem {
        var requestPath = "/offers/" + offerId + "/trades"

        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }

        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }

        let streamItem = TradesStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: requestPath))
        return streamItem
    }
    
    /// Provides information and links relating to a single offer.
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// - Parameter offerId: The ID of the Offer
    ///
    /// - Returns: OfferResponseEnum with offer details on success or error on failure
    ///
    open func getOfferDetails(offerId: String) async -> OfferResponseEnum {
        let result = await serviceHelper.GETRequestWithPath(path: "/offers/\(offerId)")
        switch result {
        case .success(let data):
            do {
                let responseMessage = try self.jsonDecoder.decode(OfferResponse.self, from: data)
                return .success(details:responseMessage)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }

        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// This endpoint represents all trades for a given offer and can be used in streaming mode.
    /// Streaming mode allows you to listen for new trades for this offer as they are added to the Stellar ledger.
    /// If called in streaming mode, Horizon will start at the earliest known trade unless a cursor is set, in which case it will start from that cursor.
    /// By setting the cursor value to now, you can stream trades created since your request time.
    ///
    /// See [Stellar developer docs](https://developers.stellar.org)
    ///
    /// - Parameter offerId: The ID of the Offer
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, "asc" or "desc", ordered by ledger sequence number.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    /// - Returns: PageResponse containing trades for the offer or error
    ///
    open func getTrades(forOffer offerId: String, cursor: String? = nil, order: Order? = nil, limit: Int? = nil) async -> PageResponse<TradeResponse>.ResponseEnum {
        var requestPath = "/offers/" + offerId + "/trades"

        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }

        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }

        return await getTradesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }

    /// Retrieves trades from a specific Horizon URL.
    ///
    /// Used for pagination. Pass URLs from PageResponse links (e.g., next, prev).
    ///
    /// - Parameter url: The complete URL to fetch trades from
    /// - Returns: PageResponse containing trades or error
    func getTradesFromUrl(url: String) async -> PageResponse<TradeResponse>.ResponseEnum {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)

        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let trades = try jsonDecoder.decode(PageResponse<TradeResponse>.self, from: data)
                return .success(page: trades)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
}
