//
//  TransactionsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum TransactionsResponseEnum {
    case success(details: TransactionsResponse)
    case failure(error: TransactionsError)
}

public enum TransactionDetailsResponseEnum {
    case success(details: Transaction)
    case failure(error: TransactionsError)
}

public typealias TransactionsResponseClosure = (_ response:TransactionsResponseEnum) -> (Void)
public typealias TransactionDetailsResponseClosure = (_ response:TransactionDetailsResponseEnum) -> (Void)

public class TransactionsService: NSObject {
    let serviceHelper: ServiceHelper
    let transactionsFactory = TransactionsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getTransactions(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping TransactionsResponseClosure) {
        let path = "/transactions?"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping TransactionsResponseClosure) {
        let path = "/accounts/" + accountId + "/transactions?"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping TransactionsResponseClosure) {
        let path = "/ledgers/" + ledger + "/transactions?"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactionDetails(transactionHash:String, response:@escaping TransactionDetailsResponseClosure) {
        let requestPath = "/transactions/" + transactionHash
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let transaction = try self.transactionsFactory.transactionFromData(data: data)
                    response(.success(details: transaction))
                } catch {
                    response(.failure(error: error as! TransactionsError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .transactionNotFound(response: message)))
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
    
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping TransactionsResponseClosure) {
        var requestPath = path
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
                    let transactions = try self.transactionsFactory.transactionsFromResponseData(data: data)
                    response(.success(details: transactions))
                } catch {
                    response(.failure(error: error as! TransactionsError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .transactionNotFound(response: message)))
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
