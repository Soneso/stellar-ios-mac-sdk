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

/// An enum used to diferentiate between successful and failed anchor put customer info responses.
public enum AnchorCustomerInfoPutResponseEnum {
    case success
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

/// A closure to be called with the response from a put info request.
public typealias AnchorCustomerInfoPutResponseClosure = (_ response:AnchorCustomerInfoPutResponseEnum) -> (Void)

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
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
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
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
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
     This anchor endpoint allows a wallet or exchange to upload information about the customer (chiefly KYC information) on the customer's behalf. It is often used following a /deposit or /withdraw request that responds with non_interactive_customer_info_needed. The endpoint accommodates KYC data that is large or binary formatted (image of driver's license, photo of bill for proof of address, etc...). A wallet may make multiple requests to /customer to upload data, and the endpoint is idempotent. All calls to /customer must include a JWT token retrieved using the SEP-10 authentication flow. This ensures that the client uploading the KYC data is the owner of the account.
     */
    public func putCustomerInfo(request: PutCustomerInfoRequest,  completion:@escaping AnchorCustomerInfoPutResponseClosure) {
        let requestPath = "/customer"
        
        serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters()) { (result) -> (Void) in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     Delete all personal information that the anchor has stored about a given customer. [account] is the Stellar account ID (G...) of the customer to delete. This request must be authenticated (via SEP-10) as coming from the owner of the account that will be deleted.
     */
    public func deleteCustomerInfo(account: String,  completion:@escaping AnchorCustomerInfoPutResponseClosure) {
        let requestPath = "/customer/\(account)"
        
        serviceHelper.DELETERequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(_):
                completion(.success)
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
