//
//  EffectsService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum EffectsChange {
    case allEffects(cursor:String?)
    case effectsForAccount(account:String, cursor:String?)
    case effectsForLedger(ledger:String, cursor:String?)
    case effectsForOperation(operation:String, cursor:String?)
    case effectsForTransaction(transaction:String, cursor:String?)
}

/// Builds requests connected to effects.
public class EffectsService: NSObject {
    let serviceHelper: ServiceHelper
    let effectsFactory = EffectsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// This function calls the endpoint that represents all effects.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/effects-all.html "All Effects")
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /// This function calls the endpoint represents all effects that changed a given account. It will return relevant effects from the creation of the account to the current ledger.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/effects-for-account.html "Effects for Account")
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter accountId: Stellar account ID of the account.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/accounts/" + accountId + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /// Effects are the specific ways that the ledger was changed by any operation. This function calls the endpoint that represents all effects that occurred in the given ledger.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/effects-for-ledger.html "Effects for Ledger")
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter ledger: Stellar ledger ID of the ledger.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/ledgers/" + ledger + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /// This function calls the endpoint that represents all effects that occurred as a result of a given operation.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/effects-for-operation.html "Effects for Operation")
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter operation: Stellar operation ID of the operation.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forOperation operation:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/operations/" + operation + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /// This function calls the endpoint that represents all effects that occurred as a result of a given transaction.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/effects-for-transaction.html "Effects for Transaction")
    ///
    /// This fuction responds with a page of effects. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter hash: A transaction hash, hex-encoded.
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getEffects(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        let path = "/transactions/" + hash + "/effects"
        getEffects(onPath: path, from:cursor, order:order, limit:limit, response:response)
    }
    
    /// Allows to stream SSE events from horizon.
    /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events. This mode will keep the connection to horizon open and horizon will continue to return responses as ledgers close.
    ///
    open func stream(for transactionsType:EffectsChange) -> EffectsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allEffects(let cursor):
            subpath = "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForOperation(let operation, let cursor):
            subpath = "/operations/" + operation + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .effectsForTransaction(let transaction, let cursor):
            subpath = "/transactions/" + transaction + "/effects"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = EffectsStreamItem(baseURL: serviceHelper.baseURL, subpath:subpath)
        return streamItem
    }
    
    /// Loads effects for a given url if valid. E.g. for a "next" link from a PageResponse<EffectResponse> object.
    ///
    /// - Parameter url: The url to be used to load the effects.
    ///
    private func getEffects(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getEffectsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    open func getEffectsFromUrl(url:String, response:@escaping PageResponse<EffectResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let effects = try self.effectsFactory.effectsFromResponseData(data: data)
                    response(.success(details: effects))
                } catch {
                    response(.failure(error: error as! HorizonRequestError))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
