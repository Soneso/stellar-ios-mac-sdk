//
//  TransactionsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllTransactionsResponseEnum {
    case success(details: AllTransactionsResponse)
    case failure(error: HorizonRequestError)
}

public enum TransactionDetailsResponseEnum {
    case success(details: TransactionResponse)
    case failure(error: HorizonRequestError)
}

public typealias AllTransactionsResponseClosure = (_ response:AllTransactionsResponseEnum) -> (Void)
public typealias TransactionDetailsResponseClosure = (_ response:TransactionDetailsResponseEnum) -> (Void)

public class TransactionsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()

    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getTransactions(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllTransactionsResponseClosure) {
        let path = "/transactions?"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllTransactionsResponseClosure) {
        let path = "/accounts/" + accountId + "/transactions?"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllTransactionsResponseClosure) {
        let path = "/ledgers/" + ledger + "/transactions?"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactionDetails(transactionHash:String, response:@escaping TransactionDetailsResponseClosure) {
        let requestPath = "/transactions/" + transactionHash
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transaction = try self.jsonDecoder.decode(TransactionResponse.self, from: data)
                    response(.success(details: transaction))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllTransactionsResponseClosure) {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transactions = try self.jsonDecoder.decode(AllTransactionsResponse.self, from: data)
                    response(.success(details: transactions))
                }  catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
