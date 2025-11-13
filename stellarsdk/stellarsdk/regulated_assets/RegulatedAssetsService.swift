//
//  RegulatedAssetsService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 26.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Response enum for creating a RegulatedAssetsService instance from a domain.
///
/// Returned by `RegulatedAssetsService.forDomain()` methods.
public enum RegulatedAssetsServiceForDomainEnum {
    /// Service instance created successfully.
    case success(response: RegulatedAssetsService)
    /// Failed to create service instance.
    case failure(error: RegulatedAssetsServiceError)
}

/// Response enum for checking if an asset requires authorization.
///
/// Returned by `RegulatedAssetsService.authorizationRequired()` methods.
public enum AuthorizationRequiredEnum {
    /// Check completed, returns whether authorization is required.
    case success(required: Bool)
    /// Failed to check authorization requirement.
    case failure(error: HorizonRequestError)
}

/// Response enum for posting a transaction to a SEP-08 approval server.
///
/// Returned by `RegulatedAssetsService.postTransaction()` methods. Represents
/// the various possible outcomes defined in SEP-08.
public enum PostSep08TransactionEnum {
    /// Transaction approved without modifications.
    case success(response: Sep08PostTransactionSuccess)
    /// Transaction approved with modifications by the issuer.
    case revised(response: Sep08PostTransactionRevised)
    /// Transaction approval is pending, client should retry later.
    case pending(response: Sep08PostTransactionPending)
    /// User action is required before approval can proceed.
    case actionRequired(response: Sep08PostTransactionActionRequired)
    /// Transaction rejected by the approval server.
    case rejected(response: Sep08PostTransactionRejected)
    /// Request failed due to network or server error.
    case failure(error: HorizonRequestError)
}

/// Response enum for posting action data to a SEP-08 action URL.
///
/// Returned by `RegulatedAssetsService.postAction()` methods when responding
/// to an action_required status.
public enum PostSep08ActionEnum {
    /// Action completed successfully, no further action required.
    case done
    /// Client should follow the next URL provided.
    case nextUrl(response: Sep08PostActionNextUrl)
    /// Request failed due to network or server error.
    case failure(error: HorizonRequestError)
}

/// Closure type for receiving RegulatedAssetsService creation results.
public typealias RegulatedAssetsServiceClosure = (_ response:RegulatedAssetsServiceForDomainEnum) -> (Void)

/// Closure type for receiving authorization requirement check results.
public typealias AuthorizationRequiredClosure = (_ response:AuthorizationRequiredEnum) -> (Void)

/// Closure type for receiving SEP-08 transaction post results.
public typealias PostSep08TransactionClosure = (_ response:PostSep08TransactionEnum) -> (Void)

/// Closure type for receiving SEP-08 action post results.
public typealias PostSep08ActionClosure = (_ response:PostSep08ActionEnum) -> (Void)

/// Implements SEP-0008 - Regulated Assets.
///
/// This class enables issuers to validate and approve transactions involving regulated assets
/// before they are submitted to the network. Regulated assets require issuer approval for
/// transfers, ensuring compliance with securities regulations and KYC/AML requirements.
///
/// ## Typical Usage
///
/// ```swift
/// // Initialize from domain
/// let result = await RegulatedAssetsService.forDomain(
///     domain: "https://issuer.example.com",
///     network: .public
/// )
///
/// guard case .success(let service) = result else { return }
///
/// // Build transaction
/// let transaction = try Transaction(...)
/// let txXdr = try transaction.encodedEnvelope()
///
/// // Submit for approval
/// let approvalResult = await service.postTransaction(
///     txB64Xdr: txXdr,
///     apporvalServer: service.regulatedAssets[0].approvalServer
/// )
///
/// switch approvalResult {
/// case .success(let response):
///     // Transaction approved, submit to network
///     let approvedTx = try Transaction(envelopeXdr: response.tx)
/// case .revised(let response):
///     // Issuer revised transaction (e.g., added compliance fee)
///     let revisedTx = try Transaction(envelopeXdr: response.tx)
/// case .pending(let response):
///     // Approval pending, retry later
/// case .actionRequired(let response):
///     // User action needed (e.g., complete KYC)
/// case .rejected(let response):
///     // Transaction rejected
/// }
/// ```
///
/// See also:
/// - [SEP-0008 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md)
/// - [StellarToml] for discovering regulated assets
public class RegulatedAssetsService: NSObject {

    /// The parsed stellar.toml file containing asset and issuer information.
    public var tomlData:StellarToml

    /// The Stellar network this service operates on.
    public var network:Network

    /// The StellarSDK instance used for Horizon API interactions.
    public var sdk:StellarSDK

    /// List of regulated assets discovered from the stellar.toml file.
    public var regulatedAssets:[RegulatedAsset] = []

    private let jsonDecoder = JSONDecoder()

    /// Creates a new RegulatedAssetsService instance from parsed TOML data.
    ///
    /// - Parameter tomlData: The parsed stellar.toml file containing regulated asset information.
    /// - Parameter horizonUrl: Optional custom Horizon API URL. If not provided, uses URL from TOML or network default.
    /// - Parameter network: Optional network specification. If not provided, derives from TOML's network passphrase.
    /// - Throws: `RegulatedAssetsServiceError.invalidToml` if TOML data is invalid or missing required fields.
    public init(tomlData:StellarToml, horizonUrl: String? = nil, network:Network? = nil) throws {
        
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        
        self.tomlData = tomlData
        
        if let net = network {
            self.network = net
        }
        else if let netPassphrase = tomlData.accountInformation.networkPassphrase {
            self.network = Network.custom(passphrase: netPassphrase)
        } else {
            throw RegulatedAssetsServiceError.invalidToml
        }
        
        if let horizon = horizonUrl {
            self.sdk = StellarSDK(withHorizonUrl: horizon)
        }
        else {
            if let url = tomlData.accountInformation.horizonUrl {
                self.sdk = StellarSDK(withHorizonUrl: url)
            } else if self.network.networkId == Network.public.networkId {
                self.sdk = StellarSDK.publicNet()
            } else if self.network.networkId == Network.testnet.networkId {
                self.sdk = StellarSDK.testNet()
            } else if self.network.networkId == Network.futurenet.networkId {
                self.sdk = StellarSDK.futureNet()
            } else {
                throw RegulatedAssetsServiceError.invalidToml
            }
        }
        
        for currency in tomlData.currenciesDocumentation {
            if let code = currency.code, let issuer = currency.issuer, let regulated = currency.regulated, regulated, let approvalServer = currency.approvalServer {
                let type = code.count <= 4 ? AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 : AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
                if let asset = try RegulatedAsset(type:type, assetCode: code, issuerId: issuer, approvalServer:approvalServer, approvalCriteria: currency.approvalCriteria) {
                    regulatedAssets.append(asset)
                }
            }
        }
    }
    
    /// Creates a RegulatedAssetsService instance based on information from the stellar.toml file for a given domain.
    @available(*, renamed: "forDomain(domain:horizonUrl:network:)")
    public static func forDomain(domain:String,  horizonUrl: String? = nil, network:Network? = nil, completion:@escaping RegulatedAssetsServiceClosure) {
        Task {
            let result = await forDomain(domain: domain, horizonUrl: horizonUrl, network: network)
            completion(result)
        }
    }
    
    /// Creates a RegulatedAssetsService instance based on information from the stellar.toml file for a given domain.
    public static func forDomain(domain:String,  horizonUrl: String? = nil, network:Network? = nil) async -> RegulatedAssetsServiceForDomainEnum {
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            return .failure(error: .invalidDomain)
        }
        
        do {
            let tomlString = try String(contentsOf: url, encoding: .utf8)
            let toml = try StellarToml(fromString: tomlString)
            
            let service =  try RegulatedAssetsService(tomlData: toml, horizonUrl: horizonUrl, network: network)
            return .success(response: service)
            
        } catch {
            return .failure(error: .invalidToml)
        }
    }
    
    @available(*, renamed: "authorizationRequired(asset:)")
    public func authorizationRequired(asset: RegulatedAsset, completion:@escaping AuthorizationRequiredClosure) {
        Task {
            let result = await authorizationRequired(asset: asset)
            completion(result)
        }
    }

    /// Checks if a regulated asset requires authorization flags.
    ///
    /// Queries the issuer account to determine if both AUTH_REQUIRED and AUTH_REVOCABLE flags are set.
    ///
    /// - Parameter asset: The regulated asset to check.
    /// - Returns: `AuthorizationRequiredEnum` indicating whether authorization is required or if the check failed.
    public func authorizationRequired(asset: RegulatedAsset) async -> AuthorizationRequiredEnum {
        
        let response = await sdk.accounts.getAccountDetails(accountId: asset.issuerId)
        switch response {
        case .success(let accountDetails):
            var required = false
            if accountDetails.flags.authRequired && accountDetails.flags.authRevocable {
                required = true
            }
            return .success(required: required)
        case .failure(let error):
            return .failure(error: error)
        }
    }

    /// Sends a transaction to be evaluated and signed by the approval server.
    @available(*, renamed: "postTransaction(txB64Xdr:apporvalServer:)")
    public func postTransaction(txB64Xdr: String, apporvalServer:String, completion:@escaping PostSep08TransactionClosure) {
        Task {
            let result = await postTransaction(txB64Xdr: txB64Xdr, apporvalServer: apporvalServer)
            completion(result)
        }
    }
    
    /// Sends a transaction to be evaluated and signed by the approval server.
    public func postTransaction(txB64Xdr: String, apporvalServer:String) async -> PostSep08TransactionEnum {
        var txRequest = [String : Any]();
        txRequest["tx"] = txB64Xdr;
        
        let requestData = try! JSONSerialization.data(withJSONObject: txRequest)
        let serviceHelper = ServiceHelper(baseURL: apporvalServer)
        
        let result = await serviceHelper.POSTRequestWithPath(path: "", body: requestData, contentType: "application/json")
        switch result {
        case .success(let data):
            do {
                let statusResponse = try self.jsonDecoder.decode(Sep08PostTransactionStatusResponse.self, from: data)
                if "success" == statusResponse.status {
                    return .success(response:try self.jsonDecoder.decode(Sep08PostTransactionSuccess.self, from: data))
                } else if "revised" == statusResponse.status {
                    return .revised(response:try self.jsonDecoder.decode(Sep08PostTransactionRevised.self, from: data))
                } else if "pending" == statusResponse.status {
                    return .pending(response:try self.jsonDecoder.decode(Sep08PostTransactionPending.self, from: data))
                } else if "action_required" == statusResponse.status {
                    return .actionRequired(response:try self.jsonDecoder.decode(Sep08PostTransactionActionRequired.self, from: data))
                } else if "rejected" == statusResponse.status {
                    return .rejected(response:try self.jsonDecoder.decode(Sep08PostTransactionRejected.self, from: data))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "unknown sep08 post transaction response"))
                }
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let reqError):
            switch reqError {
            case .badRequest(let message, _):
                do {
                    let statusResponse = try self.jsonDecoder.decode(Sep08PostTransactionStatusResponse.self, from: Data(message.utf8))
                    if "rejected" == statusResponse.status {
                        return .rejected(response:try self.jsonDecoder.decode(Sep08PostTransactionRejected.self, from: Data(message.utf8)))
                    } else {
                        return .failure(error: reqError)
                    }
                } catch {
                    return .failure(error: reqError)
                }
            default:
                return .failure(error: reqError)
            }
        }
    }
    
    @available(*, renamed: "postAction(url:actionFields:)")
    public func postAction(url: String, actionFields:[String : Any], completion:@escaping PostSep08ActionClosure) {
        Task {
            let result = await postAction(url: url, actionFields: actionFields)
            completion(result)
        }
    }

    /// Posts action data to a SEP-08 action URL when user action is required.
    ///
    /// Used when the approval server returns an action_required status, requiring the user
    /// to provide additional information before transaction approval can proceed.
    ///
    /// - Parameter url: The action URL provided by the approval server.
    /// - Parameter actionFields: Dictionary of field names and values to submit.
    /// - Returns: `PostSep08ActionEnum` indicating the result of the action submission.
    public func postAction(url: String, actionFields:[String : Any]) async -> PostSep08ActionEnum {
        
        let requestData = try! JSONSerialization.data(withJSONObject: actionFields)
        let serviceHelper = ServiceHelper(baseURL: url)
        
        let result = await serviceHelper.POSTRequestWithPath(path: "", body: requestData, contentType: "application/json")
        switch result {
        case .success(let data):
            do {
                let resultResponse = try self.jsonDecoder.decode(Sep08PostActionResultResponse.self, from: data)
                if "no_further_action_required" == resultResponse.result {
                    return .done
                } else if "follow_next_url" == resultResponse.result {
                    return .nextUrl(response:try self.jsonDecoder.decode(Sep08PostActionNextUrl.self, from: data))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "unknown sep08 post action response"))
                }
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }

}

/// Represents a regulated asset that requires issuer approval for transactions.
///
/// A regulated asset is defined in stellar.toml with the `regulated` flag set to true
/// and includes an approval server URL where transactions must be submitted for validation.
public class RegulatedAsset:Asset {
    /// The asset code (e.g., "USD", "EURT").
    public var assetCode:String

    /// The Stellar account ID of the asset issuer.
    public var issuerId:String

    /// The URL of the approval server for transaction validation.
    public var approvalServer:String

    /// Optional criteria description for when transactions require approval.
    public var approvalCriteria:String?

    /// Creates a new regulated asset instance.
    ///
    /// - Parameter type: The asset type (ASSET_TYPE_CREDIT_ALPHANUM4 or ASSET_TYPE_CREDIT_ALPHANUM12).
    /// - Parameter assetCode: The asset code.
    /// - Parameter issuerId: The Stellar account ID of the issuer.
    /// - Parameter approvalServer: The URL of the approval server.
    /// - Parameter approvalCriteria: Optional description of approval criteria.
    /// - Throws: If the issuer ID is invalid.
    public init?(type:Int32, assetCode:String, issuerId:String, approvalServer:String, approvalCriteria:String? = nil) throws {
        self.approvalServer = approvalServer
        self.approvalCriteria = approvalCriteria
        self.assetCode = assetCode
        self.issuerId = issuerId
        super.init(type: type, code: assetCode, issuer: try KeyPair(accountId: issuerId))
    }
}

/// Errors that can occur during regulated assets service operations.
public enum RegulatedAssetsServiceError: Error {
    /// The provided domain is invalid or malformed.
    case invalidDomain
    /// The stellar.toml file is invalid, missing, or does not contain required fields.
    case invalidToml
    /// Failed to parse the response from the approval server.
    case parsingResponseFailed(message:String)
    /// The approval server returned a 400 Bad Request error.
    case badRequest(error:String)
    /// The requested resource was not found (404).
    case notFound(error:String)
    /// The request was not authorized (401).
    case unauthorized(message:String)
    /// An error occurred during Horizon API interaction.
    case horizonError(error: HorizonRequestError)
}

/// Response when a transaction is approved without modifications.
///
/// The approval server has validated and signed the transaction. The client should
/// submit it to the Stellar network.
public struct Sep08PostTransactionSuccess: Decodable {
    /// The approved transaction envelope in base64-encoded XDR format.
    public var tx: String

    /// Optional human-readable message from the approval server.
    public var message: String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case tx
        case message
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tx = try values.decode(String.self, forKey: .tx)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}

/// Response when a transaction is approved but with modifications.
///
/// The approval server has revised the transaction (e.g., added fees or compliance signatures)
/// and signed it. The client should submit the revised transaction to the network.
public struct Sep08PostTransactionRevised: Decodable {
    /// The revised and signed transaction envelope in base64-encoded XDR format.
    public var tx: String

    /// Human-readable explanation of the changes made to the transaction.
    public var message: String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case tx
        case message
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tx = try values.decode(String.self, forKey: .tx)
        message = try values.decode(String.self, forKey: .message)
    }
}

/// Response when transaction approval is pending.
///
/// The approval server is processing the transaction but has not yet made a decision.
/// The client should wait and retry after the specified timeout.
public struct Sep08PostTransactionPending: Decodable {
    /// Number of seconds the client should wait before retrying.
    public var timeout: Int = 0

    /// Optional human-readable explanation of why approval is pending.
    public var message: String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case timeout
        case message
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let rTimeout = try values.decodeIfPresent(Int.self, forKey: .timeout) {
            timeout = rTimeout
        }
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}

/// Response when user action is required before approval can proceed.
///
/// The approval server requires additional information from the user (e.g., KYC data).
/// The client should collect the required information and POST it to the action URL.
public struct Sep08PostTransactionActionRequired: Decodable {
    /// Human-readable description of the action required.
    public var message: String

    /// URL where the client should send the action data.
    public var actionUrl: String

    /// HTTP method to use when posting to the action URL (typically "POST").
    public var actionMethod: String = "GET"

    /// List of field names that should be included in the action request.
    public var actionFields:[String]?
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case message
        case actionUrl = "action_url"
        case actionMethod = "action_method"
        case actionFields = "action_fields"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        message = try values.decode(String.self, forKey: .message)
        actionUrl = try values.decode(String.self, forKey: .actionUrl)
        
        if let method = try values.decodeIfPresent(String.self, forKey: .actionMethod) {
            actionMethod = method
        }
        actionFields = try values.decodeIfPresent([String].self, forKey: .actionFields)
    }
}

/// Response when a transaction is rejected by the approval server.
///
/// The transaction does not meet the issuer's compliance requirements and cannot be approved.
public struct Sep08PostTransactionRejected: Decodable {
    /// Human-readable explanation of why the transaction was rejected.
    public var error: String
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case error
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        error = try values.decode(String.self, forKey: .error)
    }
}

/// Internal response struct used to determine the status of a transaction post.
///
/// Used for parsing the initial status field before decoding into the specific response type.
public struct Sep08PostTransactionStatusResponse: Decodable {
    /// The status value (success, revised, pending, action_required, or rejected).
    public var status: String?
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case status
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decodeIfPresent(String.self, forKey: .status)
    }
}

/// Internal response struct used to determine the result of an action post.
///
/// Used for parsing the result field to determine if action is complete or if another URL should be followed.
public struct Sep08PostActionResultResponse: Decodable {
    /// The result value (no_further_action_required or follow_next_url).
    public var result: String?
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case result
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        result = try values.decodeIfPresent(String.self, forKey: .result)
    }
}

/// Response when an action post requires following another URL.
///
/// The action was processed, but the client should follow the next URL for additional steps.
public struct Sep08PostActionNextUrl: Decodable {
    /// The next URL the client should navigate to or process.
    public var nextUrl: String

    /// Optional human-readable message explaining the next step.
    public var message: String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case nextUrl =  "next_url"
        case message
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        nextUrl = try values.decode(String.self, forKey: .nextUrl)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}
