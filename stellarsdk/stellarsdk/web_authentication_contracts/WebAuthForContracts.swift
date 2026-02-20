//
//  WebAuthForContracts.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Implements SEP-45 - Stellar Web Authentication for Contract Accounts.
///
/// This class provides functionality for authenticating Soroban smart contract accounts (C... addresses)
/// through the Stellar Web Authentication protocol. The authentication flow returns a JWT token that can
/// be used for subsequent requests to SEP-compliant services (SEP-6, SEP-12, SEP-24, SEP-31).
///
/// SEP-45 extends the SEP-10 authentication protocol to support contract accounts, which have different
/// authentication requirements than traditional Stellar accounts. Contract accounts can implement custom
/// authentication logic in their __check_auth function.
///
/// ## Typical Workflow
///
/// 1. **Initialize from Domain**: Create a WebAuthForContracts instance using the anchor's stellar.toml
/// 2. **Get JWT Token**: Request and obtain a JWT token for authentication
/// 3. **Use Token**: Include the JWT token in subsequent SEP service requests
///
/// ## Example Usage
///
/// ```swift
/// // Step 1: Create WebAuthForContracts from anchor domain
/// let result = await WebAuthForContracts.from(
///     domain: "testanchor.stellar.org",
///     network: .testnet
/// )
///
/// switch result {
/// case .success(let webAuth):
///     // Step 2: Get JWT token for contract account
///     let contractId = "CABC..."
///     let signerKeyPair = try KeyPair(secretSeed: "S...")
///     let jwtResult = await webAuth.jwtToken(
///         forContractAccount: contractId,
///         signers: [signerKeyPair]
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
/// **Multi-Signature Contracts:**
/// ```swift
/// // Provide multiple signers for contracts requiring multiple signatures
/// let signers = [keyPair1, keyPair2]
/// let result = await webAuth.jwtToken(
///     forContractAccount: contractId,
///     signers: signers
/// )
/// ```
///
/// **Contracts Without Signature Requirements:**
/// ```swift
/// // For contracts whose __check_auth doesn't require signatures
/// let result = await webAuth.jwtToken(
///     forContractAccount: contractId,
///     signers: []  // Empty signers array
/// )
/// ```
///
/// **Client Domain Signing:**
/// ```swift
/// // For client domain verification (mutual authentication)
/// let clientDomainKeyPair = try KeyPair(accountId: "G...")
/// let result = await webAuth.jwtToken(
///     forContractAccount: contractId,
///     signers: [contractSignerKeyPair],
///     clientDomain: "wallet.example.com",
///     clientDomainAccountKeyPair: clientDomainKeyPair,
///     clientDomainSigningCallback: { entry in
///         // Sign on server and return signed entry
///         return try await signOnServer(entry)
///     }
/// )
/// ```
///
/// See also:
/// - [SEP-0045 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md)
/// - [StellarToml] for discovering authentication endpoints
/// - [WebAuthenticator] for traditional account (G... and M...) authentication
public final class WebAuthForContracts: @unchecked Sendable {

    // MARK: - Public Properties

    /// The URL of the SEP-45 web authentication endpoint for obtaining JWT tokens.
    public let authEndpoint: String
    /// The web auth contract ID (C... address) from stellar.toml.
    public let webAuthContractId: String
    /// The server's public signing key (G... address) used to validate challenge signatures.
    public let serverSigningKey: String
    /// The server's home domain hosting the stellar.toml configuration file.
    public let serverHomeDomain: String
    /// The Stellar network used for authentication and signature validation.
    public let network: Network
    /// Whether to use application/x-www-form-urlencoded (true) or application/json (false) for requests.
    public var useFormUrlEncoded: Bool = true
    /// Optional Soroban RPC URL for fetching current ledger (defaults based on network).
    public var sorobanRpcUrl: String?

    // MARK: - Private Properties

    private let serviceHelper: ServiceHelper
    private var httpRequestHeaders: [String: String]?

    // MARK: - Initialization

    /// Creates a WebAuthForContracts instance by fetching configuration from a domain's stellar.toml file.
    ///
    /// This is the recommended way to initialize a WebAuthForContracts. It automatically retrieves the
    /// authentication endpoint, web auth contract ID, and server signing key from the anchor's stellar.toml
    /// configuration file.
    ///
    /// - Parameter domain: The anchor's domain (e.g., "testanchor.stellar.org")
    /// - Parameter network: The Stellar network to use (.public, .testnet, or .futurenet)
    /// - Parameter secure: Whether to use HTTPS (true) or HTTP (false). Default is true.
    /// - Returns: WebAuthForContractsForDomainEnum indicating success with instance or failure with error
    ///
    /// Example:
    /// ```swift
    /// let result = await WebAuthForContracts.from(
    ///     domain: "testanchor.stellar.org",
    ///     network: .testnet
    /// )
    /// ```
    public static func from(domain: String, network: Network, secure: Bool = true) async -> WebAuthForContractsForDomainEnum {
        let result = await StellarToml.from(domain: domain, secure: secure)
        switch result {
        case .success(let toml):
            guard let authEndpoint = toml.accountInformation.webAuthForContractsEndpoint else {
                return .failure(error: .noAuthEndpoint)
            }
            guard let webAuthContractId = toml.accountInformation.webAuthContractId else {
                return .failure(error: .noWebAuthContractId)
            }
            guard let serverSigningKey = toml.accountInformation.signingKey else {
                return .failure(error: .noSigningKey)
            }

            do {
                let instance = try WebAuthForContracts(
                    authEndpoint: authEndpoint,
                    webAuthContractId: webAuthContractId,
                    serverSigningKey: serverSigningKey,
                    serverHomeDomain: domain,
                    network: network
                )
                return .success(response: instance)
            } catch let error as WebAuthForContractsError {
                return .failure(error: error)
            } catch {
                return .failure(error: .invalidToml)
            }
        case .failure(let error):
            switch error {
            case .invalidDomain:
                return .failure(error: .invalidDomain)
            case .invalidToml:
                return .failure(error: .invalidToml)
            }
        }
    }

    /// Initializes a WebAuthForContracts instance with explicit configuration parameters.
    ///
    /// - Parameter authEndpoint: Endpoint to be used for the authentication procedure. Usually taken from stellar.toml.
    /// - Parameter webAuthContractId: The web auth contract ID (C... address). Usually taken from stellar.toml.
    /// - Parameter serverSigningKey: The server public key (G... address), taken from stellar.toml.
    /// - Parameter serverHomeDomain: The server home domain of the server where the stellar.toml was loaded from.
    /// - Parameter network: The network used.
    /// - Parameter sorobanRpcUrl: Optional Soroban RPC URL. Defaults based on network if not provided.
    /// - Throws: WebAuthForContractsError if parameters are invalid
    public init(
        authEndpoint: String,
        webAuthContractId: String,
        serverSigningKey: String,
        serverHomeDomain: String,
        network: Network,
        sorobanRpcUrl: String? = nil
    ) throws {
        // Validate webAuthContractId
        guard webAuthContractId.starts(with: "C") else {
            throw WebAuthForContractsError.invalidWebAuthContractId(
                message: "webAuthContractId must be a contract address starting with 'C'"
            )
        }

        // Validate serverSigningKey
        guard serverSigningKey.starts(with: "G") else {
            throw WebAuthForContractsError.invalidServerSigningKey(
                message: "serverSigningKey must be an account address starting with 'G'"
            )
        }

        // Validate authEndpoint
        guard let url = URL(string: authEndpoint),
              url.scheme != nil,
              url.host != nil else {
            throw WebAuthForContractsError.invalidAuthEndpoint(
                message: "authEndpoint must be a valid URL"
            )
        }

        // Validate serverHomeDomain
        guard !serverHomeDomain.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw WebAuthForContractsError.emptyServerHomeDomain
        }

        self.authEndpoint = authEndpoint
        self.webAuthContractId = webAuthContractId
        self.serverSigningKey = serverSigningKey
        self.serverHomeDomain = serverHomeDomain
        self.network = network
        self.serviceHelper = ServiceHelper(baseURL: authEndpoint)

        // Set Soroban RPC URL based on network if not provided
        if let providedUrl = sorobanRpcUrl {
            self.sorobanRpcUrl = providedUrl
        } else {
            self.sorobanRpcUrl = network.passphrase == Network.testnet.passphrase
                ? "https://soroban-testnet.stellar.org"
                : "https://soroban.stellar.org"
        }
    }

    // MARK: - Public Methods

    /// Obtains a JWT token through the SEP-45 authentication flow.
    ///
    /// This method handles the complete authentication workflow: requesting a challenge from the server,
    /// validating it, signing it with the provided keypairs, and submitting it to receive a JWT token.
    /// The returned token can be used for authenticating with SEP-6, SEP-12, SEP-24, SEP-31, and other services.
    ///
    /// - Parameter forContractAccount: The contract account ID (starting with C) to authenticate
    /// - Parameter signers: Array of KeyPair objects with secret keys for signing the challenge. For contracts
    ///   that implement __check_auth with signature verification, provide keypairs with sufficient weight.
    ///   Can be empty for contracts whose __check_auth implementation does not require signatures.
    /// - Parameter homeDomain: The anchor's domain hosting the stellar.toml file. Optional, defaults to server home domain
    /// - Parameter clientDomain: Domain of the client application for mutual authentication
    /// - Parameter clientDomainAccountKeyPair: KeyPair for client domain signing. If it includes a private key, it will be used directly
    /// - Parameter clientDomainSigningCallback: Function for remote client domain signing. Accepts SorobanAuthorizationEntryXDR, returns signed entry
    /// - Parameter signatureExpirationLedger: Optional expiration ledger for signatures. If nil and signers are provided, automatically set to current ledger + 10
    /// - Returns: GetContractJWTTokenResponseEnum with JWT token on success or error details on failure
    ///
    /// Example:
    /// ```swift
    /// let contractId = "CABC..."
    /// let signerKeyPair = try KeyPair(secretSeed: "S...")
    /// let result = await webAuth.jwtToken(
    ///     forContractAccount: contractId,
    ///     signers: [signerKeyPair]
    /// )
    /// ```
    public func jwtToken(
        forContractAccount clientAccountId: String,
        signers: [KeyPair],
        homeDomain: String? = nil,
        clientDomain: String? = nil,
        clientDomainAccountKeyPair: KeyPair? = nil,
        clientDomainSigningCallback: ((SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR)? = nil,
        signatureExpirationLedger: UInt32? = nil
    ) async -> GetContractJWTTokenResponseEnum {
        // Validate client account ID
        guard clientAccountId.starts(with: "C") else {
            return .failure(error: .parsingError(message: "Client account must be a contract address (C...)"))
        }

        // Use server home domain as default if not provided
        let effectiveHomeDomain = homeDomain ?? serverHomeDomain

        // Get the challenge authorization entries from the web auth server
        let challengeResponse = await getChallenge(
            forContractAccount: clientAccountId,
            homeDomain: effectiveHomeDomain,
            clientDomain: clientDomain
        )

        switch challengeResponse {
        case .success(let response):
            // Validate network passphrase if provided
            if let networkPassphrase = response.networkPassphrase {
                let expectedNetworkPassphrase = network.passphrase
                if networkPassphrase != expectedNetworkPassphrase {
                    return .failure(error: .validationError(error: .invalidNetworkPassphrase(
                        expected: expectedNetworkPassphrase,
                        received: networkPassphrase
                    )))
                }
            }

            // Decode authorization entries
            let authEntries: [SorobanAuthorizationEntryXDR]
            do {
                authEntries = try decodeAuthorizationEntries(base64Xdr: response.authorizationEntries)
            } catch {
                return .failure(error: .parsingError(message: "Failed to decode authorization entries: \(error.localizedDescription)"))
            }

            // Determine client domain account ID if needed
            var clientDomainAccountId: String?
            if let clientDomain = clientDomain {
                if let clientDomainKeyPair = clientDomainAccountKeyPair {
                    clientDomainAccountId = clientDomainKeyPair.accountId
                } else if clientDomainSigningCallback != nil {
                    // Fetch client domain's signing key from stellar.toml
                    let tomlResult = await StellarToml.from(domain: clientDomain, secure: true)
                    switch tomlResult {
                    case .success(let toml):
                        if let signingKey = toml.accountInformation.signingKey {
                            clientDomainAccountId = signingKey
                        } else {
                            return .failure(error: .parsingError(message: "Could not find signing key in stellar.toml for client domain"))
                        }
                    case .failure:
                        return .failure(error: .parsingError(message: "Could not fetch stellar.toml for client domain"))
                    }
                } else {
                    return .failure(error: .parsingError(message: "Client domain key pair or client domain signing callback is missing"))
                }
            }

            // Validate the authorization entries
            do {
                try validateChallenge(
                    authEntries: authEntries,
                    clientAccountId: clientAccountId,
                    homeDomain: effectiveHomeDomain,
                    clientDomainAccountId: clientDomainAccountId
                )
            } catch let error as ContractChallengeValidationError {
                return .failure(error: .validationError(error: error))
            } catch {
                return .failure(error: .parsingError(message: "Challenge validation failed: \(error.localizedDescription)"))
            }

            // Auto-fill signatureExpirationLedger if not provided and signers are present
            var effectiveExpirationLedger = signatureExpirationLedger
            if !signers.isEmpty && effectiveExpirationLedger == nil {
                guard let rpcUrl = sorobanRpcUrl else {
                    return .failure(error: .parsingError(message: "Soroban RPC URL is required for auto-filling signature expiration ledger"))
                }
                let sorobanServer = SorobanServer(endpoint: rpcUrl)
                let latestLedgerResponse = await sorobanServer.getLatestLedger()
                switch latestLedgerResponse {
                case .success(let response):
                    effectiveExpirationLedger = response.sequence + 10
                case .failure(let error):
                    return .failure(error: .requestError(error: error))
                }
            }

            // Sign the authorization entries
            let signedEntries: [SorobanAuthorizationEntryXDR]
            do {
                signedEntries = try await signAuthorizationEntries(
                    authEntries: authEntries,
                    clientAccountId: clientAccountId,
                    signers: signers,
                    signatureExpirationLedger: effectiveExpirationLedger,
                    clientDomainKeyPair: clientDomainAccountKeyPair,
                    clientDomainAccountId: clientDomainAccountId,
                    clientDomainSigningCallback: clientDomainSigningCallback
                )
            } catch {
                return .failure(error: .signingError(message: "Failed to sign authorization entries: \(error.localizedDescription)"))
            }

            // Request the JWT token by sending back the signed authorization entries
            let submitResponse = await sendSignedChallenge(signedEntries: signedEntries)
            switch submitResponse {
            case .success(let jwtToken):
                return .success(jwtToken: jwtToken)
            case .failure(let error):
                return .failure(error: error)
            }

        case .failure(let error):
            return .failure(error: error)
        }
    }

    /// Requests a challenge from the authentication server.
    ///
    /// - Parameter forContractAccount: The contract account ID (starting with C) to authenticate
    /// - Parameter homeDomain: Optional home domain for the request. Defaults to server home domain if not provided
    /// - Parameter clientDomain: Optional client domain for mutual authentication
    /// - Returns: GetContractChallengeResponseEnum with challenge response or error
    public func getChallenge(
        forContractAccount clientAccountId: String,
        homeDomain: String? = nil,
        clientDomain: String? = nil
    ) async -> GetContractChallengeResponseEnum {
        let effectiveHomeDomain = homeDomain ?? serverHomeDomain

        var path = "?account=\(clientAccountId)&home_domain=\(effectiveHomeDomain)"

        if let cd = clientDomain {
            path.append("&client_domain=\(cd)")
        }

        let result = await serviceHelper.GETRequestWithPath(path: path)
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: response)
                    let challengeResponse = try JSONDecoder().decode(ContractChallengeResponse.self, from: jsonData)
                    return .success(response: challengeResponse)
                } catch {
                    if let error = response["error"] as? String {
                        return .failure(error: .challengeRequestError(message: error))
                    } else {
                        return .failure(error: .parsingError(message: "Failed to parse challenge response"))
                    }
                }
            } else {
                return .failure(error: .parsingError(message: "Invalid JSON"))
            }
        case .failure(let error):
            return .failure(error: .requestError(error: error))
        }
    }

    /// Validates the authorization entries from the challenge response.
    ///
    /// Validation steps:
    /// 1. Each entry has no sub-invocations
    /// 2. contract_address matches WEB_AUTH_CONTRACT_ID
    /// 3. function_name is "web_auth_verify"
    /// 4. Args validation (account, home_domain, web_auth_domain, nonce, etc.)
    /// 5. Server entry exists and has valid signature
    /// 6. Client entry exists
    ///
    /// - Parameter authEntries: Authorization entries to validate
    /// - Parameter clientAccountId: Expected client contract account
    /// - Parameter homeDomain: Expected home domain. Defaults to server home domain if not provided
    /// - Parameter clientDomainAccountId: Optional expected client domain account
    /// - Throws: ContractChallengeValidationError on validation failure
    public func validateChallenge(
        authEntries: [SorobanAuthorizationEntryXDR],
        clientAccountId: String,
        homeDomain: String? = nil,
        clientDomainAccountId: String? = nil
    ) throws {
        guard !authEntries.isEmpty else {
            throw ContractChallengeValidationError.invalidArgs(message: "No authorization entries found")
        }

        // Use server home domain as default if not provided
        let effectiveHomeDomain = homeDomain ?? serverHomeDomain

        var nonce: String?
        var serverEntryFound = false
        var clientEntryFound = false
        var clientDomainEntryFound = false

        // Extract web_auth_domain from auth endpoint URL (include port if present)
        guard let uri = URL(string: authEndpoint) else {
            throw ContractChallengeValidationError.invalidArgs(message: "Invalid auth endpoint URL")
        }
        var webAuthDomain = uri.host ?? ""
        if let port = uri.port, port != 80 && port != 443 {
            webAuthDomain += ":\(port)"
        }

        for entry in authEntries {
            let rootInvocation = entry.rootInvocation

            // Check 1: No sub-invocations
            guard rootInvocation.subInvocations.count == 0 else {
                throw ContractChallengeValidationError.subInvocationsFound
            }

            // Check 2: Function must be contract function
            guard case .contractFn(let contractFn) = rootInvocation.function else {
                throw ContractChallengeValidationError.invalidArgs(message: "Authorization entry is not a contract function")
            }

            // Check 3: Contract address matches WEB_AUTH_CONTRACT_ID
            let contractIdHex = try addressToHex(address: contractFn.contractAddress)
            let expectedContractIdHex = try webAuthContractId.decodeContractIdToHex()
            guard contractIdHex == expectedContractIdHex else {
                let receivedContractId = try addressToString(address: contractFn.contractAddress)
                throw ContractChallengeValidationError.invalidContractAddress(
                    expected: webAuthContractId,
                    received: receivedContractId
                )
            }

            // Check 4: Function name is "web_auth_verify"
            guard contractFn.functionName == "web_auth_verify" else {
                throw ContractChallengeValidationError.invalidFunctionName(
                    expected: "web_auth_verify",
                    received: contractFn.functionName
                )
            }

            // Check 5: Extract and validate args
            let args = try extractArgsFromEntry(entry)

            // Validate account
            guard args["account"] == clientAccountId else {
                throw ContractChallengeValidationError.invalidAccount(
                    expected: clientAccountId,
                    received: args["account"] ?? "nil"
                )
            }

            // Validate home_domain
            guard args["home_domain"] == effectiveHomeDomain else {
                throw ContractChallengeValidationError.invalidHomeDomain(
                    expected: effectiveHomeDomain,
                    received: args["home_domain"] ?? "nil"
                )
            }

            // Validate web_auth_domain
            guard args["web_auth_domain"] == webAuthDomain else {
                throw ContractChallengeValidationError.invalidWebAuthDomain(
                    expected: webAuthDomain,
                    received: args["web_auth_domain"] ?? "nil"
                )
            }

            // Validate web_auth_domain_account
            guard args["web_auth_domain_account"] == serverSigningKey else {
                throw ContractChallengeValidationError.invalidArgs(
                    message: "Web auth domain account does not match server signing key"
                )
            }

            // Validate nonce consistency
            guard let entryNonce = args["nonce"] else {
                throw ContractChallengeValidationError.invalidNonce(message: "Nonce argument is missing")
            }
            if let existingNonce = nonce {
                guard existingNonce == entryNonce else {
                    throw ContractChallengeValidationError.invalidNonce(
                        message: "Nonce is not consistent across authorization entries"
                    )
                }
            } else {
                nonce = entryNonce
            }

            // Validate client domain if provided
            if let clientDomainAccountId = clientDomainAccountId {
                if let clientDomainAccount = args["client_domain_account"],
                   clientDomainAccount != clientDomainAccountId {
                    throw ContractChallengeValidationError.invalidClientDomainAccount(
                        expected: clientDomainAccountId,
                        received: clientDomainAccount
                    )
                }
            }

            // Check which entry this is (server, client, or client domain)
            guard case .address(let addressCredentials) = entry.credentials else {
                throw ContractChallengeValidationError.invalidArgs(message: "Invalid credentials type")
            }

            let credentialsAddressStr = try addressToString(address: addressCredentials.address)

            if credentialsAddressStr == serverSigningKey {
                serverEntryFound = true
                // Verify server signature
                guard verifyServerSignature(entry: entry) else {
                    throw ContractChallengeValidationError.invalidServerSignature
                }
            } else if credentialsAddressStr == clientAccountId {
                clientEntryFound = true
            } else if let clientDomainAccountId = clientDomainAccountId,
                      credentialsAddressStr == clientDomainAccountId {
                clientDomainEntryFound = true
            }
        }

        // Check 6: Server entry must exist
        guard serverEntryFound else {
            throw ContractChallengeValidationError.missingServerEntry
        }

        // Check 7: Client entry must exist
        guard clientEntryFound else {
            throw ContractChallengeValidationError.missingClientEntry
        }

        // Check 8: Client domain entry must exist if client domain account is provided
        if clientDomainAccountId != nil && !clientDomainEntryFound {
            throw ContractChallengeValidationError.invalidArgs(
                message: "No authorization entry found for client domain account"
            )
        }
    }

    /// Signs the authorization entries for the client account.
    ///
    /// - Parameter authEntries: Authorization entries to sign
    /// - Parameter clientAccountId: Client contract account
    /// - Parameter signers: Keypairs to sign with
    /// - Parameter signatureExpirationLedger: Optional expiration ledger for signatures
    /// - Parameter clientDomainKeyPair: Optional keypair for client domain signing
    /// - Parameter clientDomainAccountId: Optional client domain account ID (used with callback)
    /// - Parameter clientDomainSigningCallback: Optional callback for remote signing (single entry)
    /// - Returns: Signed authorization entries
    /// - Throws: Error if signing fails
    public func signAuthorizationEntries(
        authEntries: [SorobanAuthorizationEntryXDR],
        clientAccountId: String,
        signers: [KeyPair],
        signatureExpirationLedger: UInt32?,
        clientDomainKeyPair: KeyPair?,
        clientDomainAccountId: String?,
        clientDomainSigningCallback: ((SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR)?
    ) async throws -> [SorobanAuthorizationEntryXDR] {
        var signedEntries: [SorobanAuthorizationEntryXDR] = []

        for var entry in authEntries {
            guard case .address(var addressCredentials) = entry.credentials else {
                // Not an address credential, add as-is
                signedEntries.append(entry)
                continue
            }

            let credentialsAddressStr = try addressToString(address: addressCredentials.address)

            // Sign client entry
            if credentialsAddressStr == clientAccountId {
                // Set signature expiration ledger if provided
                if let expirationLedger = signatureExpirationLedger {
                    addressCredentials.signatureExpirationLedger = expirationLedger
                    entry.credentials = .address(addressCredentials)
                }

                // Sign with all provided signers
                for signer in signers {
                    try entry.sign(signer: signer, network: network)
                }
                signedEntries.append(entry)
                continue
            }

            // Sign client domain entry with local keypair
            if let clientDomainKeyPair = clientDomainKeyPair,
               credentialsAddressStr == clientDomainKeyPair.accountId {
                if let expirationLedger = signatureExpirationLedger {
                    addressCredentials.signatureExpirationLedger = expirationLedger
                    entry.credentials = .address(addressCredentials)
                }
                try entry.sign(signer: clientDomainKeyPair, network: network)
                signedEntries.append(entry)
                continue
            }

            // Sign client domain entry via callback (remote signing)
            if let clientDomainSigningCallback = clientDomainSigningCallback,
               let clientDomainAccountId = clientDomainAccountId,
               credentialsAddressStr == clientDomainAccountId {
                // Set signature expiration ledger before sending to callback
                if let expirationLedger = signatureExpirationLedger {
                    addressCredentials.signatureExpirationLedger = expirationLedger
                    entry.credentials = .address(addressCredentials)
                }
                let signedEntry = try await clientDomainSigningCallback(entry)
                signedEntries.append(signedEntry)
                continue
            }

            // Add entry as-is (e.g., server entry which is already signed)
            signedEntries.append(entry)
        }

        return signedEntries
    }

    /// Submits signed authorization entries to obtain a JWT token.
    ///
    /// - Parameter signedEntries: Signed authorization entries
    /// - Returns: SubmitContractChallengeResponseEnum with JWT token or error
    public func sendSignedChallenge(
        signedEntries: [SorobanAuthorizationEntryXDR]
    ) async -> SubmitContractChallengeResponseEnum {
        do {
            let base64Xdr = try encodeAuthorizationEntries(signedEntries)

            let requestBody: Data
            let contentType: String

            if useFormUrlEncoded {
                contentType = "application/x-www-form-urlencoded"
                // URL encode the base64 string, ensuring + and / are properly escaped
                var allowedCharacters = CharacterSet.urlQueryAllowed
                allowedCharacters.remove(charactersIn: "+/=")
                let encodedBase64 = base64Xdr.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? base64Xdr
                let formString = "authorization_entries=\(encodedBase64)"
                requestBody = formString.data(using: .utf8) ?? Data()
            } else {
                contentType = "application/json"
                let json = ["authorization_entries": base64Xdr]
                requestBody = try JSONSerialization.data(withJSONObject: json)
            }

            let result = await serviceHelper.POSTRequestWithPath(path: "", body: requestBody, contentType: contentType)
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let token = response["token"] as? String {
                        return .success(jwtToken: token)
                    } else if let error = response["error"] as? String {
                        return .failure(error: .submitChallengeError(message: error))
                    } else {
                        return .failure(error: .parsingError(message: "Invalid response format"))
                    }
                } else {
                    return .failure(error: .parsingError(message: "Failed to parse response"))
                }
            case .failure(let error):
                // Check for HTTP 504 timeout
                if case .timeout = error {
                    return .failure(error: .submitChallengeTimeout)
                }
                // Check for HTTP 400 bad request with error message
                if case .badRequest(let message, _) = error {
                    return .failure(error: .submitChallengeError(message: message))
                }
                return .failure(error: .requestError(error: error))
            }
        } catch {
            return .failure(error: .parsingError(message: "Failed to encode authorization entries: \(error.localizedDescription)"))
        }
    }

    /// Decodes authorization entries from base64 XDR.
    ///
    /// - Parameter base64Xdr: Base64-encoded XDR array of SorobanAuthorizationEntry
    /// - Returns: Array of authorization entries
    /// - Throws: Error if decoding fails
    public func decodeAuthorizationEntries(base64Xdr: String) throws -> [SorobanAuthorizationEntryXDR] {
        guard let xdrData = Data(base64Encoded: base64Xdr) else {
            throw ContractChallengeValidationError.invalidArgs(message: "Invalid base64 encoding")
        }

        let xdrDecoder = XDRDecoder(data: xdrData)

        // Decode array length
        let count = try xdrDecoder.decode(Int32.self)
        guard count >= 0 else {
            throw ContractChallengeValidationError.invalidArgs(message: "Invalid array count")
        }

        // Decode each entry
        var entries: [SorobanAuthorizationEntryXDR] = []
        for _ in 0..<count {
            let entry = try SorobanAuthorizationEntryXDR(from: xdrDecoder)
            entries.append(entry)
        }

        return entries
    }

    // MARK: - Private Helper Methods

    /// Encodes authorization entries to base64 XDR.
    private func encodeAuthorizationEntries(_ entries: [SorobanAuthorizationEntryXDR]) throws -> String {
        // Create a temporary struct to encode the array using XDREncodable
        struct AuthEntriesArray: XDREncodable {
            let entries: [SorobanAuthorizationEntryXDR]

            func xdrEncode(to encoder: XDREncoder) throws {
                try encoder.encode(Int32(entries.count))
                for entry in entries {
                    try encoder.encode(entry)
                }
            }
        }

        let wrapper = AuthEntriesArray(entries: entries)
        let encodedBytes = try XDREncoder.encode(wrapper)
        return Data(encodedBytes).base64EncodedString()
    }

    /// Extracts args map from authorization entry.
    private func extractArgsFromEntry(_ entry: SorobanAuthorizationEntryXDR) throws -> [String: String] {
        guard case .contractFn(let contractFn) = entry.rootInvocation.function else {
            throw ContractChallengeValidationError.invalidArgs(message: "Not a contract function")
        }

        guard !contractFn.args.isEmpty else {
            throw ContractChallengeValidationError.invalidArgs(message: "No arguments found")
        }

        // First arg should be a map
        let argsVal = contractFn.args[0]
        guard case .map(let mapEntries) = argsVal else {
            throw ContractChallengeValidationError.invalidArgs(message: "Arguments are not in map format")
        }

        guard let entries = mapEntries else {
            throw ContractChallengeValidationError.invalidArgs(message: "Map entries are nil")
        }

        var result: [String: String] = [:]
        for mapEntry in entries {
            // Key should be a symbol
            guard case .symbol(let key) = mapEntry.key else {
                continue
            }

            // Value should be a string
            guard case .string(let value) = mapEntry.val else {
                continue
            }

            result[key] = value
        }

        return result
    }

    /// Verifies server signature on authorization entry.
    private func verifyServerSignature(entry: SorobanAuthorizationEntryXDR) -> Bool {
        do {
            guard case .address(let addressCredentials) = entry.credentials else {
                return false
            }

            // Build authorization preimage
            let networkId = WrappedData32(network.passphrase.sha256Hash)

            let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
                networkID: networkId,
                nonce: addressCredentials.nonce,
                signatureExpirationLedger: addressCredentials.signatureExpirationLedger,
                invocation: entry.rootInvocation
            )

            let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)
            let encodedBytes = try XDREncoder.encode(preimage)
            let payload = Data(encodedBytes).sha256Hash

            // Get signature from credentials
            guard case .vec(let signatureVec) = addressCredentials.signature,
                  let signatures = signatureVec,
                  !signatures.isEmpty else {
                return false
            }

            // Extract public key and signature from first signature entry
            let firstSig = signatures[0]
            guard case .map(let sigMap) = firstSig else {
                return false
            }

            guard let mapEntries = sigMap else {
                return false
            }

            var publicKey: Data?
            var signature: Data?

            for mapEntry in mapEntries {
                guard case .symbol(let key) = mapEntry.key else { continue }

                if key == "public_key", case .bytes(let pkBytes) = mapEntry.val {
                    publicKey = pkBytes
                } else if key == "signature", case .bytes(let sigBytes) = mapEntry.val {
                    signature = sigBytes
                }
            }

            guard let publicKey = publicKey, let signature = signature else {
                return false
            }

            // Verify that extracted public key matches expected server signing key
            let expectedPublicKey = try KeyPair(accountId: serverSigningKey).publicKey
            guard publicKey == Data(expectedPublicKey.bytes) else {
                return false
            }

            // Verify signature
            let serverKeyPair = try KeyPair(accountId: serverSigningKey)
            return try serverKeyPair.verify(signature: [UInt8](signature), message: [UInt8](payload))
        } catch {
            return false
        }
    }

    /// Converts an address to its string representation.
    private func addressToString(address: SCAddressXDR) throws -> String {
        switch address {
        case .account(let accountId):
            return accountId.accountId
        case .contract(let contractId):
            return try contractId.wrapped.encodeContractId()
        case .muxedAccount(let muxedAccount):
            return muxedAccount.accountId
        case .claimableBalanceId(let balanceId):
            // Encode claimable balance ID to string
            switch balanceId {
            case .claimableBalanceIDTypeV0(let data):
                return try data.wrapped.encodeClaimableBalanceId()
            }
        case .liquidityPoolId(let poolId):
            return try poolId.liquidityPoolID.wrapped.encodeLiquidityPoolId()
        }
    }

    /// Converts an address to its hex representation.
    private func addressToHex(address: SCAddressXDR) throws -> String {
        switch address {
        case .account(let accountId):
            let data = try accountId.accountId.decodeEd25519PublicKey()
            return data.base16EncodedString()
        case .contract(let contractId):
            return contractId.wrapped.base16EncodedString()
        case .muxedAccount(let muxedAccount):
            // For muxed accounts, decode to get the underlying ed25519 key
            let data = try muxedAccount.accountId.decodeEd25519PublicKey()
            return data.base16EncodedString()
        case .claimableBalanceId(let balanceId):
            switch balanceId {
            case .claimableBalanceIDTypeV0(let data):
                return data.wrapped.base16EncodedString()
            }
        case .liquidityPoolId(let poolId):
            return poolId.liquidityPoolID.wrapped.base16EncodedString()
        }
    }
}
