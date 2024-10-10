//
//  RegulatedAssetsService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 26.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public enum RegulatedAssetsServiceForDomainEnum {
    case success(response: RegulatedAssetsService)
    case failure(error: RegulatedAssetsServiceError)
}

public enum AuthorizationRequiredEnum {
    case success(required: Bool)
    case failure(error: HorizonRequestError)
}

public enum PostSep08TransactionEnum {
    case success(response: Sep08PostTransactionSuccess)
    case revised(response: Sep08PostTransactionRevised)
    case pending(response: Sep08PostTransactionPending)
    case actionRequired(response: Sep08PostTransactionActionRequired)
    case rejected(response: Sep08PostTransactionRejected)
    case failure(error: HorizonRequestError)
}

public enum PostSep08ActionEnum {
    case done
    case nextUrl(response: Sep08PostActionNextUrl)
    case failure(error: HorizonRequestError)
}

public typealias RegulatedAssetsServiceClosure = (_ response:RegulatedAssetsServiceForDomainEnum) -> (Void)
public typealias AuthorizationRequiredClosure = (_ response:AuthorizationRequiredEnum) -> (Void)
public typealias PostSep08TransactionClosure = (_ response:PostSep08TransactionEnum) -> (Void)
public typealias PostSep08ActionClosure = (_ response:PostSep08ActionEnum) -> (Void)

/**
 Implements SEP-0008 - Regulated Assets
 See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md" target="_blank">Regulated Assets</a>
 */

public class RegulatedAssetsService: NSObject {
    
    public var tomlData:StellarToml
    public var network:Network
    public var sdk:StellarSDK
    public var regulatedAssets:[RegulatedAsset] = []
    
    private let jsonDecoder = JSONDecoder()
    
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
    
    /// Creates a RegulatedAssetsService instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
    @available(*, renamed: "forDomain(domain:horizonUrl:network:)")
    public static func forDomain(domain:String,  horizonUrl: String? = nil, network:Network? = nil, completion:@escaping RegulatedAssetsServiceClosure) {
        Task {
            let result = await forDomain(domain: domain, horizonUrl: horizonUrl, network: network)
            completion(result)
        }
    }
    
    /// Creates a RegulatedAssetsService instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
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

public class RegulatedAsset:Asset {
    public var assetCode:String
    public var issuerId:String
    public var approvalServer:String
    public var approvalCriteria:String?
    
    public init?(type:Int32, assetCode:String, issuerId:String, approvalServer:String, approvalCriteria:String? = nil) throws {
        self.approvalServer = approvalServer
        self.approvalCriteria = approvalCriteria
        self.assetCode = assetCode
        self.issuerId = issuerId
        super.init(type: type, code: assetCode, issuer: try KeyPair(accountId: issuerId))
    }
}

public enum RegulatedAssetsServiceError: Error {
    case invalidDomain
    case invalidToml
    case parsingResponseFailed(message:String)
    case badRequest(error:String) // 400
    case notFound(error:String) // 404
    case unauthorized(message:String) // 401
    case horizonError(error: HorizonRequestError)
}


public struct Sep08PostTransactionSuccess: Decodable {

    public var tx: String
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

public struct Sep08PostTransactionRevised: Decodable {

    public var tx: String
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

public struct Sep08PostTransactionPending: Decodable {

    public var timeout: Int = 0
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


public struct Sep08PostTransactionActionRequired: Decodable {

    public var message: String
    public var actionUrl: String
    public var actionMethod: String = "GET"
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

public struct Sep08PostTransactionRejected: Decodable {

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

public struct Sep08PostTransactionStatusResponse: Decodable {

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

public struct Sep08PostActionResultResponse: Decodable {

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


public struct Sep08PostActionNextUrl: Decodable {

    public var nextUrl: String
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
