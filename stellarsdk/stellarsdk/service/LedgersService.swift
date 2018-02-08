//
//  LedgersService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum LedgersResponseEnum {
    case success(details: LedgersResponse)
    case failure(error: LedgersError)
}

public enum LedgerDetailsResponseEnum {
    case success(details: Ledger)
    case failure(error: LedgersError)
}

public typealias LedgersResponseClosure = (_ response:LedgersResponseEnum) -> (Void)
public typealias LedgerDetailsResponseClosure = (_ response:LedgerDetailsResponseEnum) -> (Void)

public class LedgersService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getLedger(sequenceNumber:String, response:@escaping LedgerDetailsResponseClosure) {
        let requestPath = "/ledgers" + sequenceNumber
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let ledger = try self.jsonDecoder.decode(Ledger.self, from: data)
                    response(.success(details: ledger))
                } catch {
                    response(.failure(error: error as! LedgersError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .ledgersNotFound(response: message)))
                case .requestFailed(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .internalError(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .emptyResponse:
                    response(.failure(error: .requestFailed(response: "The response came back empty")))
                }
            }
        }
    }
    
    open func getLedgers(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping LedgersResponseClosure) {
        var requestPath = "/ledgers?"
        var hasFirstParam = false
        if let cursor = cursor {
            requestPath += "cursor=" + cursor
            hasFirstParam = true;
        }
        
        if let order = order {
            if hasFirstParam {
                requestPath += "&"
            } else {
                hasFirstParam = true;
            }
            requestPath += "order=" + order.rawValue
        }
        
        if let limit = limit {
            if hasFirstParam {
                requestPath += "&"
            }
            requestPath += "limit=" + String(limit)
        }
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let ledgers = try self.jsonDecoder.decode(LedgersResponse.self, from: data)
                    response(.success(details: ledgers))
                } catch {
                    // TODO DecodingError
                    response(.failure(error: error as! LedgersError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .ledgersNotFound(response: message)))
                case .requestFailed(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .internalError(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .emptyResponse:
                    response(.failure(error: .requestFailed(response: "The response came back empty")))
                }
            }
        }
    }
}


