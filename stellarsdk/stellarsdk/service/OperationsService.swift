//
//  OperationsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum OperationDetailsResponseEnum {
    case success(details: OperationResponse)
    case failure(error: HorizonRequestError)
}

public enum OperationsChange {
    case allOperations(cursor:String?)
    case operationsForAccount(account:String, cursor:String?)
    case operationsForLedger(ledger:String, cursor:String?)
    case operationsForTransaction(transaction:String, cursor:String?)
}

public typealias OperationDetailsResponseClosure = (_ response:OperationDetailsResponseEnum) -> (Void)

public class OperationsService: NSObject {
    let serviceHelper: ServiceHelper
    let operationsFactory = OperationsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/operations"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/accounts/" + accountId + "/operations"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/ledgers/" + ledger + "/operations"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/transactions/" + hash + "/operations"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperationDetails(operationId:String, response:@escaping OperationDetailsResponseClosure) {
        let requestPath = "/operations/" + operationId
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let operation = try self.operationsFactory.operationFromData(data: data)
                    response(.success(details: operation))
                } catch {
                    response(.failure(error: error as! HorizonRequestError))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    open func stream(for transactionsType:OperationsChange) -> OperationsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allOperations(let cursor):
            subpath = "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .operationsForTransaction(let transaction, let cursor):
            subpath = "/transactions/" + transaction + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = OperationsStreamItem(baseURL: serviceHelper.baseURL, subpath:subpath)
        return streamItem
    }
    
    private func getOperations(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getOperationsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    open func getOperationsFromUrl(url:String, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let operations = try self.operationsFactory.operationsFromResponseData(data: data)
                    response(.success(details: operations))
                } catch {
                    response(.failure(error: error as! HorizonRequestError))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
