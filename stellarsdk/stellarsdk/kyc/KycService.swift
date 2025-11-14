//
//  KycService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation


/// Result enum for initializing KYC service from a domain.
public enum KycServiceForDomainEnum {
    /// Successfully created KYC service instance.
    case success(response: KycService)
    /// Failed to initialize service from domain.
    case failure(error: KycServiceError)
}

/// Result enum for SEP-12 get customer info requests.
public enum GetCustomerInfoResponseEnum {
    /// Successfully retrieved customer information and KYC status.
    case success(response: GetCustomerInfoResponse)
    /// Request failed with KYC service error.
    case failure(error: KycServiceError)
}

/// Result enum for SEP-12 put customer info requests.
public enum PutCustomerInfoResponseEnum {
    /// Successfully uploaded or updated customer information.
    case success(response: PutCustomerInfoResponse)
    /// Request failed with KYC service error.
    case failure(error: KycServiceError)
}

/// Result enum for SEP-12 delete customer requests.
public enum DeleteCustomerResponseEnum {
    /// Successfully deleted customer record.
    case success
    /// Request failed with KYC service error.
    case failure(error: KycServiceError)
}

/// Result enum for SEP-12 put customer callback requests.
public enum PutCustomerCallbackResponseEnum {
    /// Successfully registered customer callback URL.
    case success
    /// Request failed with KYC service error.
    case failure(error: KycServiceError)
}

/// Result enum for SEP-12 post customer file requests.
public enum PostCustomerFileResponseEnum {
    /// Successfully uploaded customer verification file.
    case success(response: CustomerFileResponse)
    /// Request failed with KYC service error.
    case failure(error: KycServiceError)
}

/// Result enum for SEP-12 get customer files requests.
public enum GetCustomerFilesResponseEnum {
    /// Successfully retrieved list of customer verification files.
    case success(response: GetCustomerFilesResponse)
    /// Request failed with KYC service error.
    case failure(error: KycServiceError)
}


/// Callback closure for discovering KYC service endpoints for a domain.
public typealias KycServiceClosure = (_ response:KycServiceForDomainEnum) -> (Void)

/// Callback closure for retrieving customer information from KYC service.
public typealias GetCustomerInfoResponseClosure = (_ response:GetCustomerInfoResponseEnum) -> (Void)
/// Callback closure for submitting or updating customer information to KYC service.
public typealias PutCustomerInfoResponseClosure = (_ response:PutCustomerInfoResponseEnum) -> (Void)
/// Callback closure for deleting customer information from KYC service.
public typealias DeleteCustomerResponseClosure = (_ response:DeleteCustomerResponseEnum) -> (Void)
/// Callback closure for setting a callback URL for customer status updates.
public typealias PutCustomerCallbackResponseClosure = (_ response:PutCustomerCallbackResponseEnum) -> (Void)
/// Callback closure for uploading customer verification files to KYC service.
public typealias PostCustomerFileResponseClosure = (_ response:PostCustomerFileResponseEnum) -> (Void)
/// Callback closure for retrieving customer verification files from KYC service.
public typealias GetCustomerFilesResponseClosure = (_ response:GetCustomerFilesResponseEnum) -> (Void)

/// Implements SEP-0012 - KYC API.
///
/// This class provides standardized endpoints for transmitting KYC and AML information to anchors
/// and other services. It allows customers to upload their identity information and status tracking
/// for deposit/withdrawal operations requiring identity verification.
///
/// SEP-0012 is designed to work with SEP-6 (Deposit/Withdrawal) and SEP-24 (Interactive Deposit/Withdrawal)
/// to enable regulated on/off-ramp operations that require customer identity verification.
///
/// ## Typical Workflow
///
/// 1. **Initialize Service**: Create KycService from anchor's domain
/// 2. **Authenticate**: Obtain JWT token using SEP-0010 WebAuthenticator
/// 3. **Get Required Fields**: Query which KYC fields the anchor requires
/// 4. **Upload Information**: Submit customer data and supporting documents
/// 5. **Check Status**: Monitor KYC verification status
///
/// ## Example: Complete KYC Flow
///
/// ```swift
/// // Step 1: Initialize service from domain
/// let serviceResult = await KycService.forDomain(
///     domain: "https://testanchor.stellar.org"
/// )
///
/// guard case .success(let kycService) = serviceResult else { return }
///
/// // Step 2: Get JWT token (using SEP-0010)
/// let jwtToken = "..." // Obtained from WebAuthenticator
///
/// // Step 3: Check what fields are required
/// let getRequest = GetCustomerInfoRequest(
///     account: userAccountId,
///     jwt: jwtToken
/// )
///
/// let getResult = await kycService.getCustomerInfo(request: getRequest)
/// switch getResult {
/// case .success(let response):
///     if response.status == "NEEDS_INFO" {
///         // Check response.fields to see what's required
///         print("Required fields: \(response.fields?.keys ?? [])")
///     }
/// case .failure(let error):
///     print("Error: \(error)")
/// }
///
/// // Step 4: Upload customer information
/// let putRequest = PutCustomerInfoRequest(jwt: jwtToken)
/// putRequest.account = userAccountId
/// putRequest.firstName = "John"
/// putRequest.lastName = "Doe"
/// putRequest.emailAddress = "john@example.com"
/// putRequest.birthDate = "1990-01-01"
///
/// let putResult = await kycService.putCustomerInfo(request: putRequest)
/// switch putResult {
/// case .success(let response):
///     print("Customer ID: \(response.id ?? "")")
///     print("Status: \(response.status ?? "")")
/// case .failure(let error):
///     print("Upload failed: \(error)")
/// }
/// ```
///
/// ## Example: Upload Documents
///
/// ```swift
/// // Upload a file (e.g., photo ID)
/// let photoData = ... // Image data
/// let fileResult = await kycService.postCustomerFile(
///     file: photoData,
///     jwtToken: jwtToken
/// )
///
/// switch fileResult {
/// case .success(let response):
///     // Use file ID in PUT /customer request
///     let fileId = response.id
///
///     let putRequest = PutCustomerInfoRequest(jwt: jwtToken)
///     putRequest.account = userAccountId
///     putRequest.photoIdFrontFileId = fileId
///
///     let result = await kycService.putCustomerInfo(request: putRequest)
/// case .failure(let error):
///     print("File upload failed: \(error)")
/// }
/// ```
///
/// ## Example: Verify Email/Phone
///
/// ```swift
/// // Some anchors require verification of email or phone
/// // First, submit the contact info
/// let putRequest = PutCustomerInfoRequest(jwt: jwtToken)
/// putRequest.account = userAccountId
/// putRequest.emailAddress = "user@example.com"
/// await kycService.putCustomerInfo(request: putRequest)
///
/// // User receives verification code via email
/// // Submit the verification code
/// let verifyRequest = PutCustomerVerificationRequest(
///     id: customerId,
///     jwt: jwtToken
/// )
/// verifyRequest.emailAddressVerification = "123456" // Code from email
///
/// let result = await kycService.putCustomerVerification(request: verifyRequest)
/// ```
///
/// ## Example: Check KYC Status
///
/// ```swift
/// let getRequest = GetCustomerInfoRequest(
///     account: userAccountId,
///     jwt: jwtToken
/// )
///
/// let result = await kycService.getCustomerInfo(request: getRequest)
/// if case .success(let response) = result {
///     switch response.status {
///     case "ACCEPTED":
///         // KYC approved, can proceed with transactions
///     case "PROCESSING":
///         // KYC under review
///     case "NEEDS_INFO":
///         // Additional information required
///     case "REJECTED":
///         // KYC rejected
///     default:
///         break
///     }
/// }
/// ```
///
/// ## Example: Set Status Callback
///
/// ```swift
/// // Get notified when KYC status changes
/// let callbackRequest = PutCustomerCallbackRequest(
///     url: "https://yourapp.com/kyc-callback",
///     jwt: jwtToken
/// )
///
/// let result = await kycService.putCustomerCallback(request: callbackRequest)
/// ```
///
/// ## Example: Delete Customer Data
///
/// ```swift
/// // Delete all customer information (GDPR compliance)
/// let result = await kycService.deleteCustomerInfo(
///     account: userAccountId,
///     jwt: jwtToken
/// )
/// ```
///
/// ## Error Handling
///
/// ```swift
/// let result = await kycService.putCustomerInfo(request: putRequest)
/// switch result {
/// case .success(let response):
///     // Handle success
/// case .failure(let error):
///     switch error {
///     case .badRequest(let message):
///         // Invalid field values or missing required fields
///     case .unauthorized(let message):
///         // JWT token invalid or expired
///     case .notFound(let message):
///         // Customer not found
///     case .payloadTooLarge(let message):
///         // File too large
///     case .horizonError(let horizonError):
///         // Network or server error
///     }
/// }
/// ```
///
/// ## Integration with Other SEPs
///
/// SEP-0012 is typically used alongside:
/// - **SEP-0010**: Required for authentication (JWT tokens)
/// - **SEP-6**: Non-interactive deposits/withdrawals requiring KYC
/// - **SEP-24**: Interactive deposits/withdrawals (may handle KYC in UI)
/// - **SEP-31**: Cross-border payments requiring sender/receiver KYC
///
/// ## Data Privacy
///
/// - Customer data is sensitive and should be transmitted securely
/// - Use HTTPS for all requests
/// - Implement proper data retention policies
/// - Provide data deletion functionality for GDPR compliance
/// - Store JWT tokens securely
///
/// See also:
/// - [SEP-0012 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
/// - [WebAuthenticator] for SEP-0010 authentication
/// - [TransferServerService] for SEP-6 integration
/// - [InteractiveService] for SEP-24 integration
public class KycService: NSObject {

    /// The base URL of the SEP-12 KYC service endpoint for customer information management.
    public var kycServiceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()

    /// Creates a KycService instance with a direct service endpoint URL.
    public init(kycServiceAddress:String) {
        self.kycServiceAddress = kycServiceAddress
        serviceHelper = ServiceHelper(baseURL: kycServiceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates a KycService instance based on information from the stellar.toml file for a given domain.
    @available(*, renamed: "forDomain(domain:)")
    public static func forDomain(domain:String, completion:@escaping KycServiceClosure) {
        Task {
            let result = await forDomain(domain: domain)
            completion(result)
        }
    }
    
    /// Creates a KycService instance based on information from the stellar.toml file for a given domain.
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
