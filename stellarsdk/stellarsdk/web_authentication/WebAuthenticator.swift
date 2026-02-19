//
//  WebAuthentication.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 15/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors that occur during WebAuthenticator initialization.
public enum WebAuthenticatorError: Error, Sendable {
    /// The provided domain is not a valid URL or domain format.
    case invalidDomain
    /// The stellar.toml file could not be parsed or is malformed.
    case invalidToml
    /// The stellar.toml file does not specify a WEB_AUTH_ENDPOINT.
    case noAuthEndpoint
}

/// Challenge validation errors.
public enum ChallengeValidationError: Error, Sendable {
    /// The transaction sequence number is not 0 as required by SEP-10.
    case sequenceNumberNot0
    /// The source account of an operation does not match the expected account.
    case invalidSourceAccount
    /// An operation is missing the required source account field.
    case sourceAccountNotFound
    /// An operation type is not allowed in the challenge transaction.
    case invalidOperationType
    /// The number of operations in the challenge transaction is invalid.
    case invalidOperationCount
    /// The home domain in the challenge does not match the expected domain.
    case invalidHomeDomain
    /// The transaction time bounds are invalid or expired.
    case invalidTimeBounds
    /// The server signature on the challenge transaction is invalid.
    case invalidSignature
    /// The required server signature is missing from the challenge transaction.
    case signatureNotFound
    /// General validation failure occurred during challenge verification.
    case validationFailure
    /// The transaction type is not supported for SEP-10 challenges.
    case invalidTransactionType
    /// The web_auth_domain value does not match the authentication endpoint domain.
    case invalidWebAuthDomain
    /// Both a memo and muxed source account were provided, which is not allowed.
    case memoAndMuxedSourceAccountFound
    /// The memo type in the challenge transaction is not the expected type.
    case invalidMemoType
    /// The memo value does not match the expected value.
    case invalidMemoValue
}

/// Possible errors received from a JWT token response.
public enum GetJWTTokenError: Error, Sendable {
    /// Network or server request failed during SEP-10 authentication flow.
    case requestError(HorizonRequestError)
    /// Failed to parse server response or transaction data.
    case parsingError(Error)
    /// Challenge transaction validation failed due to security or protocol violation.
    case validationErrorError(ChallengeValidationError)
    /// Failed to sign the challenge transaction with the provided signing key.
    case signingError
}

/// Result enum for creating a WebAuthenticator instance from a domain's stellar.toml file.
public enum WebAuthenticatorForDomainEnum: Sendable {
    /// Successfully created WebAuthenticator instance with endpoint from stellar.toml.
    case success(response: WebAuthenticator)
    /// Failed to create authenticator due to invalid domain, malformed TOML, or missing WEB_AUTH_ENDPOINT.
    case failure(error: WebAuthenticatorError)
}

/// Result enum for SEP-10 challenge transaction requests.
public enum ChallengeResponseEnum: Sendable {
    /// Successfully retrieved challenge transaction from authentication server.
    case success(challenge: String)
    /// Failed to retrieve challenge due to network or server error.
    case failure(error: HorizonRequestError)
}

/// Result enum for submitting signed challenge transactions.
public enum SendChallengeResponseEnum: Sendable {
    /// Successfully submitted signed challenge and received JWT authentication token.
    case success(jwtToken: String)
    /// Failed to submit signed challenge due to invalid signature or server error.
    case failure(error: HorizonRequestError)
}

/// Result enum for complete SEP-10 authentication flow.
public enum GetJWTTokenResponseEnum: Sendable {
    /// Successfully completed SEP-10 authentication and received JWT token.
    case success(jwtToken: String)
    /// Failed to complete authentication due to request, validation, or signing error.
    case failure(error: GetJWTTokenError)
}

/// Result enum for challenge transaction validation.
public enum ChallengeValidationResponseEnum: Sendable {
    /// Challenge transaction passed all SEP-10 validation requirements.
    case success
    /// Challenge validation failed due to security or protocol violation.
    case failure(error: ChallengeValidationError)
}

/// Implements SEP-0010 - Stellar Web Authentication.
///
/// This class provides functionality for authenticating users through the Stellar Web Authentication protocol,
/// which allows clients to prove they possess the signing key for a Stellar account. The authentication flow
/// returns a JWT token that can be used for subsequent requests to SEP-compliant services (SEP-6, SEP-12, SEP-24, SEP-31).
///
/// SEP-0010 defines a standard protocol for proving account ownership without transmitting secret keys.
/// The server generates a challenge transaction that the client signs with their account's signing key,
/// proving ownership without revealing the secret key itself.
///
/// ## Typical Workflow
///
/// 1. **Initialize from Domain**: Create a WebAuthenticator instance using the anchor's stellar.toml
/// 2. **Get JWT Token**: Request and obtain a JWT token for authentication
/// 3. **Use Token**: Include the JWT token in subsequent SEP service requests
///
/// ## Example Usage
///
/// ```swift
/// // Step 1: Create WebAuthenticator from anchor domain
/// let result = await WebAuthenticator.from(
///     domain: "https://testanchor.stellar.org",
///     network: .testnet
/// )
///
/// switch result {
/// case .success(let webAuth):
///     // Step 2: Get JWT token for user account
///     let userKeyPair = try KeyPair(secretSeed: "S...")
///     let jwtResult = await webAuth.jwtToken(
///         forUserAccount: userKeyPair.accountId,
///         signers: [userKeyPair],
///         homeDomain: "testanchor.stellar.org"
///     )
///
///     switch jwtResult {
///     case .success(let jwtToken):
///         // Step 3: Use JWT token for SEP-24, SEP-6, SEP-12, etc.
///         print("JWT Token: \(jwtToken)")
///     case .failure(let error):
///         print("JWT token error: \(error)")
///     }
/// case .failure(let error):
///     print("WebAuth initialization error: \(error)")
/// }
/// ```
///
/// ## Advanced Features
///
/// **Multi-Signature Accounts:**
/// ```swift
/// // Provide multiple signers for accounts requiring multiple signatures
/// let signers = [keyPair1, keyPair2, keyPair3]
/// let result = await webAuth.jwtToken(
///     forUserAccount: accountId,
///     signers: signers
/// )
/// ```
///
/// **Muxed Accounts:**
/// ```swift
/// // For muxed accounts starting with M, provide memo
/// let result = await webAuth.jwtToken(
///     forUserAccount: "M...",
///     memo: 12345,
///     signers: [keyPair]
/// )
/// ```
///
/// **Client Domain Signing:**
/// ```swift
/// // For client domain verification (mutual authentication)
/// let clientDomainKeyPair = try KeyPair(accountId: "G...")
/// let result = await webAuth.jwtToken(
///     forUserAccount: userAccountId,
///     signers: [userKeyPair],
///     clientDomain: "wallet.example.com",
///     clientDomainAccountKeyPair: clientDomainKeyPair,
///     clientDomainSigningFunction: { txXdr in
///         // Sign on server and return signed transaction
///         return try await signOnServer(txXdr)
///     }
/// )
/// ```
///
/// ## Authentication Flow Details
///
/// The SEP-0010 authentication process involves:
///
/// 1. Client requests a challenge transaction from the server
/// 2. Server returns a transaction with specific operations and time bounds
/// 3. Client validates the challenge transaction
/// 4. Client signs the transaction with their account key(s)
/// 5. Client submits the signed transaction to the server
/// 6. Server validates signatures and returns a JWT token
///
/// The JWT token typically expires after 24 hours and must be refreshed.
///
/// ## Error Handling
///
/// ```swift
/// let result = await webAuth.jwtToken(forUserAccount: accountId, signers: signers)
/// switch result {
/// case .success(let token):
///     // Use token
/// case .failure(let error):
///     switch error {
///     case .requestError(let horizonError):
///         // Network or server error
///     case .validationErrorError(let validationError):
///         // Challenge validation failed
///     case .signingError:
///         // Transaction signing failed
///     case .parsingError(let parseError):
///         // Response parsing failed
///     }
/// }
/// ```
///
/// ## Security Considerations
///
/// - Never transmit secret keys to the server
/// - Validate the challenge transaction before signing
/// - Check time bounds to prevent replay attacks
/// - Store JWT tokens securely
/// - Refresh tokens before expiration
///
/// See also:
/// - [SEP-0010 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)
/// - [StellarToml] for discovering authentication endpoints
public final class WebAuthenticator: Sendable {
    /// The URL of the SEP-10 web authentication endpoint for obtaining JWT tokens.
    public let authEndpoint: String
    /// The server's public signing key used to validate challenge transaction signatures.
    public let serverSigningKey: String
    private let serviceHelper: ServiceHelper
    /// The Stellar network used for authentication and transaction validation.
    public let network: Network
    /// The server's home domain hosting the stellar.toml configuration file.
    public let serverHomeDomain: String
    /// Grace period in seconds for validating challenge transaction time bounds (default: 5 minutes).
    public let gracePeriod:UInt64 = SEPConstants.WEBAUTH_GRACE_PERIOD_SECONDS
    
    /// Creates a WebAuthenticator instance by fetching configuration from a domain's stellar.toml file.
    ///
    /// This is the recommended way to initialize a WebAuthenticator. It automatically retrieves the
    /// authentication endpoint and server signing key from the anchor's stellar.toml configuration file.
    ///
    /// - Parameter domain: The anchor's domain (e.g., "testanchor.stellar.org")
    /// - Parameter network: The Stellar network to use (.public, .testnet, or .futurenet)
    /// - Parameter secure: Whether to use HTTPS (true) or HTTP (false). Default is true.
    /// - Returns: WebAuthenticatorForDomainEnum indicating success with WebAuthenticator instance or failure with error
    ///
    /// Example:
    /// ```swift
    /// let result = await WebAuthenticator.from(
    ///     domain: "testanchor.stellar.org",
    ///     network: .testnet
    /// )
    /// ```
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
    
    /// Initializes a WebAuthenticator instance with explicit configuration parameters.
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

    /// Obtains a JWT token through the SEP-0010 authentication flow.
    ///
    /// This method handles the complete authentication workflow: requesting a challenge from the server,
    /// validating it, signing it with the provided keypairs, and submitting it to receive a JWT token.
    /// The returned token can be used for authenticating with SEP-6, SEP-12, SEP-24, SEP-31, and other services.
    ///
    /// - Parameter forUserAccount: The Stellar account ID (starting with G or M) to authenticate
    /// - Parameter memo: ID memo for the account. Required if the account is muxed (starts with M) and accountId starts with G
    /// - Parameter signers: Array of KeyPair objects with secret keys for signing the challenge. For multi-sig accounts, include all required signers
    /// - Parameter homeDomain: The anchor's domain hosting the stellar.toml file. Optional but recommended
    /// - Parameter clientDomain: Domain of the client application for mutual authentication. Used to prove the client's identity to the server
    /// - Parameter clientDomainAccountKeyPair: KeyPair for client domain signing. If it includes a private key, it will be used directly. If only public key, use clientDomainSigningFunction
    /// - Parameter clientDomainSigningFunction: Function for remote client domain signing. Accepts base64 XDR transaction, returns signed transaction. Use when client domain signing occurs on a server
    /// - Returns: GetJWTTokenResponseEnum with JWT token on success or error details on failure
    ///
    /// Example:
    /// ```swift
    /// let userKeyPair = try KeyPair(secretSeed: "S...")
    /// let result = await webAuth.jwtToken(
    ///     forUserAccount: userKeyPair.accountId,
    ///     signers: [userKeyPair],
    ///     homeDomain: "testanchor.stellar.org"
    /// )
    /// ```
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
    
    /// Requests a SEP-10 challenge transaction from the authentication server.
    /// - Parameter forAccount: The Stellar account ID to authenticate
    /// - Parameter memo: Optional ID memo. Required for muxed accounts starting with G, prohibited for accounts starting with M
    /// - Parameter homeDomain: Optional anchor domain for verification
    /// - Parameter clientDomain: Optional client domain for mutual authentication
    /// - Returns: ChallengeResponseEnum with base64-encoded challenge transaction or error
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

    /// Validates a SEP-10 challenge transaction according to protocol specifications.
    /// - Parameter transactionEnvelopeXDR: The challenge transaction envelope to validate
    /// - Parameter userAccountId: The expected user account ID
    /// - Parameter memo: Expected memo value for non-muxed accounts
    /// - Parameter serverSigningKey: The server's public signing key
    /// - Parameter clientDomainAccount: Expected client domain account for mutual authentication
    /// - Parameter timeBoundsGracePeriod: Grace period in seconds for time bounds validation
    /// - Returns: ChallengeValidationResponseEnum indicating success or specific validation error
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

    /// Signs a challenge transaction with the provided keypairs.
    /// - Parameter transactionEnvelopeXDR: The transaction envelope to sign
    /// - Parameter keyPairs: Array of keypairs to sign the transaction with
    /// - Returns: Base64-encoded signed transaction XDR, or nil if signing fails
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

    /// Submits a signed challenge transaction to the authentication server to obtain a JWT token.
    /// - Parameter base64EnvelopeXDR: Base64-encoded signed transaction envelope
    /// - Returns: SendChallengeResponseEnum with JWT token on success or error details on failure
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
