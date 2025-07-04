//
//  ClaimableBalancesService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum ClaimableBalanceDetailsResponseEnum {
    case success(details: ClaimableBalanceResponse)
    case failure(error: HorizonRequestError)
}

public typealias ClaimableBalanceDetailsResponseClosure = (_ response:ClaimableBalanceDetailsResponseEnum) -> (Void)

public class ClaimableBalancesService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    @available(*, renamed: "getClaimableBalance(balanceId:)")
    open func getClaimableBalance(balanceId:String, response:@escaping ClaimableBalanceDetailsResponseClosure) {
        Task {
            let result = await getClaimableBalance(balanceId: balanceId)
            response(result)
        }
    }
    
    
    open func getClaimableBalance(balanceId:String) async -> ClaimableBalanceDetailsResponseEnum {
        var idHex = balanceId
        if balanceId.hasPrefix("B"),
            let cid = try? balanceId.decodeClaimableBalanceIdToHex() {
            idHex = cid
        }
        let requestPath = "/claimable_balances/" + idHex
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let value = try self.jsonDecoder.decode(ClaimableBalanceResponse.self, from: data)
                return .success(details: value)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    @available(*, renamed: "getClaimableBalances(asset:cursor:order:limit:)")
    open func getClaimableBalances(asset:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
        Task {
            let result = await getClaimableBalances(asset: asset, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getClaimableBalances(asset:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        var requestPath = "/claimable_balances"
        
        var params = Dictionary<String,String>()
        params["asset"] = asset.toCanonicalForm()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getClaimableBalancesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getClaimableBalances(claimantAccountId:cursor:order:limit:)")
    open func getClaimableBalances(claimantAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
        Task {
            let result = await getClaimableBalances(claimantAccountId: claimantAccountId, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getClaimableBalances(claimantAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        var requestPath = "/claimable_balances"
        
        var params = Dictionary<String,String>()
        params["claimant"] = claimantAccountId
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getClaimableBalancesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getClaimableBalances(sponsorAccountId:cursor:order:limit:)")
    open func getClaimableBalances(sponsorAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
        Task {
            let result = await getClaimableBalances(sponsorAccountId: sponsorAccountId, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getClaimableBalances(sponsorAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        var requestPath = "/claimable_balances"
        
        var params = Dictionary<String,String>()
        params["sponsor"] = sponsorAccountId
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getClaimableBalancesFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getClaimableBalancesFromUrl(url:)")
    open func getClaimableBalancesFromUrl(url:String, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
        Task {
            let result = await getClaimableBalancesFromUrl(url: url)
            response(result)
        }
    }
    
    
    open func getClaimableBalancesFromUrl(url:String) async -> PageResponse<ClaimableBalanceResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                //print(String(data: data, encoding: .utf8)!)
                let values = try self.jsonDecoder.decode(PageResponse<ClaimableBalanceResponse>.self, from: data)
                return .success(page: values)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
