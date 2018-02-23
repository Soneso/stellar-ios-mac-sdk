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
    
    open func getLedger(sequenceNumber:String, response:@escaping LedgerDetailsResponseClosure) {
        let requestPath = "/ledgers/" + sequenceNumber
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let ledger = try self.jsonDecoder.decode(LedgerResponse.self, from: data)
                    response(.success(details: ledger))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    open func getLedgers(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<LedgerResponse>.ResponseClosure) {
        var requestPath = "/ledgers"
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getLedgersFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    open func getLedgersFromUrl(url:String, response:@escaping PageResponse<LedgerResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let ledgers = try self.jsonDecoder.decode(PageResponse<LedgerResponse>.self, from: data)
                    response(.success(details: ledgers))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
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
        
        let streamItem = LedgersStreamItem(baseURL: serviceHelper.baseURL, subpath:subpath)
        return streamItem
    }
    
}
