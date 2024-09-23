//
//  TransferServerService.swift
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
    case success(response: AnchorTransactionResponse)
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
    
    public init(serviceAddress:String) {
        
        if (serviceAddress.hasSuffix("/")) {
            self.transferServiceAddress = String(serviceAddress.dropLast())
        } else {
            self.transferServiceAddress = serviceAddress
        }

        serviceHelper = ServiceHelper(baseURL: self.transferServiceAddress)
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
                    let transferServerService = TransferServerService(serviceAddress: transferServerAddress)
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
     
     If the anchor supports SEP-38 quotes, it can also provide a bridge between non-equivalent tokens. For example, the anchor can receive ARS via bank transfer and in return send the equivalent value (minus fees) as USDC on the Stellar network to the user's Stellar account. That kind of deposit is covered in GET /deposit-exchange.
     
     The /deposit endpoint allows a wallet to get deposit information from an anchor, so a user has all the information needed to initiate a deposit. It also lets the anchor specify additional information (if desired) that the user must submit via SEP-12 to be able to deposit.
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
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
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
     If the anchor supports SEP-38 quotes, it can provide a deposit that makes a bridge between non-equivalent tokens by receiving, for instance BRL via bank transfer and in return sending the equivalent value (minus fees) as USDC to the user's Stellar account.

     The /deposit-exchange endpoint allows a wallet to get deposit information from an anchor when the user intends to make a conversion between non-equivalent tokens. With this endpoint, a user has all the information needed to initiate a deposit and it also lets the anchor specify additional information (if desired) that the user must submit via SEP-12.
     */
    public func depositExchange(request: DepositExchangeRequest, completion:@escaping DepositResponseClosure) {
        var requestPath = "/deposit-exchange?destination_asset=\(request.destinationAsset)&source_asset=\(request.sourceAsset)&amount=\(request.amount)&account=\(request.account)"
        if let quoteId = request.quoteId {
            requestPath += "&quote_id=\(quoteId)"
        }
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
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let claimableBalanceSupported = request.claimableBalanceSupported {
            requestPath += "&claimable_balance_supported=\(claimableBalanceSupported)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
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
     A withdraw is when a user redeems an asset currently on the Stellar network for its equivalent off-chain asset via the Anchor. For instance, a user redeeming their NGNT in exchange for fiat NGN.

     If the anchor supports SEP-38 quotes, it can also provide a bridge between non-equivalent tokens. For example, the anchor can receive USDC from the Stellar network and in return send the equivalent value (minus fees) as NGN to the user's bank account. That kind of withdrawal is covered in GET /withdraw-exchange.

     The /withdraw endpoint allows a wallet to get withdrawal information from an anchor, so a user has all the information needed to initiate a withdrawal. It also lets the anchor specify additional information (if desired) that the user must submit via SEP-12 to be able to withdraw.
     */
    public func withdraw(request: WithdrawRequest, completion:@escaping WithdrawResponseClosure) {
        var requestPath = "/withdraw?type=\(request.type)&asset_code=\(request.assetCode)"
        if let dest = request.dest {
            requestPath += "&dest=\(dest)"
        }
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
        if let refundMemo = request.refundMemo {
            requestPath += "&refund_memo=\(refundMemo)"
        }
        if let refundMemoType = request.refundMemoType {
            requestPath += "&refund_memo_type=\(refundMemoType)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
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
     If the anchor supports SEP-38 quotes, it can provide a withdraw that makes a bridge between non-equivalent tokens by receiving, for instance USDC from the Stellar network and in return sending the equivalent value (minus fees) as NGN to the user's bank account.

     The /withdraw-exchange endpoint allows a wallet to get withdraw information from an anchor when the user intends to make a conversion between non-equivalent tokens. With this endpoint, a user has all the information needed to initiate a withdraw and it also lets the anchor specify additional information (if desired) that the user must submit via SEP-12.
     */
    public func withdrawExchange(request: WithdrawExchangeRequest, completion:@escaping WithdrawResponseClosure) {
        var requestPath = "/withdraw-exchange?type=\(request.type)&source_asset=\(request.sourceAsset)&destination_asset=\(request.destinationAsset)&amount=\(request.amount)"
        if let quoteId = request.quoteId {
            requestPath += "&quote_id=\(quoteId)"
        }
        if let dest = request.dest {
            requestPath += "&dest=\(dest)"
        }
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
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let refundMemo = request.refundMemo {
            requestPath += "&refund_memo=\(refundMemo)"
        }
        if let refundMemoType = request.refundMemoType {
            requestPath += "&refund_memo_type=\(refundMemoType)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
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
     
     - Parameter language: (optional) Defaults to en if not specified or if the specified language is not supported. Language code specified using RFC 4646. error fields and other human readable messages in the response should be in this language.
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
     This endpoint is deprecated. The SEP-38 GET /price endpoint should be used to fetch fees instead.
     
     The fee endpoint allows an anchor to report the fee that would be charged when using the /deposit or /withdraw endpoints.

     This endpoint is important to allow an anchor to accurately report fees to a user even when the fee schedule is complex. If a fee can be fully expressed with the fee_fixed and fee_percent fields in the /info response, then an anchor should not implement this endpoint.

     This endpoint only reports fees expressed in units of Stellar assets. Fetching fee amounts for transactions using both on & off-chain assets (using either /deposit-exchange and /withdraw-exchange) is not supported unless fees are only dependent on the amount of the Stellar asset transacted.
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

     If the decoded JWT's sub parameter also contains a memo, the anchor must only return transactions for the user identified by a combination of the account and memo. The anchor must not return all transactions for the Stellar account because that would include transactions for other memos.
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
        if let kind = request.kind {
            requestPath += "&kind=\(kind)"
        }
        if let pagingId = request.pagingId {
            requestPath += "&paging_id=\(pagingId)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
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

     Anchors must ensure that the SEP-10 JWT included in the request contains the Stellar account and optional memo value used when making the original deposit or withdraw request that resulted in the transaction requested using this endpoint.
     */
    public func getTransaction(request: AnchorTransactionRequest,  completion:@escaping AnchorTransactionResponseClosure) {
        var requestPath = "/transaction?"
        
        var first = true
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
            first = false
        }
        if let lang = request.lang {
            if !first {
                requestPath += "&"
            }
            requestPath += "lang=\(lang)"
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(AnchorTransactionResponse.self, from: data)
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
                    let response = try self.jsonDecoder.decode(AnchorTransactionResponse.self, from: data)
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
        case .requestFailed(let message, _),
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
