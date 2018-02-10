//
//  PaymentsService.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 10.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllPaymentsResponseEnum {
    case success(details: AllPaymentsResponse)
    case failure(error: HorizonRequestError)
}

public typealias AllPaymentsResponseClosure = (_ response:AllPaymentsResponseEnum) -> (Void)

public class PaymentsService: NSObject {
    let serviceHelper: ServiceHelper
    let operationsFactory = OperationsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /**
        This function responds with all payment operations that are part of validated transactions.
     
         - Parameter cursor: An optional paging token, specifying where to start returning records from.
         - Parameter order: The order in which to return rows, “asc” or “desc”.
         - Parameter limit: Maximum number of records to return default 10
     
        See also [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-all.html "All Payments")
     */
    open func getPayments(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllPaymentsResponseClosure) {
        let path = "/payments?"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /**
        This function responds with a collection of payment operations where the given account was either the sender or receiver.
     
        - Parameter accountId: The account id of the account used to constrain results.
        - Parameter cursor: An optional paging token, specifying where to start returning records from.
        - Parameter order: The order in which to return rows, “asc” or “desc”.
        - Parameter limit: Maximum number of records to return default 10
     
        See also [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-account.html "Payments for Account")
    */
    open func getPayments(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllPaymentsResponseClosure) {
        let path = "/accounts/" + accountId + "/payments?"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /**
        This function responds with all payment operations that are part of a valid transactions in a given ledger.
     
         - Parameter accountId: The ledger id of the ledger used to constrain results.
         - Parameter cursor: An optional paging token, specifying where to start returning records from.
         - Parameter order: The order in which to return rows, “asc” or “desc”.
         - Parameter limit: Maximum number of records to return default 10
     
        See also [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-ledger.html "Payments for Ledger")
    */
    open func getPayments(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllPaymentsResponseClosure) {
        let path = "/ledgers/" + ledger + "/payments?"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /**
        This function with all payment operations that are part of a given transaction.
     
         - Parameter hash: A transaction hash, hex-encoded.
         - Parameter cursor: An optional paging token, specifying where to start returning records from.
         - Parameter order: The order in which to return rows, “asc” or “desc”.
         - Parameter limit: Maximum number of records to return default 10
     
        See also [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-transaction.html "Payments for Transaction")
     */
    open func getPayments(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllPaymentsResponseClosure) {
        let path = "/transactions/" + hash + "/payments?"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    private func getPayments(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping AllPaymentsResponseClosure) {
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
                    let paymentsLinks = try AllPaymentsLinksResponse(operationsLinks: operations.links)
                    let payments = AllPaymentsResponse(payments: operations.operations, links: paymentsLinks)
                    response(.success(details: payments))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
