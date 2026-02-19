import Foundation

/// Result enum for initializing interactive service from a domain.
public enum InteractiveServiceForDomainEnum: Sendable {
    /// Successfully created interactive service instance.
    case success(response: InteractiveService)
    /// Failed to initialize service from domain.
    case failure(error: InteractiveServiceError)
}

/// Result enum for SEP-24 info endpoint requests.
public enum Sep24InfoResponseEnum: Sendable {
    /// Successfully retrieved anchor's supported assets and features.
    case success(response: Sep24InfoResponse)
    /// Request failed with interactive service error.
    case failure(error: InteractiveServiceError)
}

/// Result enum for SEP-24 fee endpoint requests.
public enum Sep24FeeResponseEnum: Sendable {
    /// Successfully retrieved fee information for deposit or withdrawal.
    case success(response: Sep24FeeResponse)
    /// Request failed with interactive service error.
    case failure(error: InteractiveServiceError)
}

/// Result enum for SEP-24 interactive deposit or withdrawal initiation.
public enum Sep24InteractiveResponseEnum: Sendable {
    /// Successfully initiated interactive flow, returns URL for user interaction.
    case success(response: Sep24InteractiveResponse)
    /// Request failed with interactive service error.
    case failure(error: InteractiveServiceError)
}

/// Result enum for SEP-24 transactions list endpoint requests.
public enum Sep24TransactionsResponseEnum: Sendable {
    /// Successfully retrieved list of transactions.
    case success(response: Sep24TransactionsResponse)
    /// Request failed with interactive service error.
    case failure(error: InteractiveServiceError)
}

/// Result enum for SEP-24 single transaction status requests.
public enum Sep24TransactionResponseEnum: Sendable {
    /// Successfully retrieved transaction status and details.
    case success(response: Sep24TransactionResponse)
    /// Request failed with interactive service error.
    case failure(error: InteractiveServiceError)
}

/// Implements SEP-0024 - Hosted Deposit and Withdrawal.
///
/// This class provides an interactive flow for deposits and withdrawals where the anchor service
/// requires user interaction through a web interface. The user completes KYC and other requirements
/// in the anchor's hosted web application, then the anchor handles the on/off-ramp process.
///
/// SEP-0024 enables a standardized way for wallets to integrate with anchor services for fiat on/off-ramps.
/// The anchor hosts a web interface where users can provide additional information like KYC data,
/// bank account details, or complete email verification.
///
/// ## Typical Workflow
///
/// 1. **Initialize Service**: Create InteractiveService from anchor's domain
/// 2. **Check Capabilities**: Query /info endpoint to see supported assets and features
/// 3. **Authenticate**: Obtain JWT token using SEP-0010 WebAuthenticator
/// 4. **Initiate Flow**: Start deposit or withdraw, receive interactive URL
/// 5. **User Interaction**: Open URL in webview/browser for user to complete requirements
/// 6. **Monitor Status**: Poll transaction endpoint to track progress
///
/// ## Example: Complete Deposit Flow
///
/// ```swift
/// // Step 1: Initialize service from domain
/// let serviceResult = await InteractiveService.forDomain(
///     domain: "https://testanchor.stellar.org"
/// )
///
/// guard case .success(let service) = serviceResult else { return }
///
/// // Step 2: Check what assets are supported
/// let infoResult = await service.info()
/// guard case .success(let info) = infoResult else { return }
/// print("Supported assets: \(info.deposit.keys)")
///
/// // Step 3: Get JWT token (using SEP-0010)
/// let jwtToken = "..." // Obtained from WebAuthenticator
///
/// // Step 4: Initiate deposit
/// let depositRequest = Sep24DepositRequest(
///     assetCode: "USDC",
///     account: userAccountId,
///     jwt: jwtToken
/// )
/// let depositResult = await service.deposit(request: depositRequest)
///
/// switch depositResult {
/// case .success(let response):
///     // Step 5: Open interactive URL in webview
///     print("Open this URL: \(response.url)")
///     // User completes KYC and provides deposit information
///
///     // Step 6: Monitor transaction status
///     let txRequest = Sep24TransactionRequest(
///         id: response.id,
///         jwt: jwtToken
///     )
///     let statusResult = await service.getTransaction(request: txRequest)
///     // Check response.transaction.status
/// case .failure(let error):
///     print("Deposit initiation failed: \(error)")
/// }
/// ```
///
/// ## Example: Withdraw Flow
///
/// ```swift
/// let withdrawRequest = Sep24WithdrawRequest(
///     assetCode: "USDC",
///     dest: "bank_account",
///     account: userAccountId,
///     jwt: jwtToken
/// )
///
/// let result = await service.withdraw(request: withdrawRequest)
/// switch result {
/// case .success(let response):
///     // Open interactive URL
///     print("Complete withdraw at: \(response.url)")
///
///     // User provides bank details and completes verification
///     // Then sends USDC to the anchor's account
/// case .failure(let error):
///     print("Withdraw failed: \(error)")
/// }
/// ```
///
/// ## Transaction Status Monitoring
///
/// ```swift
/// // Poll for transaction status updates
/// let txRequest = Sep24TransactionRequest(
///     id: transactionId,
///     jwt: jwtToken
/// )
///
/// let result = await service.getTransaction(request: txRequest)
/// if case .success(let response) = result {
///     switch response.transaction.status {
///     case "incomplete":
///         // User needs to complete interactive flow
///     case "pending_user_transfer_start":
///         // Waiting for user to send funds
///     case "pending_anchor":
///         // Anchor is processing
///     case "completed":
///         // Transaction complete
///     case "error":
///         // Transaction failed
///     default:
///         break
///     }
/// }
/// ```
///
/// ## Fee Information
///
/// ```swift
/// let feeRequest = Sep24FeeRequest(
///     operation: "deposit",
///     assetCode: "USDC",
///     amount: "100",
///     jwt: jwtToken
/// )
///
/// let feeResult = await service.fee(request: feeRequest)
/// if case .success(let feeResponse) = feeResult {
///     print("Fee: \(feeResponse.fee)")
/// }
/// ```
///
/// ## Error Handling
///
/// ```swift
/// let result = await service.deposit(request: depositRequest)
/// switch result {
/// case .success(let response):
///     // Handle success
/// case .failure(let error):
///     switch error {
///     case .authenticationRequired:
///         // JWT token missing or expired, re-authenticate with SEP-10
///     case .anchorError(let message):
///         // Anchor-specific error (e.g., unsupported asset, amount too large)
///     case .parsingResponseFailed(let message):
///         // Response parsing error
///     case .horizonError(let horizonError):
///         // Network or HTTP error
///     }
/// }
/// ```
///
/// ## Integration with Other SEPs
///
/// SEP-0024 often works together with:
/// - **SEP-0010**: Required for authentication (JWT tokens)
/// - **SEP-0012**: For standalone KYC (may be handled in interactive flow)
/// - **SEP-0038**: For cross-asset swaps during deposit/withdraw
///
/// ## Security Considerations
///
/// - Always use HTTPS for production
/// - Validate JWT tokens are current
/// - Open interactive URLs in a secure webview
/// - Monitor transaction status to detect issues
/// - Handle user cancellations gracefully
///
/// See also:
/// - [SEP-0024 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
/// - [WebAuthenticator] for SEP-0010 authentication
/// - [StellarToml] for service discovery
public final class InteractiveService: @unchecked Sendable {

    /// The base URL of the SEP-24 interactive service endpoint for hosted deposit and withdrawal.
    public let serviceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()

    /// Initializes a new InteractiveService instance with the specified SEP-24 transfer server endpoint URL.
    ///
    /// - Parameter serviceAddress: The URL of the SEP-24 transfer server (e.g., "https://example.com/sep24")
    public init(serviceAddress:String) {
        self.serviceAddress = serviceAddress
        serviceHelper = ServiceHelper(baseURL: serviceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates an InteractiveService instance based on information from the stellar.toml file for a given domain.
    ///
    /// Fetches the stellar.toml file from `{domain}/.well-known/stellar.toml` and extracts the TRANSFER_SERVER_SEP0024 URL.
    ///
    /// - Parameter domain: The anchor's domain including scheme (e.g., "https://testanchor.stellar.org")
    /// - Returns: InteractiveServiceForDomainEnum with the service instance, or an error
    public static func forDomain(domain:String) async -> InteractiveServiceForDomainEnum {
        let interactiveServerKey = "TRANSFER_SERVER_SEP0024"
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            return .failure(error: .invalidDomain)
        }
        
        do {
            let tomlString = try String(contentsOf: url, encoding: .utf8)
            let toml = try Toml(withString: tomlString)
            if let interactiveAddress = toml.string(interactiveServerKey) {
                let interactiveService = InteractiveService(serviceAddress: interactiveAddress)
                return .success(response: interactiveService)
            } else {
                return .failure(error: .noInteractiveServerSet)
            }
            
        } catch {
            return .failure(error: .invalidToml)
        }
    }
    
    
    /// Get the anchor's basic info about what their TRANSFER_SERVER_SEP0024 supports to wallets and clients.
    ///
    /// Returns information about supported assets, deposit/withdraw features, and fee structures.
    ///
    /// - Parameter language: Language code specified using ISO 639-1. Description fields in the response should be in this language. Defaults to "en".
    /// - Returns: Sep24InfoResponseEnum with anchor capabilities, or an error
    public func info(language: String? = nil) async -> Sep24InfoResponseEnum {
        var requestPath = "/info"
        if let language = language {
            requestPath += "?lang=\(language)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep24InfoResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Get the anchor's reported fee that would be charged for a given deposit or withdraw operation.
    ///
    /// This is important to allow an anchor to accurately report fees to a user even when the fee schedule is complex.
    /// If a fee can be fully expressed with the fee_fixed, fee_percent or fee_minimum fields in the /info response,
    /// then an anchor will not implement this endpoint.
    ///
    /// - Parameter request: Sep24FeeRequest containing operation type, asset code, amount, and JWT token
    /// - Returns: Sep24FeeResponseEnum with fee amount, or an error
    public func fee(request: Sep24FeeRequest) async -> Sep24FeeResponseEnum {
        var requestPath = "/fee?operation=\(request.operation)&asset_code=\(request.assetCode)&amount=\(request.amount)"
        
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep24FeeResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Initiates a SEP-24 deposit transaction, returning an interactive URL for the user to complete KYC and deposit requirements.
    ///
    /// The user should be redirected to the returned URL to complete the deposit flow in the anchor's web interface.
    ///
    /// - Parameter request: Sep24DepositRequest containing asset code, destination account, and JWT token
    /// - Returns: Sep24InteractiveResponseEnum with interactive URL and transaction ID, or an error
    public func deposit(request: Sep24DepositRequest) async -> Sep24InteractiveResponseEnum {
        let requestPath = "/transactions/deposit/interactive"
        
        let result = await serviceHelper.POSTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep24InteractiveResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Initiates a SEP-24 withdrawal transaction, returning an interactive URL for the user to provide withdrawal details and complete verification.
    ///
    /// The user should be redirected to the returned URL to complete the withdrawal flow in the anchor's web interface.
    ///
    /// - Parameter request: Sep24WithdrawRequest containing asset code, destination type, and JWT token
    /// - Returns: Sep24InteractiveResponseEnum with interactive URL and transaction ID, or an error
    public func withdraw(request: Sep24WithdrawRequest) async -> Sep24InteractiveResponseEnum {
        let requestPath = "/transactions/withdraw/interactive"
        
        let result = await serviceHelper.POSTMultipartRequestWithPath(path: requestPath, parameters: request.toParameters(), jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep24InteractiveResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Retrieves a list of SEP-24 transactions for the authenticated user, filtered by asset code and optional parameters.
    ///
    /// Use this to show transaction history or monitor multiple pending transactions.
    ///
    /// - Parameter request: Sep24TransactionsRequest containing asset code, filters, pagination options, and JWT token
    /// - Returns: Sep24TransactionsResponseEnum with list of transactions, or an error
    public func getTransactions(request: Sep24TransactionsRequest) async -> Sep24TransactionsResponseEnum {
        var requestPath = "/transactions?asset_code=\(request.assetCode)"
        if let noOlderThanDate = request.noOlderThan {
            let noOlderThan = DateFormatter.iso8601.string(from: noOlderThanDate)
            requestPath += "&no_older_than=\(noOlderThan)"
        }
        if let limit = request.limit {
            requestPath += "&limit=\(limit)"
        }
        if let kind = request.kind {
            requestPath += "&kind=\(kind)"
        }
        if let pagingId = request.pagingId {
            requestPath += "&paging_id=\(pagingId)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep24TransactionsResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Retrieves the status and details of a single SEP-24 transaction by ID, Stellar transaction ID, or external transaction ID.
    ///
    /// Use this to poll for transaction status updates during the deposit/withdrawal flow.
    ///
    /// - Parameter request: Sep24TransactionRequest containing transaction identifier(s) and JWT token
    /// - Returns: Sep24TransactionResponseEnum with transaction details and status, or an error
    public func getTransaction(request: Sep24TransactionRequest) async -> Sep24TransactionResponseEnum {
        var requestPath = "/transaction?"
        
        var first = true
        if let id = request.id {
            requestPath += "id=\(id)"
            first = false
        }
        if let stellarTransactionId = request.stellarTransactionId {
            if !first {
                requestPath += "&"
            }
            requestPath += "stellar_transaction_id=\(stellarTransactionId)"
            first = false
        }
        if let externalTransactionId = request.externalTransactionId {
            if !first {
                requestPath += "&"
            }
            requestPath += "external_transaction_id=\(externalTransactionId)"
        }
        if let lang = request.lang {
            if !first {
                requestPath += "&"
            }
            requestPath += "lang=\(lang)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep24TransactionResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Converts a HorizonRequestError into a domain-specific InteractiveServiceError with appropriate error categorization.
    private func errorFor(horizonError:HorizonRequestError) -> InteractiveServiceError {
        switch horizonError {
        case .forbidden(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let type = json["type"] as? String {
                        if type == "authentication_required" {
                            return.authenticationRequired
                        } else {
                            return .parsingResponseFailed(message: horizonError.localizedDescription)
                        }
                    }
                } catch let error {
                    return .parsingResponseFailed(message: error.localizedDescription)
                }
            }
        case .requestFailed(let message, _),
             .badRequest(let message, _),
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
            break
        case .notFound(let message, _):
            return .notFound(message: message)
        default:
            return .horizonError(error: horizonError)
        }
        return .horizonError(error: horizonError)
    }
}
