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
    case destinationRequiresMemo(destinationAccountId: String)
    case failure(error: HorizonRequestError)
}

public enum TransactionPostAsyncResponseEnum {
    case success(details: SubmitTransactionAsyncResponse)
    case destinationRequiresMemo(destinationAccountId: String)
    case failure(error: HorizonRequestError)
}


public enum CheckMemoRequiredResponseEnum {
    case noMemoRequired
    case memoRequired(destination: String)
    case failure(error: HorizonRequestError)
}

public enum TransactionsChange {
    case allTransactions(cursor:String?)
    case transactionsForAccount(account:String, cursor:String?)
    case transactionsForClaimableBalance(claimableBalanceId:String, cursor:String?)
    case transactionsForLedger(ledger:String, cursor:String?)
}

public typealias TransactionDetailsResponseClosure = (_ response:TransactionDetailsResponseEnum) -> (Void)
public typealias TransactionPostResponseClosure = (_ response:TransactionPostResponseEnum) -> (Void)
public typealias TransactionPostAsyncResponseClosure = (_ response:TransactionPostAsyncResponseEnum) -> (Void)
public typealias CheckMemoRequiredResponseClosure = (_ response:CheckMemoRequiredResponseEnum) -> (Void)

public class TransactionsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    @available(*, renamed: "getTransactions(cursor:order:limit:)")
    open func getTransactions(cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getTransactions(cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let path = "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    @available(*, renamed: "getTransactions(forAccount:from:order:limit:)")
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forAccount: accountId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getTransactions(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum
    {
        let path = "/accounts/" + accountId + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    @available(*, renamed: "getTransactions(forClaimableBalance:from:order:limit:)")
    open func getTransactions(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forClaimableBalance: claimableBalanceId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getTransactions(forClaimableBalance claimableBalanceId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let path = "/claimable_balances/" + claimableBalanceId + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    @available(*, renamed: "getTransactions(forLiquidityPool:from:order:limit:)")
    open func getTransactions(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forLiquidityPool: liquidityPoolId, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    open func getTransactions(forLiquidityPool liquidityPoolId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let path = "/liquidity_pools/" + liquidityPoolId + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    @available(*, renamed: "getTransactions(forLedger:from:order:limit:)")
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(forLedger: ledger, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    open func getTransactions(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let path = "/ledgers/" + ledger + "/transactions"
        return await getTransactions(onPath: path, from:cursor, order:order, limit:limit)
    }
    
    @available(*, renamed: "getTransactionDetails(transactionHash:)")
    open func getTransactionDetails(transactionHash:String, response:@escaping TransactionDetailsResponseClosure) {
        Task {
            let result = await getTransactionDetails(transactionHash: transactionHash)
            response(result)
        }
    }
    
    
    open func getTransactionDetails(transactionHash:String) async -> TransactionDetailsResponseEnum {
        let requestPath = "/transactions/" + transactionHash
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let transaction = try self.jsonDecoder.decode(TransactionResponse.self, from: data)
                return .success(details: transaction)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
    
    @available(*, renamed: "submitTransaction(transaction:skipMemoRequiredCheck:)")
    open func submitTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await submitTransaction(transaction: transaction, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    
    open func submitTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false) async -> TransactionPostResponseEnum {
        let envelope = try! transaction.encodedEnvelope()
        return await postTransaction(transactionEnvelope: envelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
    }
    
    @available(*, renamed: "submitAsyncTransaction(transaction:skipMemoRequiredCheck:)")
    open func submitAsyncTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await submitAsyncTransaction(transaction: transaction, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    
    open func submitAsyncTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false) async -> TransactionPostAsyncResponseEnum {
        let envelope = try! transaction.encodedEnvelope()
        return await postTransactionAsync(transactionEnvelope: envelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
    }
    
    open func submitFeeBumpTransaction(transaction:FeeBumpTransaction, response:@escaping TransactionPostResponseClosure) throws {
        let envelope = try transaction.encodedEnvelope()
        //print(envelope)
        postTransactionCore(transactionEnvelope: envelope, response: { (result) -> (Void) in
            switch result {
            case .success(let transaction):
                response(.success(details: transaction))
            case .failure(let error):
                response(.failure(error: error))
            case .destinationRequiresMemo(let destinationAccountId):
                response(.destinationRequiresMemo(destinationAccountId: destinationAccountId))
            }
        })
    }
    
    open func submitFeeBumpAsyncTransaction(transaction:FeeBumpTransaction, response:@escaping TransactionPostAsyncResponseClosure) throws {
        let envelope = try transaction.encodedEnvelope()
        //print(envelope)
        postTransactionAsyncCore(transactionEnvelope: envelope, response: { (result) -> (Void) in
            switch result {
            case .success(let transaction):
                response(.success(details: transaction))
            case .failure(let error):
                response(.failure(error: error))
            case .destinationRequiresMemo(let destinationAccountId):
                response(.destinationRequiresMemo(destinationAccountId: destinationAccountId))
            }
        })
    }
    
    @available(*, renamed: "postTransaction(transactionEnvelope:skipMemoRequiredCheck:)")
    open func postTransaction(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await postTransaction(transactionEnvelope: transactionEnvelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    
    open func postTransaction(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false) async -> TransactionPostResponseEnum {
        
        if !skipMemoRequiredCheck, let transaction = try? Transaction(envelopeXdr: transactionEnvelope) {
            return await withCheckedContinuation { continuation in
                checkMemoRequired(transaction: transaction, response: { (result) -> (Void) in
                    switch result {
                    case .noMemoRequired:
                        self.postTransactionCore(transactionEnvelope: transactionEnvelope, response: { (result) -> (Void) in
                            switch result {
                            case .success(let transaction):
                                continuation.resume(returning: .success(details: transaction))
                            case .failure(let error):
                                continuation.resume(returning: .failure(error: error))
                            case .destinationRequiresMemo(let destinationAccountId):
                                continuation.resume(returning: .destinationRequiresMemo(destinationAccountId: destinationAccountId))
                            }
                        })
                    case .memoRequired(let accountId):
                        continuation.resume(returning: .destinationRequiresMemo(destinationAccountId: accountId))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error: error))
                    }
                })
            }
        } else {
            return await withCheckedContinuation { continuation in
                postTransactionCore(transactionEnvelope: transactionEnvelope, response: { (result) -> (Void) in
                    switch result {
                    case .success(let transaction):
                        continuation.resume(returning: .success(details: transaction))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error: error))
                    case .destinationRequiresMemo(let destinationAccountId):
                        continuation.resume(returning: .destinationRequiresMemo(destinationAccountId: destinationAccountId))
                    }
                })
            }
        }
    }
    
    @available(*, renamed: "postTransactionAsync(transactionEnvelope:skipMemoRequiredCheck:)")
    open func postTransactionAsync(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await postTransactionAsync(transactionEnvelope: transactionEnvelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
            response(result)
        }
    }
    
    
    open func postTransactionAsync(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false) async -> TransactionPostAsyncResponseEnum {
        
        if !skipMemoRequiredCheck, let transaction = try? Transaction(envelopeXdr: transactionEnvelope) {
            return await withCheckedContinuation { continuation in
                checkMemoRequired(transaction: transaction, response: { (result) -> (Void) in
                    switch result {
                    case .noMemoRequired:
                        self.postTransactionAsyncCore(transactionEnvelope: transactionEnvelope, response: { (result) -> (Void) in
                            switch result {
                            case .success(let transaction):
                                continuation.resume(returning: .success(details: transaction))
                            case .failure(let error):
                                continuation.resume(returning: .failure(error: error))
                            case .destinationRequiresMemo(let destinationAccountId):
                                continuation.resume(returning: .destinationRequiresMemo(destinationAccountId: destinationAccountId))
                            }
                        })
                    case .memoRequired(let accountId):
                        continuation.resume(returning: .destinationRequiresMemo(destinationAccountId: accountId))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error: error))
                    }
                })
            }
        } else {
            return await withCheckedContinuation { continuation in
                postTransactionAsyncCore(transactionEnvelope: transactionEnvelope, response: { (result) -> (Void) in
                    switch result {
                    case .success(let transaction):
                        continuation.resume(returning: .success(details: transaction))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error: error))
                    case .destinationRequiresMemo(let destinationAccountId):
                        continuation.resume(returning: .destinationRequiresMemo(destinationAccountId: destinationAccountId))
                    }
                })
            }
        }
    }
    
    
    @available(*, renamed: "checkMemoRequired(transaction:)")
    private func checkMemoRequired(transaction: Transaction, response:@escaping CheckMemoRequiredResponseClosure) {
        Task {
            let result = await checkMemoRequired(transaction: transaction)
            response(result)
        }
    }
    
    
    private func checkMemoRequired(transaction: Transaction) async -> CheckMemoRequiredResponseEnum {
        if transaction.memo != Memo.none {
            return .noMemoRequired
        }
        
        var destinations = [String]()
        for operation in transaction.operations {
            
            var destination = ""
            if let paymentOp = operation as? PaymentOperation, paymentOp.destinationAccountId.hasPrefix("G") {
                destination = paymentOp.destinationAccountId
            } else if let paymentOp = operation as? PathPaymentOperation, paymentOp.destinationAccountId.hasPrefix("G") {
                destination = paymentOp.destinationAccountId
            } else if let accountMergeOp = operation as? AccountMergeOperation, accountMergeOp.destinationAccountId.hasPrefix("G") {
                destination = accountMergeOp.destinationAccountId
            }
            
            if destination.isEmpty || destinations.contains(destination) {
                continue
            }
            
            destinations.append(destination)
        }
        
        if (destinations.count == 0) {
            return .noMemoRequired
        }
        
        return await withCheckedContinuation { continuation in
            checkMemoRequiredForDestinations(destinations: destinations, response: { (result) -> (Void) in
                switch result {
                case .noMemoRequired:
                    continuation.resume(returning: .noMemoRequired)
                case .memoRequired(let accountId):
                    continuation.resume(returning: .memoRequired(destination: accountId))
                case .failure(let error):
                    continuation.resume(returning: .failure(error: error))
                }
            })
        }
    }
    
    private func checkMemoRequiredForDestinations(destinations: [String], response:@escaping CheckMemoRequiredResponseClosure) {
        
        var remainingDestinations = destinations
        if let firstDestination = remainingDestinations.first {
            let requestPath = "/accounts/\(firstDestination)"
            
            serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
                switch result {
                case .success(let data):
                    do {
                        let accountDetails = try self.jsonDecoder.decode(AccountResponse.self, from: data)
                        // "MQ==" is the base64 encoding of "1".
                        if let value = accountDetails.data["config.memo_required"], value == "MQ==" {
                            response(.memoRequired(destination: accountDetails.accountId))
                        } else {
                            remainingDestinations.removeFirst()
                            self.checkMemoRequiredForDestinations(destinations: remainingDestinations, response: { (nextResult) -> (Void) in
                                switch nextResult {
                                case .noMemoRequired:
                                    response(.noMemoRequired)
                                case .memoRequired(let accountId):
                                    response(.memoRequired(destination: accountId))
                                case .failure(let error):
                                    response(.failure(error: error))
                                }
                            })
                        }
                    } catch {
                        response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                    }
                    
                case .failure(let error):
                    switch error {
                    case .notFound( _, _):
                        // account not found => no memo required for this account.
                        remainingDestinations.removeFirst()
                        self.checkMemoRequiredForDestinations(destinations: remainingDestinations, response: { (nextResult) -> (Void) in
                            switch nextResult {
                            case .noMemoRequired:
                                response(.noMemoRequired)
                            case .memoRequired(let accountId):
                                response(.memoRequired(destination: accountId))
                            case .failure(let error):
                                response(.failure(error: error))
                            }
                        })
                    default:
                        response(.failure(error:error))
                    }
                }
            }
        } else {
            response(.noMemoRequired)
        }
    }
    
    @available(*, renamed: "postTransactionCore(transactionEnvelope:)")
    private func postTransactionCore(transactionEnvelope:String, response:@escaping TransactionPostResponseClosure) {
        Task {
            let result = await postTransactionCore(transactionEnvelope: transactionEnvelope)
            response(result)
        }
    }
    
    
    private func postTransactionCore(transactionEnvelope:String) async -> TransactionPostResponseEnum {
        
        let requestPath = "/transactions"
        if let encoded = transactionEnvelope.urlEncoded {
            let data1 = ("tx=" + encoded).data(using: .utf8)
            
            let result = await serviceHelper.POSTRequestWithPath(path: requestPath, body: data1)
            switch result {
            case .success(let data):
                do {
                    //print("SUCCESS: " + String(data: data, encoding: .utf8)!)
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transaction = try self.jsonDecoder.decode(SubmitTransactionResponse.self, from: data)
                    return .success(details: transaction)
                } catch {
                    return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
                }
            case .failure(let error):
                return .failure(error:error)
            }
        } else {
            return .failure(error: .parsingResponseFailed(message: "Failed to URL encode the xdr enveloper"))
        }
    }
    
    @available(*, renamed: "postTransactionAsyncCore(transactionEnvelope:)")
    private func postTransactionAsyncCore(transactionEnvelope:String, response:@escaping TransactionPostAsyncResponseClosure) {
        Task {
            let result = await postTransactionAsyncCore(transactionEnvelope: transactionEnvelope)
            response(result)
        }
    }
    
    
    private func postTransactionAsyncCore(transactionEnvelope:String) async -> TransactionPostAsyncResponseEnum {
        
        let requestPath = "/transactions_async"
        if let encoded = transactionEnvelope.urlEncoded {
            let data1 = ("tx=" + encoded).data(using: .utf8)
            
            let result = await serviceHelper.POSTRequestWithPath(path: requestPath, body: data1)
            switch result {
            case .success(let data):
                do {
                    //print("SUCCESS: " + String(data: data, encoding: .utf8)!)
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let transaction = try self.jsonDecoder.decode(SubmitTransactionAsyncResponse.self, from: data)
                    return .success(details: transaction)
                } catch {
                    return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
                }
            case .failure(let error):
                var responseData:Data? = nil
                
                switch error {
                case .badRequest(let message, _):
                    responseData = message.data(using: .utf8)
                case .duplicate(let message, _):
                    responseData = message.data(using: .utf8)
                case .staleHistory(let message, _):
                    responseData = message.data(using: .utf8)
                default:
                    break
                }
                if let data = responseData {
                    self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    if let transaction = try? self.jsonDecoder.decode(SubmitTransactionAsyncResponse.self, from: data) {
                        return .success(details: transaction)
                    }
                }
                return .failure(error:error)
            }
        } else {
            return .failure(error: .parsingResponseFailed(message: "Failed to URL encode the xdr enveloper"))
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
        case .transactionsForClaimableBalance(let claimableBalanceId, let cursor):
            subpath = "/_balances/" + claimableBalanceId + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .transactionsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/transactions"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
        
        let streamItem = TransactionsStreamItem(requestUrl: serviceHelper.requestUrlWithPath(path: subpath))
        return streamItem
    }
    
    @available(*, renamed: "getTransactions(onPath:from:order:limit:)")
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactions(onPath: path, from: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    
    private func getTransactions(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<TransactionResponse>.ResponseEnum {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getTransactionsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    @available(*, renamed: "getTransactionsFromUrl(url:)")
    open func getTransactionsFromUrl(url:String, response:@escaping PageResponse<TransactionResponse>.ResponseClosure) {
        Task {
            let result = await getTransactionsFromUrl(url: url)
            response(result)
        }
    }
    
    
    open func getTransactionsFromUrl(url:String) async -> PageResponse<TransactionResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                self.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                let transactions = try self.jsonDecoder.decode(PageResponse<TransactionResponse>.self, from: data)
                return .success(page: transactions)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
