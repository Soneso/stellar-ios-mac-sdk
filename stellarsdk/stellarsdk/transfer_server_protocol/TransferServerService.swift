//
//  TransferObject.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed transfer server for domain responses.
public enum TransferServerServiceForDomainEnum {
    case success(response: TransferServerService)
    case failure(error: TransferServerError)
}

/// An enum used to diferentiate between successful and failed deposit responses.
public enum DepositResponseEnum {
    case success(response: DepositResponse)
    case failure(error: TransferServerError)
}

/// An enum used to diferentiate between successful and failed withdraw responses.
public enum WithdrawResponseEnum {
    case success(response: WithdrawResponse)
    case failure(error: TransferServerError)
}

/// An enum used to diferentiate between successful and failed anchor info responses.
public enum AnchorInfoResponseEnum {
    case success(response: AnchorInfoResponse)
    case failure(error: TransferServerError)
}

/// An enum used to diferentiate between successful and failed anchor transactions responses.
public enum AnchorTransactionsResponseEnum {
    case success(response: AnchorTransactionsResponse)
    case failure(error: TransferServerError)
}

/// An enum used to diferentiate between successful and failed anchor transaction responses.
public enum AnchorTransactionResponseEnum {
    case success(response: AnchorTransaction)
    case failure(error: TransferServerError)
}

/// An enum used to diferentiate between successful and failed anchor fee responses.
public enum AnchorFeeResponseEnum {
    case success(response: AnchorFeeResponse)
    case failure(error: TransferServerError)
}

/// A closure to be called with the response from a transfer server for domain request.
public typealias TransferServerServiceClosure = (_ response:TransferServerServiceForDomainEnum) -> (Void)

/// A closure to be called with the response from a deposit request.
public typealias DepositResponseClosure = (_ response:DepositResponseEnum) -> (Void)

/// A closure to be called with the response from a withdraw request.
public typealias WithdrawResponseClosure = (_ response:WithdrawResponseEnum) -> (Void)

/// A closure to be called with the response from a anchor info request.
public typealias AnchorInfoResponseClosure = (_ response:AnchorInfoResponseEnum) -> (Void)

/// A closure to be called with the response from a transactions request.
public typealias AnchorTransactionsResponseClosure = (_ response:AnchorTransactionsResponseEnum) -> (Void)

/// A closure to be called with the response from a transaction request.
public typealias AnchorTransactionResponseClosure = (_ response:AnchorTransactionResponseEnum) -> (Void)

/// A closure to be called with the response from a fee request.
public typealias AnchorFeeResponseClosure = (_ response:AnchorFeeResponseEnum) -> (Void)


public class TransferServerService: NSObject {

    public var transferServiceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(transferServiceAddress:String) {
        self.transferServiceAddress = transferServiceAddress
        serviceHelper = ServiceHelper(baseURL: transferServiceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates a TransferServerService instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
    public static func forDomain(domain:String, completion:@escaping TransferServerServiceClosure) {
        let transferServerKey = "TRANSFER_SERVER"
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            completion(.failure(error: .invalidDomain))
            return
        }
        
        DispatchQueue.global().async {
            do {
                let tomlString = try String(contentsOf: url, encoding: .utf8)
                let toml = try Toml(withString: tomlString)
                if let transferServerAddress = toml.string(transferServerKey) {
                    let transferServerService = TransferServerService(transferServiceAddress: transferServerAddress)
                    completion(.success(response: transferServerService))
                } else {
                    completion(.failure(error: .noTransferServerSet))
                }
                
            } catch {
                completion(.failure(error: .invalidToml))
            }
        }
    }
    
    /**
     A deposit is when a user sends an external token (BTC via Bitcoin, USD via bank transfer, etc...) to an address held by an anchor. In turn, the anchor sends an equal amount of tokens on the Stellar network (minus fees) to the user's Stellar account.
     
     The deposit endpoint allows a wallet to get deposit information from an anchor, so a user has all the information needed to initiate a deposit. It also lets the anchor specify additional information (if desired) that the user must submit via the /customer endpoint to be able to deposit.
     */
    public func deposit(request: DepositRequest, completion:@escaping DepositResponseClosure) {
        var requestPath = "/deposit?asset_code=\(request.assetCode)&account=\(request.account)"
        if let memoType = request.memoType {
            requestPath += "&memo_type=\(memoType)"
        }
        if let memo = request.memo {
            requestPath += "&memo=\(memo)"
        }
        if let emailAddress = request.emailAddress {
            requestPath += "&email_address=\(emailAddress)"
        }
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        if let walletName = request.walletName {
            requestPath += "&wallet_name=\(walletName)"
        }
        if let walletUrl = request.walletUrl {
            requestPath += "&wallet_url=\(walletUrl)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        if let onChangeCallback = request.onChangeCallback {
            requestPath += "&on_change_callback=\(onChangeCallback)"
        }
        if let amount = request.amount {
            requestPath += "&amount=\(amount)"
        }
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let claimableBalanceSupported = request.claimableBalanceSupported {
            requestPath += "&claimable_balance_supported=\(claimableBalanceSupported)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(DepositResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     This operation allows a user to redeem an asset currently on the Stellar network for the real asset (BTC, USD, stock, etc...) via the anchor of the Stellar asset.
     
     The withdraw endpoint allows a wallet to get withdrawal information from an anchor, so a user has all the information needed to initiate a withdrawal. It also lets the anchor specify additional information (if desired) that the user must submit via the /customer endpoint to be able to withdraw.
     */
    public func withdraw(request: WithdrawRequest, completion:@escaping WithdrawResponseClosure) {
        var requestPath = "/withdraw?type=\(request.type)&asset_code=\(request.assetCode)&dest=\(request.dest)"
        if let destExtra = request.destExtra {
            requestPath += "&dest_extra=\(destExtra)"
        }
        if let account = request.account {
            requestPath += "&account=\(account)"
        }
        if let memo = request.memo {
            requestPath += "&memo=\(memo)"
        }
        if let memoType = request.memoType {
            requestPath += "&memo_type=\(memoType)"
        }
        if let walletName = request.walletName {
            requestPath += "&wallet_name=\(walletName)"
        }
        if let walletUrl = request.walletUrl {
            requestPath += "&wallet_url=\(walletUrl)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        if let onChangeCallback = request.onChangeCallback {
            requestPath += "&on_change_callback=\(onChangeCallback)"
        }
        if let amount = request.amount {
            requestPath += "&amount=\(amount)"
        }
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(WithdrawResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error))) 
            }
        }
    }
    
    /**
     Allows an anchor to communicate basic info about what their TRANSFER_SERVER supports to wallets and clients.
     
     - Parameter language: (optional) Defaults to en. Language code specified using ISO 639-1. description fields in the response should be in this language.
     */
    public func info(language: String? = nil, completion:@escaping AnchorInfoResponseClosure) {
        var requestPath = "/info"
        if let language = language {
            requestPath += "&lang=\(language)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(AnchorInfoResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     The fee endpoint allows an anchor to report the fee that would be charged for a given deposit or withdraw operation. This is important to allow an anchor to accurately report fees to a user even when the fee schedule is complex. If a fee can be fully expressed with the fee_fixed and fee_percent fields in the /info response, then an anchor must not implement this endpoint.
     */
    public func fee(request: FeeRequest,  completion:@escaping AnchorFeeResponseClosure) {
        var requestPath = "/fee?operation=\(request.operation)&asset_code=\(request.assetCode)&amount=\(request.amount)"
        
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(AnchorFeeResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     The transaction history endpoint helps anchors enable a better experience for users using an external wallet. With it, wallets can display the status of deposits and withdrawals while they process and a history of past transactions with the anchor. It's only for transactions that are deposits to or withdrawals from the anchor.
     */
    public func getTransactions(request: AnchorTransactionsRequest,  completion:@escaping AnchorTransactionsResponseClosure) {
        var requestPath = "/transactions?asset_code=\(request.assetCode)&account=\(request.account)"
        if let noOlderThanDate = request.noOlderThan {
            let noOlderThan = DateFormatter.iso8601.string(from: noOlderThanDate)
            requestPath += "&no_older_than=\(noOlderThan)"
        }
        if let limit = request.limit {
            requestPath += "&limit=\(limit)"
        }
        if let pagingId = request.pagingId {
            requestPath += "&paging_id=\(pagingId)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(AnchorTransactionsResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     The transaction endpoint enables clients to query/validate a specific transaction at an anchor.
     */
    public func getTransaction(request: AnchorTransactionRequest,  completion:@escaping AnchorTransactionResponseClosure) {
        var requestPath = "/transaction?"
        
        var first = false
        if let id = request.id {
            requestPath += "id=\(id)"
            first = false
        }
        if let stellarTransactionId = request.stellarTransactionId {
            if !first {
                requestPath += "&"
            }
            requestPath += "stellar_transaction_id=\(stellarTransactionId)"
            first = false
        }
        if let externalTransactionId = request.externalTransactionId {
            if !first {
                requestPath += "&"
            }
            requestPath += "external_transaction_id=\(externalTransactionId)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(AnchorTransaction.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     This endpoint should only be used when the anchor requests more info via the pending_transaction_info_update status. The required_info_updates transaction field should contain the fields required for the update. If the sender tries to update at a time when no info is requested the receiver should fail with an error response.
     @See https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#update
     
     - Parameter id: id of the transaction
     - Parameter jwt: token received via SEP-10 authentication
     - Parameter contentType:represents  the content type of the request
     - Parameter body:body of the request as described in the stellar doc
     
     */
    public func patchTransaction(id:String, jwt:String?, contentType:String, body:Data, completion:@escaping AnchorTransactionResponseClosure) {
        let requestPath = "/transaction/\(id)"
    
        serviceHelper.PATCHRequestWithPath(path: requestPath, jwtToken: jwt, contentType:contentType, body:body) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(AnchorTransaction.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    private func errorFor(horizonError:HorizonRequestError) -> TransferServerError {
        switch horizonError {
        case .forbidden(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let type = json["type"] as? String {
                        if type == "non_interactive_customer_info_needed" {
                            let response = try self.jsonDecoder.decode(CustomerInformationNeededNonInteractive.self, from: data)
                            return .informationNeeded(response: .nonInteractive(info: response))
                        } else if type == "interactive_customer_info_needed" {
                            let response = try self.jsonDecoder.decode(CustomerInformationNeededInteractive.self, from: data)
                            return .informationNeeded(response: .interactive(info: response))
                        } else if type == "customer_info_status" {
                            let response = try self.jsonDecoder.decode(CustomerInformationStatus.self, from: data)
                            return.informationNeeded(response: .status(info: response))
                        } else if type == "authentication_required" {
                            return.authenticationRequired
                        } else {
                            return .parsingResponseFailed(message: horizonError.localizedDescription)
                        }
                    }
                } catch let error {
                    return .parsingResponseFailed(message: error.localizedDescription)
                }
            }
        case .requestFailed(let message),
             .badRequest(let message, _),
             .notFound(let message, _),
             .notAcceptable(let message, _),
             .beforeHistory(let message, _),
             .rateLimitExceeded(let message, _),
             .internalServerError(let message, _),
             .notImplemented(let message, _),
             .staleHistory(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let error = json["error"] as? String {
                        return .anchorError(message: error)
                    }
                } catch {
                    return .horizonError(error: horizonError)
                }
            }
        default:
            return .horizonError(error: horizonError)
        }
        return .horizonError(error: horizonError)
    }
    
}
