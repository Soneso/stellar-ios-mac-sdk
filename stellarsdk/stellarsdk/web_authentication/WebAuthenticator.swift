//
//  WebAuthentication.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 15/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Endpoint errors.
public enum WebAuthenticatorError: Error {
    case invalidDomain
    case invalidToml
    case noAuthEndpoint
}

/// Challenge validation errors.
public enum ChallengeValidationError: Error {
    case sequenceNumberNot0
    case invalidSourceAccount
    case sourceAccountNotFound
    case invalidOperationType
    case invalidOperationCount
    case invalidHomeDomain
    case invalidTimeBounds
    case invalidSignature
    case signatureNotFound
    case validationFailure
    case invalidTransactionType
    case invalidWebAuthDomain
    case memoAndMuxedSourceAccountFound
    case invalidMemoType
    case invalidMemoValue
}

/// Possible errors received from a JWT token response.
public enum GetJWTTokenError: Error {
    case requestError(HorizonRequestError)
    case parsingError(Error)
    case validationErrorError(ChallengeValidationError)
    case signingError
    
}

/// An enum used to diferentiate between successful and failed WebAuthenticator for domain responses.
public enum WebAuthenticatorForDomainEnum {
    case success(response: WebAuthenticator)
    case failure(error: WebAuthenticatorError)
}

/// An enum used to diferentiate between successful and failed get challenge responses.
public enum ChallengeResponseEnum {
    case success(challenge: String)
    case failure(error: HorizonRequestError)
}

/// An enum used to diferentiate between successful and failed post challenge responses.
public enum SendChallengeResponseEnum {
    case success(jwtToken: String)
    case failure(error: HorizonRequestError)
}

/// An enum used to diferentiate between successful and failed get JWT token responses.
public enum GetJWTTokenResponseEnum {
    case success(jwtToken: String)
    case failure(error: GetJWTTokenError)
}

/// Challenge validation response enum.
public enum ChallengeValidationResponseEnum {
    case success
    case failure(error: ChallengeValidationError)
}

/// A closure to be called with the response from a WebAuthenticator for domain request.
public typealias WebAuthenticatorClosure = (_ response:WebAuthenticatorForDomainEnum) -> (Void)

/// A closure to be called with the response from a get challenge request.
public typealias ChallengeResponseClosure = (_ response:ChallengeResponseEnum) -> (Void)

/// A closure to be called with the response from a post challenge request.
public typealias SendChallengeResponseClosure = (_ response:SendChallengeResponseEnum) -> (Void)

/// A closure to be called with the response from a get JWT token request.
public typealias GetJWTTokenResponseClosure = (_ response:GetJWTTokenResponseEnum) -> (Void)

public class WebAuthenticator {
    public let authEndpoint: String
    public let serverSigningKey: String
    private let serviceHelper: ServiceHelper
    public let network: Network
    public let serverHomeDomain: String
    public let gracePeriod:UInt64 = SEPConstants.WEBAUTH_GRACE_PERIOD_SECONDS
    
    /// Get a WebAuthenticator instange from a domain
    ///
    /// - Parameter domain: The domain from which to get the stellar information
    /// - Parameter network: The network used.
    /// - Parameter secure: The protocol used (http or https).
    ///
    @available(*, renamed: "from(domain:network:secure:)")
    public static func from(domain: String, network:Network, secure: Bool = true, completion:@escaping WebAuthenticatorClosure) {
        Task {
            let result = await from(domain: domain, network: network, secure: secure)
            completion(result)
        }
    }
    
    /// Get a WebAuthenticator instange from a domain
    ///
    /// - Parameter domain: The domain from which to get the stellar information
    /// - Parameter network: The network used.
    /// - Parameter secure: The protocol used (http or https).
    ///
    public static func from(domain: String, network:Network, secure: Bool = true) async -> WebAuthenticatorForDomainEnum {
        let result = await StellarToml.from(domain: domain, secure: secure)
        switch result {
        case .success(let toml):
            if let authEndpoint = toml.accountInformation.webAuthEndpoint, let serverSigningKey = toml.accountInformation.signingKey {
                return .success(response: WebAuthenticator(authEndpoint: authEndpoint, network: network, serverSigningKey: serverSigningKey, serverHomeDomain: domain))
            } else {
                return .failure(error: .noAuthEndpoint)
            }
        case .failure(let error):
            switch error {
            case .invalidDomain:
                return .failure(error: .invalidToml)
            case .invalidToml:
                return .failure(error: .invalidDomain)
            }
        }
    }
    
    /// Init a WebAuthenticator instange
    ///
    /// - Parameter authEndpoint: Endpoint to be used for the authentication procedure. Usually taken from stellar.toml.
    /// - Parameter network: The network used.
    /// - Parameter serverSigningKey: The server public key, taken from stellar.toml.
    /// - Parameter serverHomeDomain: The server home domain of the server where the stellar.toml was loaded from
    ///
    public init(authEndpoint:String, network:Network, serverSigningKey:String, serverHomeDomain:String) {
        self.authEndpoint = authEndpoint
        self.serverSigningKey = serverSigningKey
        serviceHelper = ServiceHelper(baseURL: authEndpoint)
        self.network = network
        self.serverHomeDomain = serverHomeDomain
    }
    
    /// Get JWT token for wallet
    ///
    /// - Parameter forUserAccount: account id of the user
    /// - Parameter memo: ID memo of the client account if muxed and accountId starts with G
    /// - Parameter signers: list of signers (keypairs including secret seed) of the client account
    /// - Parameter homeDomain: domain of the server hosting it's stellar.toml
    /// - Parameter clientDomain: domain of the client hosting it's stellar.toml
    /// - Parameter clientDomainAccountKeyPair: Keypair of the client domain account including the seed (used for signing the transaction if client domain is provided)
    @available(*, deprecated, message: "use jwtToken(forUserAccount:memo:signers:homeDomain:clientDomain:clientDomainAccountKeyPair:clientDomainSigningFunction:) instead")
    public func jwtToken(forUserAccount accountId:String, memo:UInt64? = nil, signers:[KeyPair], homeDomain:String? = nil, clientDomain:String? = nil, clientDomainAccountKeyPair:KeyPair? = nil, completion:@escaping GetJWTTokenResponseClosure) {
        Task {
            let result = await jwtToken(forUserAccount: accountId, memo: memo, signers: signers, homeDomain: homeDomain, clientDomain: clientDomain, clientDomainAccountKeyPair: clientDomainAccountKeyPair)
            completion(result)
        }
    }
    
    /// Get JWT token for wallet
    ///
    /// - Parameter forUserAccount: account id of the user
    /// - Parameter memo: ID memo of the client account if muxed and accountId starts with G
    /// - Parameter signers: list of signers (keypairs including secret seed) of the client account
    /// - Parameter homeDomain: domain of the server hosting it's stellar.toml
    /// - Parameter clientDomain: domain of the client server hosting it's stellar.toml for client domain signing
    /// - Parameter clientDomainAccountKeyPair: Keypair of the client domain account. Needed if clientDomain is provided. If it includes the private key, it will be used for signing the transaction (client domain signer). If it only contains the account id (public key) the client domain signing can be done via a signing function that can be passed by the parameter clientDomainSigningFunction
    /// - Parameter clientDomainSigningFunction: a function that signs the transaction if clientDomain is provided but the provided clientDomainAccountKeyPair does not have a private key. Should accept a base64 encoded transaction envelope xdr string, sign it and send the signed transaction back as base64 encoded transaction envelope xdr string. This is normally used, when the client domain signing takes place on a server and you don't have the client domain signing seed in your app.
    public func jwtToken(forUserAccount accountId:String, memo:UInt64? = nil, signers:[KeyPair], homeDomain:String? = nil, clientDomain:String? = nil, clientDomainAccountKeyPair:KeyPair? = nil, clientDomainSigningFunction:((_:String) async throws -> String)? = nil) async -> GetJWTTokenResponseEnum {
        let response = await getChallenge(forAccount: accountId, memo: memo, homeDomain: homeDomain, clientDomain: clientDomain)
        switch response {
        case .success(let challenge):
            do {
                let transactionEnvelope = try TransactionEnvelopeXDR(xdr: challenge)
                var clientDomainAccount:String?
                if let clientDomainAccountKeyPair = clientDomainAccountKeyPair {
                    clientDomainAccount = clientDomainAccountKeyPair.accountId
                }
                let challengeValid = self.isValidChallenge(transactionEnvelopeXDR: transactionEnvelope, userAccountId: accountId, memo:memo, serverSigningKey: self.serverSigningKey, clientDomainAccount: clientDomainAccount, timeBoundsGracePeriod: self.gracePeriod)
                switch challengeValid {
                case .success:
                    var keyPairs:[KeyPair] = [KeyPair]()
                    keyPairs.append(contentsOf: signers)
                    if let clientDomainAccountKeyPair = clientDomainAccountKeyPair, clientDomainAccountKeyPair.privateKey != nil {
                        keyPairs.append(clientDomainAccountKeyPair)
                    }
                    if var signedTransaction = self.signTransaction(transactionEnvelopeXDR: transactionEnvelope, keyPairs: keyPairs) {
                        if let clientDomainSigningFunction = clientDomainSigningFunction,
                            let clientDomainAccountKeyPair = clientDomainAccountKeyPair,
                           clientDomainAccountKeyPair.privateKey == nil {
                            
                            signedTransaction = try await clientDomainSigningFunction(signedTransaction)
                        }
                        
                        let response = await self.sendCompletedChallenge(base64EnvelopeXDR: signedTransaction)
                        switch response {
                        case .success(let jwtToken):
                            return .success(jwtToken: jwtToken)
                        case .failure(let error):
                            return .failure(error: .requestError(error))
                        }
                    } else {
                        return .failure(error: .signingError)
                    }
                case .failure(let error):
                    return .failure(error: .validationErrorError(error))
                }
            } catch let error {
                return .failure(error: .parsingError(error))
            }
        case .failure(let error):
            return .failure(error: .requestError(error))
        }
    }
    
    @available(*, renamed: "getChallenge(forAccount:memo:homeDomain:clientDomain:)")
    public func getChallenge(forAccount accountId:String, memo:UInt64? = nil, homeDomain:String? = nil, clientDomain:String? = nil, completion:@escaping ChallengeResponseClosure) {
        Task {
            let result = await getChallenge(forAccount: accountId, memo: memo, homeDomain: homeDomain, clientDomain: clientDomain)
            completion(result)
        }
    }
    
    
    public func getChallenge(forAccount accountId:String, memo:UInt64? = nil, homeDomain:String? = nil, clientDomain:String? = nil) async -> ChallengeResponseEnum {
        
        var path = (homeDomain != nil) ? "?account=\(accountId)&home_domain=\(homeDomain!)" : "?account=\(accountId)"
        
        if let cd = clientDomain {
            path.append("&client_domain=\(cd)");
        }
        
        if let mid = memo {
            if accountId.starts(with: "G") {
                path.append("&memo=\(mid)");
            } else {
                return .failure(error: .requestFailed(message: "memo cannot be used if accountId is a muxed account", horizonErrorResponse: nil))
            }
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: path)
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let challenge = response["transaction"] as? String {
                    return .success(challenge: challenge)
                } else if let error = response["error"] as? String {
                    return .failure(error: .requestFailed(message: error, horizonErrorResponse: nil))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON"))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON"))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    public func isValidChallenge(transactionEnvelopeXDR: TransactionEnvelopeXDR, userAccountId: String, memo:UInt64? = nil, serverSigningKey: String, clientDomainAccount:String? = nil, timeBoundsGracePeriod:UInt64? = nil) -> ChallengeValidationResponseEnum {
        do {
            switch transactionEnvelopeXDR {
            case .feeBump(_):
                return .failure(error: .invalidTransactionType)
            default:
                break
            }
            
            if (transactionEnvelopeXDR.txSeqNum != 0) {
                return .failure(error: .sequenceNumberNot0)
            }
            
            if transactionEnvelopeXDR.txMemo.type() != MemoType.MEMO_TYPE_NONE {
                if userAccountId.starts(with: "M") {
                    return .failure(error: .memoAndMuxedSourceAccountFound)
                } else if transactionEnvelopeXDR.txMemo.type() != MemoType.MEMO_TYPE_ID {
                    return .failure(error: .invalidMemoType)
                } else if let mval = memo {
                    switch transactionEnvelopeXDR.txMemo {
                    case .id(let value):
                        if value != mval {
                            return .failure(error: .invalidMemoValue)
                        }
                    default:
                        return .failure(error: .invalidMemoValue)
                    }
                } else {
                    return .failure(error: .invalidMemoValue)
                }
            } else if memo != nil {
                return .failure(error: .invalidMemoValue)
            }
            
            var index = 0
            for operationXDR in transactionEnvelopeXDR.txOperations {
                if let operationSourceAccount = operationXDR.sourceAccount {
                    if (index == 0 && operationSourceAccount.accountId != userAccountId) {
                        return .failure(error: .invalidSourceAccount)
                    }
                    // the source account of additional operations must be the SEP-10 server's SIGNING_KEY
                    // except data name is "client_domain"
                    if (index > 0 && operationSourceAccount.accountId != serverSigningKey) {
                        let operationBodyXDR = operationXDR.body
                        switch operationBodyXDR {
                        case .manageData(let manageDataOperation):
                            if (manageDataOperation.dataName != "client_domain") {
                                return .failure(error: .invalidSourceAccount)
                            } else if (operationSourceAccount.accountId != clientDomainAccount) {
                                return .failure(error: .invalidSourceAccount)
                            }
                            break
                        default:
                            return .failure(error: .invalidOperationType)
                        }
                    }
                } else {
                    return .failure(error: .sourceAccountNotFound)
                }
                
                //all operations must be manage data operations
                let operationBodyXDR = operationXDR.body
                switch operationBodyXDR {
                case .manageData(let manageDataOperation):
                    if (index == 0 && manageDataOperation.dataName != (self.serverHomeDomain + " auth")) {
                        return .failure(error: .invalidHomeDomain)
                    } else if (manageDataOperation.dataName == "web_auth_domain") {
                        if let dataValue = manageDataOperation.dataValue,
                           let url = URL(string: self.authEndpoint),
                           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let host = components.host {
                            
                            let webAuthDomain = String(decoding: dataValue, as: UTF8.self)
                            if webAuthDomain != host {
                                return .failure(error: .invalidWebAuthDomain)
                            }
                            
                        } else {
                            return .failure(error: .invalidWebAuthDomain)
                        }
                    }
                    break
                default:
                    return .failure(error: .invalidOperationType)
                }
                index += 1
            }
            
            if index == 0 {
                return .failure(error: .invalidOperationCount)
            }
            
            if let minTime = transactionEnvelopeXDR.txTimeBounds?.minTime, let maxTime = transactionEnvelopeXDR.txTimeBounds?.maxTime {
                let currentTimestamp = Date().timeIntervalSince1970
                var grace:UInt64 = 0
                if let pgrace = timeBoundsGracePeriod {
                    grace = pgrace
                }
                if (currentTimestamp < TimeInterval(minTime - grace)) || (currentTimestamp > TimeInterval(maxTime + grace)) {
                    return .failure(error: .invalidTimeBounds)
                }
            }
            
            // the envelope must have one signature and it must be valid: transaction signed by the server
            if transactionEnvelopeXDR.txSignatures.count == 1, let signature = transactionEnvelopeXDR.txSignatures.first?.signature {
                // transaction hash is the signed payload
                let transactionHash = try [UInt8](transactionEnvelopeXDR.txHash(network: network))
                
                // validate signature
                let serverKeyPair = try KeyPair(accountId: serverSigningKey)
                let signatureIsValid = try serverKeyPair.verify(signature: [UInt8](signature), message: transactionHash)
                if signatureIsValid {
                    return .success
                } else { // signature is not valid
                    return .failure(error: .invalidSignature)
                }
            } else {
                return .failure(error: .signatureNotFound)
            }
        } catch {
            return .failure(error: .validationFailure)
        }
    }
    
    public func signTransaction(transactionEnvelopeXDR: TransactionEnvelopeXDR, keyPairs:[KeyPair]) -> String? {
        let envelopeXDR = transactionEnvelopeXDR
        do {
            switch envelopeXDR {
            case .feeBump(_):
                return nil
            default:
                break
            }
            
            // user signature
            let transactionHash = try [UInt8](envelopeXDR.txHash(network: network))
            for kp in keyPairs {
                let userSignature = kp.signDecorated(transactionHash)
                envelopeXDR.appendSignature(signature: userSignature)
            }
            
            if let xdrEncodedEnvelope = envelopeXDR.xdrEncoded {
                return xdrEncodedEnvelope
            } else {
                return nil
            }
        } catch _ {
            return nil
        }
    }
    
    @available(*, renamed: "sendCompletedChallenge(base64EnvelopeXDR:)")
    public func sendCompletedChallenge(base64EnvelopeXDR: String, completion:@escaping SendChallengeResponseClosure) {
        Task {
            let result = await sendCompletedChallenge(base64EnvelopeXDR: base64EnvelopeXDR)
            completion(result)
        }
    }
    
    
    public func sendCompletedChallenge(base64EnvelopeXDR: String) async -> SendChallengeResponseEnum {
        let json = ["transaction": base64EnvelopeXDR]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let result = await serviceHelper.POSTRequestWithPath(path: "", body: jsonData, contentType: "application/json")
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let token = response["token"] as? String {
                    return .success(jwtToken: token)
                } else if let error = response["error"] as? String {
                    return .failure(error: .requestFailed(message: error, horizonErrorResponse: nil))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON"))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON"))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
}
