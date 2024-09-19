//
//  LedgersService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerDetailsResponseEnum {
    case success(details: LedgerResponse)
    case failure(error: HorizonRequestError)
}

public enum LedgersChange {
    case allLedgers(cursor:String?)
}

public typealias LedgerDetailsResponseClosure = (_ response:LedgerDetailsResponseEnum) -> (Void)

public class LedgersService: NSObject {
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
    
    @available(*, renamed: "getLedger(sequenceNumber:)")
    open func getLedger(sequenceNumber:String, response:@escaping LedgerDetailsResponseClosure) {
        Task {
            let result = await getLedger(sequenceNumber: sequenceNumber)
            response(result)
        }
    }
    
    
    open func getLedger(sequenceNumber:String) async -> LedgerDetailsResponseEnum {
        let requestPath = "/ledgers/" + sequenceNumber
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let ledger = try self.jsonDecoder.decode(LedgerResponse.self, from: data)
                return .success(details: ledger)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    @available(*, renamed: "getLedgers(cursor:order:limit:)")
    open func getLedgers(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LedgerResponse>.ResponseClosure) {
        Task {
            let result = await getLedgers(cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getLedgers(cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<LedgerResponse>.ResponseEnum {
        var requestPath = "/ledgers"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getLedgersFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getLedgersFromUrl(url:)")
    open func getLedgersFromUrl(url:String, response:@escaping PageResponse<LedgerResponse>.ResponseClosure) {
        Task {
            let result = await getLedgersFromUrl(url: url)
            response(result)
        }
    }
    
    
    open func getLedgersFromUrl(url:String) async -> PageResponse<LedgerResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let ledgers = try self.jsonDecoder.decode(PageResponse<LedgerResponse>.self, from: data)
                return .success(page: ledgers)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    open func stream(for transactionsType:LedgersChange) -> LedgersStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allLedgers(let cursor):
            subpath = "/ledgers"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = LedgersStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
    
}
