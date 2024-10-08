//
//  OffersService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum OffersChange {
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
    case offersForAccount(account:String,
                          cursor:String?)
}

public enum OfferResponseEnum {
    case success(details: OfferResponse)
    case failure(error: HorizonRequestError)
}

public typealias OfferResponseClosure = (_ response:OfferResponseEnum) -> (Void)

public class OffersService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    @available(*, renamed: "getOffers(forAccount:cursor:order:limit:)")
    open func getOffers(forAccount accountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OfferResponse>.ResponseClosure) {
        Task {
            let result = await getOffers(forAccount: accountId, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
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
    /// - Parameter sponsor: Optional. Account ID of the sponsor.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    @available(*, renamed: "getOffers(seller:sellingAssetType:sellingAssetCode:sellingAssetIssuer:buyingAssetType:buyingAssetCode:buyingAssetIssuer:sponsor:cursor:order:limit:)")
    open func getOffers(seller:String?, sellingAssetType:String, sellingAssetCode:String? = nil, sellingAssetIssuer:String? = nil, buyingAssetType:String, buyingAssetCode:String? = nil, buyingAssetIssuer:String? = nil, sponsor:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OfferResponse>.ResponseClosure) {
        Task {
            let result = await getOffers(seller: seller, sellingAssetType: sellingAssetType, sellingAssetCode: sellingAssetCode, sellingAssetIssuer: sellingAssetIssuer, buyingAssetType: buyingAssetType, buyingAssetCode: buyingAssetCode, buyingAssetIssuer: buyingAssetIssuer, sponsor: sponsor, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getOffersFromUrl(url:)")
    func getOffersFromUrl(url:String, response:@escaping PageResponse<OfferResponse>.ResponseClosure) {
        Task {
            let result = await getOffersFromUrl(url: url)
            response(result)
        }
    }
    
    
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
    
    /// Allows to stream SSE events from horizon.
    /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events. This mode will keep the connection to horizon open and horizon will continue to return responses as ledgers close.
    ///
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
    
    /// Provides information and links relating to a single offer.
    /// See [Horizon API] (https://developers.stellar.org/api/resources/offers/single/ "Offer Details")
    ///
    /// - Parameter offerId: The ID of the Offer
    /// - Parameter response: The closure to be called upon response.
    ///
    /// - Throws:
    ///     - 'HorizonRequestError.notFound' if there is no offer whose ID matches the 'offerId' parameter.
    ///     - other 'HorizonRequestError' errors depending on the error case.
    ///
    @available(*, renamed: "getOfferDetails(offerId:)")
    open func getOfferDetails(offerId: String, response: @escaping OfferResponseClosure) {
        Task {
            let result = await getOfferDetails(offerId: offerId)
            response(result)
        }
    }
    
    
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
}
