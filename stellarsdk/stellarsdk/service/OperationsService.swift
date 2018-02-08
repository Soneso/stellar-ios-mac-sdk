//
//  OperationsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum AllOperationsResponseEnum {
    case success(details: AllOperationsResponse)
    case failure(error: OperationsError)
}

public enum OperationDetailsResponseEnum {
    case success(details: OperationResponse)
    case failure(error: OperationsError)
}

public typealias AllOperationsResponseClosure = (_ response:AllOperationsResponseEnum) -> (Void)
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
    
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllOperationsResponseClosure) {
        let path = "/operations?"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllOperationsResponseClosure) {
        let path = "/accounts/" + accountId + "/operations?"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllOperationsResponseClosure) {
        let path = "/ledgers/" + ledger + "/operations?"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllOperationsResponseClosure) {
        let path = "/transactions/" + hash + "/operations?"
        getOperations(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    open func getOperationDetails(operationId:String, response:@escaping OperationDetailsResponseClosure) {
        let requestPath = "/operations/" + operationId
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let operation = try self.operationsFactory.operationFromData(data: data)
                    response(.success(details: operation))
                } catch {
                    response(.failure(error: error as! OperationsError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .operationNotFound(response: message)))
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
    
    private func getOperations(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllOperationsResponseClosure) {
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
                    let operations = try self.operationsFactory.operationsFromResponseData(data: data)
                    response(.success(details: operations))
                } catch {
                    response(.failure(error: error as! OperationsError))
                }
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .operationNotFound(response: message)))
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
