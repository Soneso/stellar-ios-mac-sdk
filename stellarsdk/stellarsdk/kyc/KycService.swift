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

public enum PostCustomerFileResponseEnum {
    case success(response: CustomerFileResponse)
    case failure(error: KycServiceError)
}

public enum GetCustomerFilesResponseEnum {
    case success(response: GetCustomerFilesResponse)
    case failure(error: KycServiceError)
}


public typealias KycServiceClosure = (_ response:KycServiceForDomainEnum) -> (Void)


public typealias GetCustomerInfoResponseClosure = (_ response:GetCustomerInfoResponseEnum) -> (Void)
public typealias PutCustomerInfoResponseClosure = (_ response:PutCustomerInfoResponseEnum) -> (Void)
public typealias DeleteCustomerResponseClosure = (_ response:DeleteCustomerResponseEnum) -> (Void)
public typealias PutCustomerCallbackResponseClosure = (_ response:PutCustomerCallbackResponseEnum) -> (Void)
public typealias PostCustomerFileResponseClosure = (_ response:PostCustomerFileResponseEnum) -> (Void)
public typealias GetCustomerFilesResponseClosure = (_ response:GetCustomerFilesResponseEnum) -> (Void)


public class KycService: NSObject {

    public var kycServiceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(kycServiceAddress:String) {
        self.kycServiceAddress = kycServiceAddress
        serviceHelper = ServiceHelper(baseURL: kycServiceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates a KycService instance based on information from [stellar.toml](https://developers.stellar.org/docs/learn/concepts/stellar-toml.html) file for a given domain.
    @available(*, renamed: "forDomain(domain:)")
    public static func forDomain(domain:String, completion:@escaping KycServiceClosure) {
        Task {
            let result = await forDomain(domain: domain)
            completion(result)
        }
    }
    
    /// Creates a KycService instance based on information from [stellar.toml](https://developers.stellar.org/docs/learn/concepts/stellar-toml.html) file for a given domain.
    public static func forDomain(domain:String) async -> KycServiceForDomainEnum {
        let kycServerKey = "KYC_SERVER"
        let transferServerKey = "TRANSFER_SERVER"
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            return .failure(error: .invalidDomain)
        }
        
        do {
            let tomlString = try String(contentsOf: url, encoding: .utf8)
            let toml = try Toml(withString: tomlString)
            if let kycServerAddress = toml.string(kycServerKey) != nil ? toml.string(kycServerKey) : toml.string(transferServerKey) {
                let kycService = KycService(kycServiceAddress: kycServerAddress)
                return .success(response: kycService)
            } else {
                return .failure(error: .noKycOrTransferServerSet)
            }
            
        } catch {
            return .failure(error: .invalidToml)
        }
    }
    
    /**
     This allows you to:
     1. Fetch the fields the server requires in order to register a new customer via a PUT /customer request
     2 .Check the status of a customer that may already be registered
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-get
     */
    @available(*, renamed: "getCustomerInfo(request:)")
    public func getCustomerInfo(request: GetCustomerInfoRequest, completion:@escaping GetCustomerInfoResponseClosure) {
        Task {
            let result = await getCustomerInfo(request: request)
            completion(result)
        }
    }
    
    /**
     This allows you to:
     1. Fetch the fields the server requires in order to register a new customer via a PUT /customer request
     2 .Check the status of a customer that may already be registered
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-get
     */
    public func getCustomerInfo(request: GetCustomerInfoRequest) async -> GetCustomerInfoResponseEnum {
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
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(GetCustomerInfoResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /**
     Upload customer information to an anchor in an authenticated and idempotent fashion.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put
     */
    @available(*, renamed: "putCustomerInfo(request:)")
    public func putCustomerInfo(request: PutCustomerInfoRequest,  completion:@escaping PutCustomerInfoResponseClosure) {
        Task {
            let result = await putCustomerInfo(request: request)
            completion(result)
        }
    }
    
    /**
     Upload customer information to an anchor in an authenticated and idempotent fashion.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put
     */
    public func putCustomerInfo(request: PutCustomerInfoRequest) async -> PutCustomerInfoResponseEnum {
        let requestPath = "/customer"
        
        let result = await serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(PutCustomerInfoResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /**
     This endpoint allows servers to accept data values, usually confirmation codes, that verify a previously provided field via PUT /customer, such as mobile_number or email_address.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification
     */
    @available(*, renamed: "putCustomerVerification(request:)")
    public func putCustomerVerification(request: PutCustomerVerificationRequest,  completion:@escaping GetCustomerInfoResponseClosure) {
        Task {
            let result = await putCustomerVerification(request: request)
            completion(result)
        }
    }
    
    /**
     This endpoint allows servers to accept data values, usually confirmation codes, that verify a previously provided field via PUT /customer, such as mobile_number or email_address.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification
     */
    public func putCustomerVerification(request: PutCustomerVerificationRequest) async -> GetCustomerInfoResponseEnum {
        let requestPath = "/customer/verification"
        
        let result = await serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(GetCustomerInfoResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /**
     Delete all personal information that the anchor has stored about a given customer. [account] is the Stellar account ID (G...) of the customer to delete. This request must be authenticated (via SEP-10) as coming from the owner of the account that will be deleted.
     */
    @available(*, renamed: "deleteCustomerInfo(account:jwt:)")
    public func deleteCustomerInfo(account: String, jwt:String, completion:@escaping DeleteCustomerResponseClosure) {
        Task {
            let result = await deleteCustomerInfo(account: account, jwt: jwt)
            completion(result)
        }
    }
    
    /**
     Delete all personal information that the anchor has stored about a given customer. [account] is the Stellar account ID (G...) of the customer to delete. This request must be authenticated (via SEP-10) as coming from the owner of the account that will be deleted.
     */
    public func deleteCustomerInfo(account: String, jwt:String) async -> DeleteCustomerResponseEnum {
        let requestPath = "/customer/\(account)"
        
        let result = await serviceHelper.DELETERequestWithPath(path: requestPath, jwtToken: jwt)
        switch result {
        case .success(_):
            return .success
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /**
     Allow the wallet to provide a callback URL to the anchor. The provided callback URL will replace (and supercede) any previously-set callback URL for this account.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-callback-put
     */
    @available(*, renamed: "putCustomerCallback(request:)")
    public func putCustomerCallback(request: PutCustomerCallbackRequest,  completion:@escaping PutCustomerCallbackResponseClosure) {
        Task {
            let result = await putCustomerCallback(request: request)
            completion(result)
        }
    }
    
    /**
     Allow the wallet to provide a callback URL to the anchor. The provided callback URL will replace (and supercede) any previously-set callback URL for this account.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-callback-put
     */
    public func putCustomerCallback(request: PutCustomerCallbackRequest) async -> PutCustomerCallbackResponseEnum {
        let requestPath = "/customer/callback"
        
        let result = await serviceHelper.PUTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt)
        switch result {
        case .success(_):
            return .success
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Passing binary fields such as photo_id_front or organization.photo_proof_address in PUT /customer requests must be done using the multipart/form-data content type. This is acceptable in most cases, but multipart/form-data does not support nested data structures such as arrays or sub-objects.
    /// This endpoint is intended to decouple requests containing binary fields from requests containing nested data structures, supported by content types such as application/json. This endpoint is optional and only needs to be supported if the use case requires accepting nested data structures in PUT /customer requests.
    /// Once a file has been uploaded using this endpoint, it's file_id can be used in subsequent PUT /customer requests. The field name for the file_id should be the appropriate SEP-9 field followed by _file_id. For example, if file_abc is returned as a file_id from POST /customer/files, it can be used in a PUT /customer
    /// See:  https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files
    public func postCustomerFile(file:Data, jwtToken:String) async -> PostCustomerFileResponseEnum {
        let requestPath = "/customer/files"
        var parameters = [String:Data]()
        parameters["file"] = file
        let result = await serviceHelper.POSTMultipartRequestWithPath(path: requestPath, parameters: parameters, jwtToken: jwtToken)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(CustomerFileResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Requests info about the uploaded files via postCustomerFile
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files
    public func getCustomerFiles(fileId:String? = nil, customerId:String? = nil, jwtToken: String) async -> GetCustomerFilesResponseEnum {
        var requestPath = "/customer/files"
        
        if let fid = fileId {
            requestPath += "&file_id=\(fid)"
        }
        if let cid = customerId {
            requestPath += "&customer_id=\(cid)"
        }
        
        if let range = requestPath.range(of: "&") {
            requestPath = requestPath.replacingCharacters(in: range, with: "?")
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwtToken)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(GetCustomerFilesResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
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
        case .payloadTooLarge(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let error = json["error"] as? String {
                        return .payloadTooLarge(error: error)
                    }
                } catch {
                    return .payloadTooLarge(error: nil)
                }
            }
        default:
            return .horizonError(error: horizonError)
        }
        return .horizonError(error: horizonError)
    }
}
