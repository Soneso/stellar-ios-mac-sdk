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
    case invalidTimeBounds
    case invalidSignature
    case signatureNotFound
    case validationFailure
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
    private let authEndpoint: String
    private let serverSigningKey: String
    private let serviceHelper: ServiceHelper
    private let network: Network
    
    /// This can be used to ignore the timebounds values of the transaction. Its useful when the server time and client time are out of sync
    public var ignoreTimebounds = false
    
    /// Get a WebAuthenticator instange from a domain
    ///
    /// - Parameter domain: The domain from which to get the stellar information
    /// - Parameter network: The network used.
    /// - Parameter secure: The protocol used (http or https).
    ///
    /// - Throws:
    ///     - A WebAuthenticatorError describing the error.
    ///
    public static func from(domain: String, network:Network, secure: Bool = true, completion:@escaping WebAuthenticatorClosure) throws {
        try? StellarToml.from(domain: domain, secure: secure, completion: { (result) -> (Void) in
            switch result {
            case .success(let toml):
                if let authEndpoint = toml.accountInformation.webAuthEndpoint, let serverSigningKey = toml.accountInformation.signingKey {
                    completion(.success(response: WebAuthenticator(authEndpoint: authEndpoint, network: network, serverSigningKey: serverSigningKey)))
                } else {
                    completion(.failure(error: .noAuthEndpoint))
                }
            case .failure(let error):
                switch error {
                case .invalidDomain:
                    completion(.failure(error: .invalidToml))
                case .invalidToml:
                    completion(.failure(error: .invalidDomain))
                }
            }
        })
    }
    
    /// Init a WebAuthenticator instange
    ///
    /// - Parameter authEndpoint: Endpoint to be used for the authentication procedure. Usually taken from stellar.toml.
    /// - Parameter network: The network used.
    /// - Parameter serverSigningKey: The server public key. Usually taken from stellar.toml.
    ///
    public init(authEndpoint:String, network:Network, serverSigningKey:String) {
        self.authEndpoint = authEndpoint
        self.serverSigningKey = serverSigningKey
        serviceHelper = ServiceHelper(baseURL: authEndpoint)
        self.network = network
    }
    
    /// Get JWT token for wallet
    ///
    /// - Parameter keyPair: The keypair of the wallet to get the JWT token for.
    ///
    public func jwtToken(forKeyPair keyPair:KeyPair, completion:@escaping GetJWTTokenResponseClosure) {
        getChallenge(forAccount: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let challenge):
                do {
                    let transactionEnvelope = try TransactionEnvelopeXDR(xdr: challenge)
                    let challengeValid = self.isValidChallenge(transactionEnvelopeXDR: transactionEnvelope, userAccountId: keyPair.accountId, serverSigningKey: self.serverSigningKey)
                    switch challengeValid {
                    case .success:
                        if let signedTransaction = self.signTransaction(transactionEnvelopeXDR: transactionEnvelope, userKeyPair: keyPair) {
                            self.sendCompletedChallenge(base64EnvelopeXDR: signedTransaction, completion: { (response) -> (Void) in
                                switch response {
                                case .success(let jwtToken):
                                    completion(.success(jwtToken: jwtToken))
                                case .failure(let error):
                                    completion(.failure(error: .requestError(error)))
                                }
                            })
                        } else {
                            completion(.failure(error: .signingError))
                        }
                    case .failure(let error):
                        completion(.failure(error: .validationErrorError(error)))
                    }
                } catch let error {
                    completion(.failure(error: .parsingError(error)))
                }
            case .failure(let error):
                completion(.failure(error: .requestError(error)))
            }
        }
    }
    
    private func getChallenge(forAccount accountId:String, completion:@escaping ChallengeResponseClosure) {
        serviceHelper.GETRequestWithPath(path: "?account=\(accountId)") { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let challenge = response?["transaction"] as? String {
                        completion(.success(challenge: challenge))
                    } else if let error = response?["error"] as? String {
                        completion(.failure(error: .requestFailed(message: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON")))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON")))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    private func isValidChallenge(transactionEnvelopeXDR: TransactionEnvelopeXDR, userAccountId: String, serverSigningKey: String) -> ChallengeValidationResponseEnum {
        do {
            let transactionXDR = transactionEnvelopeXDR.tx
            
            if (transactionXDR.seqNum != 0) {
                return .failure(error: .sequenceNumberNot0)
            }
            
            // the transaction must contain one operation
            if transactionXDR.operations.count == 1, let operationXDR = transactionXDR.operations.first {
                // the source account of the operation must match
                if let operationSourceAccount = operationXDR.sourceAccount {
                    if (operationSourceAccount.accountId != userAccountId) {
                        return .failure(error: .invalidSourceAccount)
                    }
                } else {
                    return .failure(error: .sourceAccountNotFound)
                }
                
                //operation must be manage data operation
                let operationBodyXDR = operationXDR.body
                if (operationBodyXDR.type() != OperationType.manageData.rawValue) {
                    return .failure(error: .invalidOperationType)
                }
                
            } else {
                return .failure(error: .invalidOperationCount)
            }
            
            if !ignoreTimebounds, let minTime = transactionXDR.timeBounds?.minTime, let maxTime = transactionXDR.timeBounds?.maxTime {
                let currentTimestamp = Date().timeIntervalSince1970
                if (currentTimestamp < TimeInterval(minTime)) || (currentTimestamp > TimeInterval(maxTime)) {
                    return .failure(error: .invalidTimeBounds)
                }
            }
            
            // the envelope must have one signature and it must be valid: transaction signed by the server
            if transactionEnvelopeXDR.signatures.count == 1, let signature = transactionEnvelopeXDR.signatures.first?.signature {
                // transaction hash is the signed payload
                let transactionHash = try [UInt8](transactionXDR.hash(network: network))
                
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
    
    private func signTransaction(transactionEnvelopeXDR: TransactionEnvelopeXDR, userKeyPair: KeyPair) -> String? {
        let envelopeXDR = transactionEnvelopeXDR
        do {
            let tx = envelopeXDR.tx
            
            // user signature
            let transactionHash = try [UInt8](tx.hash(network: network))
            let userSignature = userKeyPair.signDecorated(transactionHash)
            
            envelopeXDR.signatures.append(userSignature)
            
            if let xdrEncodedEnvelope = envelopeXDR.xdrEncoded {
                return xdrEncodedEnvelope
            } else {
                return nil
            }
        } catch _ {
            return nil
        }
    }
    
    private func sendCompletedChallenge(base64EnvelopeXDR: String, completion:@escaping SendChallengeResponseClosure) {
        let json = ["transaction": base64EnvelopeXDR]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        serviceHelper.POSTRequestWithPath(path: "", body: jsonData) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let token = response?["token"] as? String {
                        completion(.success(jwtToken: token))
                    } else if let error = response?["error"] as? String {
                        completion(.failure(error: .requestFailed(message: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON")))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON")))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
}
