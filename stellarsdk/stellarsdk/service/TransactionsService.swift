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

public enum CheckMemoRequiredResponseEnum {
    case noMemoRequired
    case memoRequired(destination: String)
    case failure(error: HorizonRequestError)
}

public enum TransactionsChange {
    case allTransactions(cursor:String?)
    case transactionsForAccount(account:String, cursor:String?)
    case transactionsForLedger(ledger:String, cursor:String?)
}

public typealias TransactionDetailsResponseClosure = (_ response:TransactionDetailsResponseEnum) -> (Void)
public typealias TransactionPostResponseClosure = (_ response:TransactionPostResponseEnum) -> (Void)
public typealias CheckMemoRequiredResponseClosure = (_ response:CheckMemoRequiredResponseEnum) -> (Void)

public class TransactionsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    //let sdk = StellarSDK()
    
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
    
    open func submitTransaction(transaction:Transaction, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostResponseClosure) throws {
        let envelope = try transaction.encodedEnvelope()
        postTransaction(transactionEnvelope:envelope, skipMemoRequiredCheck: skipMemoRequiredCheck, response: response)
    }
    
    open func postTransaction(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false, response:@escaping TransactionPostResponseClosure) {
        
        if !skipMemoRequiredCheck, let transaction = try? Transaction(envelopeXdr: transactionEnvelope) {
            checkMemoRequired(transaction: transaction, response: { (result) -> (Void) in
                switch result {
                case .noMemoRequired:
                    self.postTransactionCore(transactionEnvelope: transactionEnvelope, response: { (result) -> (Void) in
                        switch result {
                        case .success(let transaction):
                            response(.success(details: transaction))
                        case .failure(let error):
                            response(.failure(error: error))
                        case .destinationRequiresMemo(let destinationAccountId):
                            response(.destinationRequiresMemo(destinationAccountId: destinationAccountId))
                        }
                    })
                case .memoRequired(let accountId):
                    response(.destinationRequiresMemo(destinationAccountId: accountId))
                case .failure(let error):
                    response(.failure(error: error))
                }
            })
        } else {
            postTransactionCore(transactionEnvelope: transactionEnvelope, response: { (result) -> (Void) in
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
    }
    
    
    private func checkMemoRequired(transaction: Transaction, response:@escaping CheckMemoRequiredResponseClosure) {
        if transaction.memo != Memo.none {
            response(.noMemoRequired)
            return
        }
        
        var destinations = [String]()
        for operation in transaction.operations {
            
            var destination = ""
            if let paymentOp = operation as? PaymentOperation {
                destination = paymentOp.destination.accountId
            } else if let paymentOp = operation as? PathPaymentOperation {
                destination = paymentOp.destination.accountId
            } else if let accountMergeOp = operation as? AccountMergeOperation {
                destination = accountMergeOp.destination.accountId
            }
            
            if destination.isEmpty || destinations.contains(destination) {
                continue
            }
            
            destinations.append(destination)
        }
        
        if (destinations.count == 0) {
            response(.noMemoRequired)
            return
        }
        
        checkMemoRequiredForDestinations(destinations: destinations, response: { (result) -> (Void) in
            switch result {
            case .noMemoRequired:
                response(.noMemoRequired)
            case .memoRequired(let accountId):
                response(.memoRequired(destination: accountId))
            case .failure(let error):
                response(.failure(error: error))
            }
        })
    }
    
    open func getAccountDetails(accountId: String, response: @escaping AccountResponseClosure) {
        let requestPath = "/accounts/\(accountId)"
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let responseMessage = try self.jsonDecoder.decode(AccountResponse.self, from: data)
                    response(.success(details:responseMessage))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                response(.failure(error:error))
            }
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
                    response(.failure(error:error))
                }
            }
        } else {
            response(.noMemoRequired)
        }
    }
    private func postTransactionCore(transactionEnvelope:String, response:@escaping TransactionPostResponseClosure) {
        
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
