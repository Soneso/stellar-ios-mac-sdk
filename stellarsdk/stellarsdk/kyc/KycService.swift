//
//  KycService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation


/// An enum used to diferentiate between successful and failed kyc server for domain responses.
public enum KycServiceForDomainEnum {
    case success(response: KycService)
    case failure(error: KycServiceError)
}

/// An enum used to diferentiate between successful and failed get customer info responses.
public enum GetCustomerInfoResponseEnum {
    case success(response: GetCustomerInfoResponse)
    case failure(error: KycServiceError)
}

public enum PutCustomerInfoResponseEnum {
    case success(response: PutCustomerInfoResponse)
    case failure(error: KycServiceError)
}

public enum DeleteCustomerResponseEnum {
    case success
    case failure(error: KycServiceError)
}

public enum PutCustomerCallbackResponseEnum {
    case success
    case failure(error: KycServiceError)
}


public typealias KycServiceClosure = (_ response:KycServiceForDomainEnum) -> (Void)


public typealias GetCustomerInfoResponseClosure = (_ response:GetCustomerInfoResponseEnum) -> (Void)
public typealias PutCustomerInfoResponseClosure = (_ response:PutCustomerInfoResponseEnum) -> (Void)
public typealias DeleteCustomerResponseClosure = (_ response:DeleteCustomerResponseEnum) -> (Void)
public typealias PutCustomerCallbackResponseClosure = (_ response:PutCustomerCallbackResponseEnum) -> (Void)


public class KycService: NSObject {

    public var kycServiceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(kycServiceAddress:String) {
        self.kycServiceAddress = kycServiceAddress
        serviceHelper = ServiceHelper(baseURL: kycServiceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates a KycService instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
    public static func forDomain(domain:String, completion:@escaping KycServiceClosure) {
        let kycServerKey = "KYC_SERVER"
        let transferServerKey = "TRANSFER_SERVER"
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            completion(.failure(error: .invalidDomain))
            return
        }
        
        DispatchQueue.global().async {
            do {
                let tomlString = try String(contentsOf: url, encoding: .utf8)
                let toml = try Toml(withString: tomlString)
                if let kycServerAddress = toml.string(kycServerKey) != nil ? toml.string(kycServerKey) : toml.string(transferServerKey) {
                    let kycService = KycService(kycServiceAddress: kycServerAddress)
                    completion(.success(response: kycService))
                } else {
                    completion(.failure(error: .noKycOrTransferServerSet))
                }
                
            } catch {
                completion(.failure(error: .invalidToml))
            }
        }
    }
    
    /**
     This allows you to:
     1. Fetch the fields the server requires in order to register a new customer via a PUT /customer request
     2 .Check the status of a customer that may already be registered
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-get
     */
    public func getCustomerInfo(request: GetCustomerInfoRequest, completion:@escaping GetCustomerInfoResponseClosure) {
        var requestPath = "/customer"
        
        if let id = request.id {
            requestPath += "&id=\(id)"
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
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        if let transactionId = request.transactionId {
            requestPath += "&transaction_id=\(transactionId)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        
        if let range = requestPath.range(of: "&") {
            requestPath = requestPath.replacingCharacters(in: range, with: "?")
        }
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(GetCustomerInfoResponse.self, from: data)
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
     Upload customer information to an anchor in an authenticated and idempotent fashion.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put
     */
    public func putCustomerInfo(request: PutCustomerInfoRequest,  completion:@escaping PutCustomerInfoResponseClosure) {
        let requestPath = "/customer"
        
        serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(PutCustomerInfoResponse.self, from: data)
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
     This endpoint allows servers to accept data values, usually confirmation codes, that verify a previously provided field via PUT /customer, such as mobile_number or email_address.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification
     */
    public func putCustomerVerification(request: PutCustomerVerificationRequest,  completion:@escaping GetCustomerInfoResponseClosure) {
        let requestPath = "/customer/verification"
        
        serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(GetCustomerInfoResponse.self, from: data)
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
     Delete all personal information that the anchor has stored about a given customer. [account] is the Stellar account ID (G...) of the customer to delete. This request must be authenticated (via SEP-10) as coming from the owner of the account that will be deleted.
     */
    public func deleteCustomerInfo(account: String, jwt:String, completion:@escaping DeleteCustomerResponseClosure) {
        let requestPath = "/customer/\(account)"
        
        serviceHelper.DELETERequestWithPath(path: requestPath, jwtToken: jwt) { (result) -> (Void) in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     Allow the wallet to provide a callback URL to the anchor. The provided callback URL will replace (and supercede) any previously-set callback URL for this account.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-callback-put
     */
    public func putCustomerCallback(request: PutCustomerCallbackRequest,  completion:@escaping PutCustomerCallbackResponseClosure) {
        let requestPath = "/customer/callback"
        
        serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt) { (result) -> (Void) in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    private func errorFor(horizonError:HorizonRequestError) -> KycServiceError {
        switch horizonError {
        case .badRequest(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let error = json["error"] as? String {
                        return .badRequest(error: error)
                    }
                } catch {
                    return .horizonError(error: horizonError)
                }
            }
            break
        case .notFound(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let error = json["error"] as? String {
                        return .notFound(error: error)
                    }
                } catch {
                    return .horizonError(error: horizonError)
                }
            }
            break
        case .unauthorized(let message):
            return .unauthorized(message: message)
        default:
            return .horizonError(error: horizonError)
        }
        return .horizonError(error: horizonError)
    }
}
