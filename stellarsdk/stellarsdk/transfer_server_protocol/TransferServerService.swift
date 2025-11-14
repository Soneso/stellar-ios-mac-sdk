//
//  TransferServerService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for creating a TransferServerService instance from a domain's stellar.toml file.
public enum TransferServerServiceForDomainEnum {
    /// Successfully created TransferServerService instance with endpoint from stellar.toml.
    case success(response: TransferServerService)
    /// Failed to create service due to invalid domain, malformed TOML, or missing TRANSFER_SERVER.
    case failure(error: TransferServerError)
}

/// Result enum for SEP-6 deposit requests.
public enum DepositResponseEnum {
    /// Successfully initiated deposit with instructions for transferring external assets to anchor.
    case success(response: DepositResponse)
    /// Failed to initiate deposit due to authentication, validation, or anchor service error.
    case failure(error: TransferServerError)
}

/// Result enum for SEP-6 withdrawal requests.
public enum WithdrawResponseEnum {
    /// Successfully initiated withdrawal with instructions for receiving off-chain assets from anchor.
    case success(response: WithdrawResponse)
    /// Failed to initiate withdrawal due to authentication, validation, or anchor service error.
    case failure(error: TransferServerError)
}

/// Result enum for SEP-6 anchor information requests.
public enum AnchorInfoResponseEnum {
    /// Successfully retrieved anchor capabilities including supported assets and operations.
    case success(response: AnchorInfoResponse)
    /// Failed to retrieve anchor info due to network or anchor service error.
    case failure(error: TransferServerError)
}

/// Result enum for SEP-6 transaction history requests.
public enum AnchorTransactionsResponseEnum {
    /// Successfully retrieved list of deposit and withdrawal transactions with current status.
    case success(response: AnchorTransactionsResponse)
    /// Failed to retrieve transaction history due to authentication or anchor service error.
    case failure(error: TransferServerError)
}

/// Result enum for SEP-6 individual transaction requests.
public enum AnchorTransactionResponseEnum {
    /// Successfully retrieved detailed status and information for the requested transaction.
    case success(response: AnchorTransactionResponse)
    /// Failed to retrieve transaction details due to authentication or anchor service error.
    case failure(error: TransferServerError)
}

/// Result enum for SEP-6 fee calculation requests (deprecated, use SEP-38 /price endpoint).
public enum AnchorFeeResponseEnum {
    /// Successfully retrieved calculated fee for the specified deposit or withdrawal operation.
    case success(response: AnchorFeeResponse)
    /// Failed to calculate fee due to invalid parameters or anchor service error.
    case failure(error: TransferServerError)
}

/// A closure to be called with the response from a transfer server for domain request.
public typealias TransferServerServiceClosure = (_ response:TransferServerServiceForDomainEnum) -> (Void)

/// A closure to be called with the response from a deposit request.
public typealias DepositResponseClosure = (_ response:DepositResponseEnum) -> (Void)

/// A closure to be called with the response from a withdraw request.
public typealias WithdrawResponseClosure = (_ response:WithdrawResponseEnum) -> (Void)

/// A closure to be called with the response from a anchor info request.
public typealias AnchorInfoResponseClosure = (_ response:AnchorInfoResponseEnum) -> (Void)

/// A closure to be called with the response from a transactions request.
public typealias AnchorTransactionsResponseClosure = (_ response:AnchorTransactionsResponseEnum) -> (Void)

/// A closure to be called with the response from a transaction request.
public typealias AnchorTransactionResponseClosure = (_ response:AnchorTransactionResponseEnum) -> (Void)

/// A closure to be called with the response from a fee request.
public typealias AnchorFeeResponseClosure = (_ response:AnchorFeeResponseEnum) -> (Void)

/// Implements SEP-0006 - Deposit and Withdrawal API.
///
/// This class provides programmatic deposit and withdrawal functionality for Stellar assets
/// without requiring user interaction in a web interface. Unlike SEP-0024, SEP-6 is designed
/// for automated workflows and server-to-server integrations.
///
/// ## Key Differences from SEP-0024
///
/// - **SEP-6**: Programmatic API for automation (no user web interface)
/// - **SEP-24**: Interactive flows with hosted web UI for user input
///
/// ## Typical Workflow
///
/// ```swift
/// // Initialize service
/// let result = await TransferServerService.forDomain(domain: "testanchor.stellar.org")
/// guard case .success(let service) = result else { return }
///
/// // Get info about supported assets
/// let info = await service.info()
///
/// // Deposit flow
/// let depositRequest = DepositRequest(
///     assetCode: "USDC",
///     account: accountId,
///     jwt: jwtToken
/// )
/// let depositResult = await service.deposit(request: depositRequest)
///
/// // Withdraw flow
/// let withdrawRequest = WithdrawRequest(
///     type: "bank_account",
///     assetCode: "USDC",
///     account: accountId,
///     dest: "123456789", // Bank account number
///     jwt: jwtToken
/// )
/// let withdrawResult = await service.withdraw(request: withdrawRequest)
/// ```
///
/// ## Exchange Operations
///
/// SEP-6 supports asset conversion during deposit/withdrawal using SEP-38 quotes:
///
/// ```swift
/// // Deposit with exchange (e.g., receive BRL, send USDC to Stellar)
/// let exchangeRequest = DepositExchangeRequest(
///     destinationAsset: "stellar:USDC:G...",
///     sourceAsset: "iso4217:BRL",
///     amount: "1000",
///     account: accountId,
///     jwt: jwtToken
/// )
/// let result = await service.depositExchange(request: exchangeRequest)
/// ```
///
/// See also:
/// - [SEP-0006 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
/// - [InteractiveService] for SEP-24 (interactive flows)
/// - [WebAuthenticator] for SEP-10 authentication
public class TransferServerService: NSObject {

    /// The base URL of the SEP-6 transfer server endpoint for programmatic deposit and withdrawal.
    public var transferServiceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()

    /// Initializes a SEP-6 transfer server service with the specified endpoint address.
    /// - Parameter serviceAddress: The base URL of the transfer server, trailing slashes are automatically removed.
    public init(serviceAddress:String) {

        if (serviceAddress.hasSuffix("/")) {
            self.transferServiceAddress = String(serviceAddress.dropLast())
        } else {
            self.transferServiceAddress = serviceAddress
        }

        serviceHelper = ServiceHelper(baseURL: self.transferServiceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates a TransferServerService instance based on information from the stellar.toml file for a given domain.
    @available(*, renamed: "forDomain(domain:)")
    public static func forDomain(domain:String, completion:@escaping TransferServerServiceClosure) {
        Task {
            let result = await forDomain(domain: domain)
            completion(result)
        }
    }
    
    /// Creates a TransferServerService instance based on information from the stellar.toml file for a given domain.
    public static func forDomain(domain:String) async -> TransferServerServiceForDomainEnum {
        let transferServerKey = "TRANSFER_SERVER"
        
        guard let url = URL(string: "\(domain)/.well-known/stellar.toml") else {
            return .failure(error: .invalidDomain)
        }
        
        do {
            let tomlString = try String(contentsOf: url, encoding: .utf8)
            let toml = try Toml(withString: tomlString)
            if let transferServerAddress = toml.string(transferServerKey) {
                let transferServerService = TransferServerService(serviceAddress: transferServerAddress)
                return .success(response: transferServerService)
            } else {
                return .failure(error: .noTransferServerSet)
            }
            
        } catch {
            return .failure(error: .invalidToml)
        }
    }
    
    /// Initiates a SEP-6 deposit flow to convert external assets into Stellar tokens via an anchor.
    /// - Parameters:
    ///   - request: Deposit request containing asset code, destination account, and optional parameters.
    ///   - completion: Callback with deposit instructions or error response from the anchor.
    @available(*, renamed: "deposit(request:)")
    public func deposit(request: DepositRequest, completion:@escaping DepositResponseClosure) {
        Task {
            let result = await deposit(request: request)
            completion(result)
        }
    }

    /// Initiates a SEP-6 deposit flow to convert external assets into Stellar tokens via an anchor.
    /// - Parameter request: Deposit request containing asset code, destination account, and optional parameters.
    /// - Returns: Deposit response with instructions for transferring external assets to the anchor, or an error.
    public func deposit(request: DepositRequest) async -> DepositResponseEnum {
        var requestPath = "/deposit?asset_code=\(request.assetCode)&account=\(request.account)"
        if let memoType = request.memoType {
            requestPath += "&memo_type=\(memoType)"
        }
        if let memo = request.memo {
            requestPath += "&memo=\(memo)"
        }
        if let emailAddress = request.emailAddress {
            requestPath += "&email_address=\(emailAddress)"
        }
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        if let walletName = request.walletName {
            requestPath += "&wallet_name=\(walletName)"
        }
        if let walletUrl = request.walletUrl {
            requestPath += "&wallet_url=\(walletUrl)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        if let onChangeCallback = request.onChangeCallback {
            requestPath += "&on_change_callback=\(onChangeCallback)"
        }
        if let amount = request.amount {
            requestPath += "&amount=\(amount)"
        }
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let claimableBalanceSupported = request.claimableBalanceSupported {
            requestPath += "&claimable_balance_supported=\(claimableBalanceSupported)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(DepositResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Initiates a SEP-6 deposit with asset conversion using SEP-38 quotes for non-equivalent token exchange.
    /// - Parameters:
    ///   - request: Exchange deposit request specifying source asset, destination asset, amount, and account.
    ///   - completion: Callback with deposit instructions including conversion details or error response.
    @available(*, renamed: "depositExchange(request:)")
    public func depositExchange(request: DepositExchangeRequest, completion:@escaping DepositResponseClosure) {
        Task {
            let result = await depositExchange(request: request)
            completion(result)
        }
    }

    /// Initiates a SEP-6 deposit with asset conversion using SEP-38 quotes for non-equivalent token exchange.
    /// - Parameter request: Exchange deposit request specifying source asset, destination asset, amount, and account.
    /// - Returns: Deposit response with conversion details and instructions, or an error.
    public func depositExchange(request: DepositExchangeRequest) async -> DepositResponseEnum {
        var requestPath = "/deposit-exchange?destination_asset=\(request.destinationAsset)&source_asset=\(request.sourceAsset)&amount=\(request.amount)&account=\(request.account)"
        if let quoteId = request.quoteId {
            requestPath += "&quote_id=\(quoteId)"
        }
        if let memoType = request.memoType {
            requestPath += "&memo_type=\(memoType)"
        }
        if let memo = request.memo {
            requestPath += "&memo=\(memo)"
        }
        if let emailAddress = request.emailAddress {
            requestPath += "&email_address=\(emailAddress)"
        }
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        if let walletName = request.walletName {
            requestPath += "&wallet_name=\(walletName)"
        }
        if let walletUrl = request.walletUrl {
            requestPath += "&wallet_url=\(walletUrl)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        if let onChangeCallback = request.onChangeCallback {
            requestPath += "&on_change_callback=\(onChangeCallback)"
        }
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let claimableBalanceSupported = request.claimableBalanceSupported {
            requestPath += "&claimable_balance_supported=\(claimableBalanceSupported)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(DepositResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Initiates a SEP-6 withdrawal flow to convert Stellar tokens into off-chain assets via an anchor.
    /// - Parameters:
    ///   - request: Withdrawal request with asset code, withdrawal type, destination, and optional account details.
    ///   - completion: Callback with withdrawal instructions or error response from the anchor.
    @available(*, renamed: "withdraw(request:)")
    public func withdraw(request: WithdrawRequest, completion:@escaping WithdrawResponseClosure) {
        Task {
            let result = await withdraw(request: request)
            completion(result)
        }
    }

    /// Initiates a SEP-6 withdrawal flow to convert Stellar tokens into off-chain assets via an anchor.
    /// - Parameter request: Withdrawal request with asset code, withdrawal type, destination, and optional account details.
    /// - Returns: Withdrawal response with instructions for receiving off-chain assets, or an error.
    public func withdraw(request: WithdrawRequest) async -> WithdrawResponseEnum {
        var requestPath = "/withdraw?type=\(request.type)&asset_code=\(request.assetCode)"
        if let dest = request.dest {
            requestPath += "&dest=\(dest)"
        }
        if let destExtra = request.destExtra {
            requestPath += "&dest_extra=\(destExtra)"
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
        if let walletName = request.walletName {
            requestPath += "&wallet_name=\(walletName)"
        }
        if let walletUrl = request.walletUrl {
            requestPath += "&wallet_url=\(walletUrl)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        if let onChangeCallback = request.onChangeCallback {
            requestPath += "&on_change_callback=\(onChangeCallback)"
        }
        if let amount = request.amount {
            requestPath += "&amount=\(amount)"
        }
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let refundMemo = request.refundMemo {
            requestPath += "&refund_memo=\(refundMemo)"
        }
        if let refundMemoType = request.refundMemoType {
            requestPath += "&refund_memo_type=\(refundMemoType)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(WithdrawResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error)) 
        }
    }
    
    /// Initiates a SEP-6 withdrawal with asset conversion using SEP-38 quotes for non-equivalent token exchange.
    /// - Parameters:
    ///   - request: Exchange withdrawal request specifying source asset, destination asset, amount, and withdrawal details.
    ///   - completion: Callback with withdrawal instructions including conversion details or error response.
    @available(*, renamed: "withdrawExchange(request:)")
    public func withdrawExchange(request: WithdrawExchangeRequest, completion:@escaping WithdrawResponseClosure) {
        Task {
            let result = await withdrawExchange(request: request)
            completion(result)
        }
    }

    /// Initiates a SEP-6 withdrawal with asset conversion using SEP-38 quotes for non-equivalent token exchange.
    /// - Parameter request: Exchange withdrawal request specifying source asset, destination asset, amount, and withdrawal details.
    /// - Returns: Withdrawal response with conversion details and instructions, or an error.
    public func withdrawExchange(request: WithdrawExchangeRequest) async -> WithdrawResponseEnum {
        var requestPath = "/withdraw-exchange?type=\(request.type)&source_asset=\(request.sourceAsset)&destination_asset=\(request.destinationAsset)&amount=\(request.amount)"
        if let quoteId = request.quoteId {
            requestPath += "&quote_id=\(quoteId)"
        }
        if let dest = request.dest {
            requestPath += "&dest=\(dest)"
        }
        if let destExtra = request.destExtra {
            requestPath += "&dest_extra=\(destExtra)"
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
        if let walletName = request.walletName {
            requestPath += "&wallet_name=\(walletName)"
        }
        if let walletUrl = request.walletUrl {
            requestPath += "&wallet_url=\(walletUrl)"
        }
        if let lang = request.lang {
            requestPath += "&lang=\(lang)"
        }
        if let onChangeCallback = request.onChangeCallback {
            requestPath += "&on_change_callback=\(onChangeCallback)"
        }
        if let countryCode = request.countryCode {
            requestPath += "&country_code=\(countryCode)"
        }
        if let refundMemo = request.refundMemo {
            requestPath += "&refund_memo=\(refundMemo)"
        }
        if let refundMemoType = request.refundMemoType {
            requestPath += "&refund_memo_type=\(refundMemoType)"
        }
        if let customerId = request.customerId {
            requestPath += "&customer_id=\(customerId)"
        }
        if let locationId = request.locationId {
            requestPath += "&location_id=\(locationId)"
        }
        if let extraFields = request.extraFields {
            extraFields.forEach {
                requestPath += "&\($0.key)=\($0.value)"
            }
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(WithdrawResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Retrieves SEP-6 anchor capabilities including supported assets, operations, and authentication requirements.
    /// - Parameters:
    ///   - language: RFC 4646 language code for localized responses, defaults to English.
    ///   - jwtToken: Optional SEP-10 authentication token if required by the anchor.
    ///   - completion: Callback with anchor capabilities or error response.
    @available(*, renamed: "info(language:jwtToken:)")
    public func info(language: String? = nil, jwtToken:String? = nil, completion:@escaping AnchorInfoResponseClosure) {
        Task {
            let result = await info(language: language)
            completion(result)
        }
    }

    /// Retrieves SEP-6 anchor capabilities including supported assets, operations, and authentication requirements.
    /// - Parameters:
    ///   - language: RFC 4646 language code for localized responses, defaults to English.
    ///   - jwtToken: Optional SEP-10 authentication token if required by the anchor.
    /// - Returns: Anchor capabilities and configuration, or an error.
    public func info(language: String? = nil, jwtToken:String? = nil) async -> AnchorInfoResponseEnum {
        var requestPath = "/info"
        if let language = language {
            requestPath += "&lang=\(language)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwtToken)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(AnchorInfoResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Retrieves fee information for SEP-6 deposit or withdrawal operations (deprecated, use SEP-38 /price endpoint).
    /// - Parameters:
    ///   - request: Fee request containing operation type, asset code, and transaction amount.
    ///   - completion: Callback with calculated fee details or error response.
    @available(*, renamed: "fee(request:)")
    public func fee(request: FeeRequest,  completion:@escaping AnchorFeeResponseClosure) {
        Task {
            let result = await fee(request: request)
            completion(result)
        }
    }

    /// Retrieves fee information for SEP-6 deposit or withdrawal operations (deprecated, use SEP-38 /price endpoint).
    /// - Parameter request: Fee request containing operation type, asset code, and transaction amount.
    /// - Returns: Calculated fee details for the specified operation, or an error.
    public func fee(request: FeeRequest) async -> AnchorFeeResponseEnum {
        var requestPath = "/fee?operation=\(request.operation)&asset_code=\(request.assetCode)&amount=\(request.amount)"
        
        if let type = request.type {
            requestPath += "&type=\(type)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: request.jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(AnchorFeeResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Retrieves transaction history for SEP-6 deposits and withdrawals filtered by account and asset.
    /// - Parameters:
    ///   - request: Transaction query request with account, asset code, optional filters, and SEP-10 JWT token.
    ///   - completion: Callback with transaction history list or error response.
    @available(*, renamed: "getTransactions(request:)")
    public func getTransactions(request: AnchorTransactionsRequest,  completion:@escaping AnchorTransactionsResponseClosure) {
        Task {
            let result = await getTransactions(request: request)
            completion(result)
        }
    }

    /// Retrieves transaction history for SEP-6 deposits and withdrawals filtered by account and asset.
    /// - Parameter request: Transaction query request with account, asset code, optional filters, and SEP-10 JWT token.
    /// - Returns: List of deposit and withdrawal transactions with current status details, or an error.
    public func getTransactions(request: AnchorTransactionsRequest) async -> AnchorTransactionsResponseEnum {
        var requestPath = "/transactions?asset_code=\(request.assetCode)&account=\(request.account)"
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
                let response = try self.jsonDecoder.decode(AnchorTransactionsResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Retrieves detailed status and information for a specific SEP-6 transaction by ID or Stellar transaction hash.
    /// - Parameters:
    ///   - request: Transaction lookup request with transaction ID, Stellar hash, or external ID, and SEP-10 JWT token.
    ///   - completion: Callback with transaction details or error response.
    @available(*, renamed: "getTransaction(request:)")
    public func getTransaction(request: AnchorTransactionRequest,  completion:@escaping AnchorTransactionResponseClosure) {
        Task {
            let result = await getTransaction(request: request)
            completion(result)
        }
    }

    /// Retrieves detailed status and information for a specific SEP-6 transaction by ID or Stellar transaction hash.
    /// - Parameter request: Transaction lookup request with transaction ID, Stellar hash, or external ID, and SEP-10 JWT token.
    /// - Returns: Detailed transaction status, amounts, and processing information, or an error.
    public func getTransaction(request: AnchorTransactionRequest) async -> AnchorTransactionResponseEnum {
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
            first = false
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
                let response = try self.jsonDecoder.decode(AnchorTransactionResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Updates a SEP-6 transaction with additional customer information when requested by the anchor via pending_transaction_info_update status.
    /// - Parameters:
    ///   - id: The anchor's transaction ID requiring additional information.
    ///   - jwt: SEP-10 authentication token for the transaction owner.
    ///   - contentType: HTTP content type for the request body (e.g., application/json or multipart/form-data).
    ///   - body: Encoded request data containing the required customer information updates.
    ///   - completion: Callback with updated transaction details or error response.
    @available(*, renamed: "patchTransaction(id:jwt:contentType:body:)")
    public func patchTransaction(id:String, jwt:String?, contentType:String, body:Data, completion:@escaping AnchorTransactionResponseClosure) {
        Task {
            let result = await patchTransaction(id: id, jwt: jwt, contentType: contentType, body: body)
            completion(result)
        }
    }

    /// Updates a SEP-6 transaction with additional customer information when requested by the anchor via pending_transaction_info_update status.
    /// - Parameters:
    ///   - id: The anchor's transaction ID requiring additional information.
    ///   - jwt: SEP-10 authentication token for the transaction owner.
    ///   - contentType: HTTP content type for the request body (e.g., application/json or multipart/form-data).
    ///   - body: Encoded request data containing the required customer information updates.
    /// - Returns: Updated transaction details with new status, or an error.
    public func patchTransaction(id:String, jwt:String?, contentType:String, body:Data) async -> AnchorTransactionResponseEnum {
        let requestPath = "/transaction/\(id)"
        
        let result = await serviceHelper.PATCHRequestWithPath(path: requestPath, jwtToken: jwt, contentType: contentType, body: body)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(AnchorTransactionResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }

    /// Converts Horizon HTTP errors into SEP-6 specific transfer server errors, handling authentication and customer info requirements.
    /// - Parameter horizonError: The raw HTTP error from the anchor's transfer server endpoint.
    /// - Returns: A structured TransferServerError with parsed customer information needs or authentication requirements.
    private func errorFor(horizonError:HorizonRequestError) -> TransferServerError {
        switch horizonError {
        case .forbidden(let message, _):
            if let data = message.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let type = json["type"] as? String {
                        if type == "non_interactive_customer_info_needed" {
                            let response = try self.jsonDecoder.decode(CustomerInformationNeededNonInteractive.self, from: data)
                            return .informationNeeded(response: .nonInteractive(info: response))
                        } else if type == "customer_info_status" {
                            let response = try self.jsonDecoder.decode(CustomerInformationStatus.self, from: data)
                            return.informationNeeded(response: .status(info: response))
                        } else if type == "authentication_required" {
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
             .notFound(let message, _),
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
        default:
            return .horizonError(error: horizonError)
        }
        return .horizonError(error: horizonError)
    }
    
}
