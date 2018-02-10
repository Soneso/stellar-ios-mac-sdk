//
//  LedgersService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllLedgersResponseEnum {
    case success(details: AllLedgersResponse)
    case failure(error: HorizonRequestError)
}

public enum LedgerDetailsResponseEnum {
    case success(details: LedgerResponse)
    case failure(error: HorizonRequestError)
}

public typealias AllLedgersResponseClosure = (_ response:AllLedgersResponseEnum) -> (Void)
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
    
    open func getLedgers(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllLedgersResponseClosure) {
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
                    let ledgers = try self.jsonDecoder.decode(AllLedgersResponse.self, from: data)
                    response(.success(details: ledgers))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
