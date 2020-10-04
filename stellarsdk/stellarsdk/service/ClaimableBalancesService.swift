//
//  ClaimableBalancesService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation


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
    
    open func getClaimableBalance(balanceId:String, response:@escaping ClaimableBalanceDetailsResponseClosure) {
        let requestPath = "/claimable_balances/" + balanceId
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let value = try self.jsonDecoder.decode(ClaimableBalanceResponse.self, from: data)
                    response(.success(details: value))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    open func getClaimableBalances(asset:Asset, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
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
        
        getClaimableBalancesFromUrl(url:serviceHelper.requestUrlWithPath(path: requestPath), response:response)
    }
    
    open func getClaimableBalances(claimantAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
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
        
        getClaimableBalancesFromUrl(url:serviceHelper.requestUrlWithPath(path: requestPath), response:response)
    }
    
    open func getClaimableBalances(sponsorAccountId:String, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
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
        
        getClaimableBalancesFromUrl(url:serviceHelper.requestUrlWithPath(path: requestPath), response:response)
    }
    
    open func getClaimableBalancesFromUrl(url:String, response:@escaping PageResponse<ClaimableBalanceResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    print(String(data: data, encoding: .utf8)!)
                    let values = try self.jsonDecoder.decode(PageResponse<ClaimableBalanceResponse>.self, from: data)
                    response(.success(details: values))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
