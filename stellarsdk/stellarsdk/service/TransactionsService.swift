//
//  TransactionsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum TransactionDetailsResponseEnum {
    case success(details: TransactionResponse)
    case failure(error: HorizonRequestError)
}

public enum TransactionPostResponseEnum {
    case success(details: SubmitTransactionResponse)
    case failure(error: HorizonRequestError)
}

public enum TransactionsChange {
    case allTransactions(cursor:String?)
    case transactionsForAccount(account:String, cursor:String?)
    case transactionsForLedger(ledger:String, cursor:String?)
}

public typealias TransactionDetailsResponseClosure = (_ response:TransactionDetailsResponseEnum) -> (Void)
public typealias TransactionPostResponseClosure = (_ response:TransactionPostResponseEnum) -> (Void)

public class TransactionsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()

    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getTransactions(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        let path = "/transactions"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        let path = "/accounts/" + accountId + "/transactions"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        let path = "/ledgers/" + ledger + "/transactions"
        getTransactions(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getTransactionDetails(transactionHash:String, response:@escaping TransactionDetailsResponseClosure) {
        let requestPath = "/transactions/" + transactionHash
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
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
    
    open func submitTransaction(transaction:Transaction, response:@escaping TransactionPostResponseClosure) throws {
        let envelope = try transaction.encodedEnvelope()
        postTransaction(transactionEnvelope:envelope, response: response)
    }
    
    open func postTransaction(transactionEnvelope:String, response:@escaping TransactionPostResponseClosure) {
        let requestPath = "/transactions"
        if let encoded = transactionEnvelope.urlEncoded {
            let data = ("tx=" + encoded).data(using: .utf8)
        
            serviceHelper.POSTRequestWithPath(path: requestPath, body: data) { (result) -> (Void) in
                switch result {
                case .success(let data):
                    do {
                        self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                        let transaction = try self.jsonDecoder.decode(SubmitTransactionResponse.self, from: data)
                        response(.success(details: transaction))
                    } catch {
                        response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                    }
                case .failure(let error):
                    response(.failure(error:error))
                }
            }
        } else {
            response(.failure(error: .parsingResponseFailed(message: "Failed to URL encode the xdr enveloper")))
        }
    }
    
    open func stream(for transactionsType:TransactionsChange) -> TransactionsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allTransactions(let cursor):
            subpath = "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .transactionsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .transactionsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = TransactionsStreamItem(baseURL: serviceHelper.baseURL, subpath:subpath)
        return streamItem
    }
    
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getTransactionsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    open func getTransactionsFromUrl(url:String, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transactions = try self.jsonDecoder.decode(PageResponse<TransactionResponse>.self, from: data)
                    response(.success(details: transactions))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
