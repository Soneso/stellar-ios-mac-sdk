import Foundation

public enum InteractiveServiceForDomainEnum {
    case success(response: InteractiveService)
    case failure(error: InteractiveServiceError)
}

public enum Sep24InfoResponseEnum {
    case success(response: Sep24InfoResponse)
    case failure(error: InteractiveServiceError)
}

public enum Sep24FeeResponseEnum {
    case success(response: Sep24FeeResponse)
    case failure(error: InteractiveServiceError)
}

public enum Sep24InteractiveResponseEnum {
    case success(response: Sep24InteractiveResponse)
    case failure(error: InteractiveServiceError)
}

public enum Sep24TransactionsResponseEnum {
    case success(response: Sep24TransactionsResponse)
    case failure(error: InteractiveServiceError)
}

public enum Sep24TransactionResponseEnum {
    case success(response: Sep24TransactionResponse)
    case failure(error: InteractiveServiceError)
}

public typealias InteractiveServiceClosure = (_ response:InteractiveServiceForDomainEnum) -> (Void)
public typealias Sep24InfoResponseClosure = (_ response:Sep24InfoResponseEnum) -> (Void)
public typealias Sep24FeeResponseClosure = (_ response:Sep24FeeResponseEnum) -> (Void)
public typealias Sep24InteractiveResponseClosure = (_ response:Sep24InteractiveResponseEnum) -> (Void)
public typealias Sep24TransactionsResponseClosure = (_ response:Sep24TransactionsResponseEnum) -> (Void)
public typealias Sep24TransactionResponseClosure = (_ response:Sep24TransactionResponseEnum) -> (Void)

/// Implements SEP-0024 - Hosted Deposit and Withdrawal.
///  See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md" target="_blank">Hosted Deposit and Withdrawal</a>
public class InteractiveService: NSObject {

    public var serviceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(serviceAddress:String) {
        self.serviceAddress = serviceAddress
        serviceHelper = ServiceHelper(baseURL: serviceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Creates an InteractiveService instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
    @available(*, renamed: "forDomain(domain:)")
    public static func forDomain(domain:String, completion:@escaping InteractiveServiceClosure) {
        Task {
            let result = await forDomain(domain: domain)
            completion(result)
        }
    }
    
    /// Creates an InteractiveService instance based on information from [stellar.toml](https://www.stellar.org/developers/learn/concepts/stellar-toml.html) file for a given domain.
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
    
    
    /**
     * Get the anchors basic info about what their TRANSFER_SERVER_SEP0024 support to wallets and clients.
     * - Parameter language: (optional) Language code specified using ISO 639-1. description fields in the response should be in this language. Defaults to en.
     */
    @available(*, renamed: "info(language:)")
    public func info(language: String? = nil, completion:@escaping Sep24InfoResponseClosure) {
        Task {
            let result = await info(language: language)
            completion(result)
        }
    }
    
    /**
     * Get the anchors basic info about what their TRANSFER_SERVER_SEP0024 support to wallets and clients.
     * - Parameter language: (optional) Language code specified using ISO 639-1. description fields in the response should be in this language. Defaults to en.
     */
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
    
    /**
     * Get the anchor's to reported fee that would be charged for a given deposit or withdraw operation.
     * This is important to allow an anchor to accurately report fees to a user even when the fee schedule is complex.
     * If a fee can be fully expressed with the fee_fixed, fee_percent or fee_minimum fields in the /info response,
     * then an anchor will not implement this endpoint.
     * - Parameter request Sep24FeeRequest
     */
    @available(*, renamed: "fee(request:)")
    public func fee(request: Sep24FeeRequest, completion:@escaping Sep24FeeResponseClosure) {
        Task {
            let result = await fee(request: request)
            completion(result)
        }
    }
    
    /**
     * Get the anchor's to reported fee that would be charged for a given deposit or withdraw operation.
     * This is important to allow an anchor to accurately report fees to a user even when the fee schedule is complex.
     * If a fee can be fully expressed with the fee_fixed, fee_percent or fee_minimum fields in the /info response,
     * then an anchor will not implement this endpoint.
     * - Parameter request Sep24FeeRequest
     */
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
    
    @available(*, renamed: "deposit(request:)")
    public func deposit(request: Sep24DepositRequest, completion:@escaping Sep24InteractiveResponseClosure) {
        Task {
            let result = await deposit(request: request)
            completion(result)
        }
    }
    
    
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
    
    @available(*, renamed: "withdraw(request:)")
    public func withdraw(request: Sep24WithdrawRequest, completion:@escaping Sep24InteractiveResponseClosure) {
        Task {
            let result = await withdraw(request: request)
            completion(result)
        }
    }
    
    
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
    
    @available(*, renamed: "getTransactions(request:)")
    public func getTransactions(request: Sep24TransactionsRequest,  completion:@escaping Sep24TransactionsResponseClosure) {
        Task {
            let result = await getTransactions(request: request)
            completion(result)
        }
    }
    
    
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
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
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
    
    @available(*, renamed: "getTransaction(request:)")
    public func getTransaction(request: Sep24TransactionRequest,  completion:@escaping Sep24TransactionResponseClosure) {
        Task {
            let result = await getTransaction(request: request)
            completion(result)
        }
    }
    
    
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
