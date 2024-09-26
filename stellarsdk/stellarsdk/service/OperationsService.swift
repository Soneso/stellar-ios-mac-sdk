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
    case operationsForClaimableBalance(claimableBalanceId:String, cursor:String?)
    case operationsForLedger(ledger:String, cursor:String?)
    case operationsForTransaction(transaction:String, cursor:String?)
    case operationsForLiquidityPool(liquidityPoolId:String, cursor:String?)
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
    
    @available(*, renamed: "getOperations(from:order:limit:includeFailed:join:)")
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperations(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    @available(*, renamed: "getOperations(forAccount:from:order:limit:includeFailed:join:)")
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forAccount: accountId, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperations(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/accounts/" + accountId + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    @available(*, renamed: "getOperations(forClaimableBalance:from:order:limit:includeFailed:join:)")
    open func getOperations(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forClaimableBalance: claimableBalanceId, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperations(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/claimable_balances/" + claimableBalanceId + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    @available(*, renamed: "getOperations(forLedger:from:order:limit:includeFailed:join:)")
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forLedger: ledger, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperations(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    @available(*, renamed: "getOperations(forTransaction:from:order:limit:includeFailed:join:)")
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forTransaction: hash, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperations(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/transactions/" + hash + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    @available(*, renamed: "getOperations(forLiquidityPool:from:order:limit:includeFailed:join:)")
    open func getOperations(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(forLiquidityPool: liquidityPoolId, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperations(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        let path = "/liquidity_pools/" + liquidityPoolId + "/operations"
        return await getOperations(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join)
    }
    
    @available(*, renamed: "getOperationDetails(operationId:includeFailed:join:)")
    open func getOperationDetails(operationId:String, includeFailed:Bool? = nil, join:String? = nil, response:@escaping OperationDetailsResponseClosure) {
        Task {
            let result = await getOperationDetails(operationId: operationId, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    open func getOperationDetails(operationId:String, includeFailed:Bool? = nil, join:String? = nil) async -> OperationDetailsResponseEnum {
        var requestPath = "/operations/" + operationId
        
        var params = Dictionary<String,String>()
        if let isIncludeFailed = includeFailed, isIncludeFailed { params["include_failed"] = "true" }
        if let join = join { params["join"] = join }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let operation = try self.operationsFactory.operationFromData(data: data)
                return .success(details: operation)
            } catch {
                return .failure(error: error as! HorizonRequestError)
            }
        case .failure(let error):
            return .failure(error:error)
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
        case .operationsForClaimableBalance(let claimableBalanceId, let cursor):
            subpath = "/claimable_balances/" + claimableBalanceId + "/operations"
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
        case .operationsForLiquidityPool(let liquidityPool, let cursor):
            subpath = "/liquidity_pools/" + liquidityPool + "/operations"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = OperationsStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
    
    @available(*, renamed: "getOperations(onPath:from:order:limit:includeFailed:join:)")
    private func getOperations(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperations(onPath: path, from: cursor, order: order, limit: limit, includeFailed: includeFailed, join: join)
            response(result)
        }
    }
    
    
    private func getOperations(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil) async -> PageResponse<OperationResponse>.ResponseEnum {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        if let isIncludeFailed = includeFailed, isIncludeFailed { params["include_failed"] = "true" }
        if let join = join { params["join"] = join }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getOperationsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getOperationsFromUrl(url:)")
    open func getOperationsFromUrl(url:String, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        Task {
            let result = await getOperationsFromUrl(url: url)
            response(result)
        }
    }
    
    
    open func getOperationsFromUrl(url:String) async -> PageResponse<OperationResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let operations = try self.operationsFactory.operationsFromResponseData(data: data)
                return .success(page: operations)
            } catch {
                return .failure(error: error as! HorizonRequestError)
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
