//
//  SorobanServer.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed post challenge responses.
public enum GetHealthResponseEnum {
    case success(response: GetHealthResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetAccountResponseEnum {
    case success(response: GetAccountResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetLedgerEntryResponseEnum {
    case success(response: GetLedgerEntryResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum SimulateTransactionResponseEnum {
    case success(response: SimulateTransactionResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum SendTransactionResponseEnum {
    case success(response: SendTransactionResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetTransactionStatusResponseEnum {
    case success(response: GetTransactionStatusResponse)
    case failure(error: SorobanRpcRequestError)
}

/// A closure to be called with the response from a post challenge request.
public typealias GetHealthResponseClosure = (_ response:GetHealthResponseEnum) -> (Void)
public typealias GetAccountResponseClosure = (_ response:GetAccountResponseEnum) -> (Void)
public typealias GetLedgerEntryResponseClosure = (_ response:GetLedgerEntryResponseEnum) -> (Void)
public typealias SimulateTransactionResponseClosure = (_ response:SimulateTransactionResponseEnum) -> (Void)
public typealias SendTransactionResponseClosure = (_ response:SendTransactionResponseEnum) -> (Void)
public typealias GetTransactionStatusResponseClosure = (_ response:GetTransactionStatusResponseEnum) -> (Void)

/// An enum to diferentiate between succesful and failed responses
private enum RpcResult {
    case success(data: Data)
    case failure(error: SorobanRpcRequestError)
}

/// A closure to be called when a HTTP response is received
private typealias RpcResponseClosure = (_ response:RpcResult) -> (Void)

/// This class helps you to connect to a local or remote soroban rpc server
/// and send requests to the server. It parses the results and provides
/// corresponding response objects.
public class SorobanServer {
    private let endpoint: String
    private let jsonDecoder = JSONDecoder()
    
    static let clientVersionHeader = "X-Client-Version"
    static let clientNameHeader = "X-Client-Name"
    static let clientApplicationNameHeader = "X-App-Name"
    static let clientApplicationVersionHeader = "X-App-Version"

    lazy var requestHeaders: [String: String] = {
        var headers: [String: String] = [:]

        let mainBundle = Bundle.main
        let frameworkBundle = Bundle(for: ServiceHelper.self)
        
        if let bundleIdentifier = frameworkBundle.infoDictionary?["CFBundleIdentifier"] as? String {
            headers[SorobanServer.clientNameHeader] = bundleIdentifier
        }
        if let bundleVersion = frameworkBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers[SorobanServer.clientVersionHeader] = bundleVersion
        }
        if let applicationBundleID = mainBundle.infoDictionary?["CFBundleIdentifier"] as? String {
            headers[SorobanServer.clientApplicationNameHeader] = applicationBundleID
        }
        if let applicationBundleVersion = mainBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers[SorobanServer.clientApplicationVersionHeader] = applicationBundleVersion
        }

        return headers
    }()
    
    public var enableLogging = false
    public var acknowledgeExperimental = false
    
    /// Init a SorobanServer instance
    ///
    /// - Parameter endpoint: Endpoint representing the url of the soroban rpc server to use
    ///
    public init(endpoint:String) {
        self.endpoint = endpoint
    }
    
    /// General node health check request.
    public func getHealth(completion:@escaping GetHealthResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getHealth")) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let health = try self.jsonDecoder.decode(GetHealthResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: health))
                        } catch {
                            completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data)))
                        }
                    } else if let error = response["error"] as? [String: Any] {
                        completion(.failure(error: .errorResponse(errorData: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Fetch a minimal set of current info about a stellar account.
    public func getAccount(accountId: String, completion:@escaping GetAccountResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getAccount", args: [accountId])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(GetAccountResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: decoded))
                        } catch {
                            completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data)))
                        }
                    } else if let error = response["error"] as? [String: Any] {
                        completion(.failure(error: .errorResponse(errorData: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// For reading the current value of ledger entries directly. Allows you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry.
    /// This is a backup way to access your contract data which may not be available via events or simulateTransaction.
    /// To fetch contract wasm byte-code, use the ContractCode ledger entry key.
    public func getLedgerEntry(base64EncodedKey: String, completion:@escaping GetLedgerEntryResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getLedgerEntry", args: ["key" : base64EncodedKey])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(GetLedgerEntryResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: decoded))
                        } catch {
                            completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data)))
                        }
                    } else if let error = response["error"] as? [String: Any] {
                        completion(.failure(error: .errorResponse(errorData: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Submit a trial contract invocation to get back return values, expected ledger footprint, and expected costs.
    public func simulateTransaction(transaction: Transaction, completion:@escaping SimulateTransactionResponseClosure) {
        
        request(body: try? buildRequestJson(method: "simulateTransaction", args: [transaction.encodedEnvelope()])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(SimulateTransactionResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: decoded))
                        } catch {
                            completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data)))
                        }
                    } else if let error = response["error"] as? [String: Any] {
                        completion(.failure(error: .errorResponse(errorData: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Submit a real transaction to the stellar network. This is the only way to make changes “on-chain”.
    /// Unlike Horizon, this does not wait for transaction completion. It simply validates and enqueues the transaction.
    /// Clients should call getTransactionStatus to learn about transaction success/failure.
    public func sendTransaction(transaction: Transaction, completion:@escaping SendTransactionResponseClosure) {
        
        request(body: try? buildRequestJson(method: "sendTransaction", args: [transaction.encodedEnvelope()])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(SendTransactionResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: decoded))
                        } catch {
                            completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data)))
                        }
                    } else if let error = response["error"] as? [String: Any] {
                        completion(.failure(error: .errorResponse(errorData: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Clients will poll this to tell when the transaction has been completed.
    public func getTransactionStatus(transactionHash:String, completion:@escaping GetTransactionStatusResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getTransactionStatus", args: [transactionHash])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(GetTransactionStatusResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: decoded))
                        } catch {
                            completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data)))
                        }
                    } else if let error = response["error"] as? [String: Any] {
                        completion(.failure(error: .errorResponse(errorData: error)))
                    } else {
                        completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                    }
                } else {
                    completion(.failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data)))
                }
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    private func buildRequestJson(method:String, args:Any? = nil) throws -> Data? {
        var result: [String : Any] = [
            "jsonrpc": "2.0",
            "method": method
        ]
        // params
        if (args != nil) {
            result["params"] = args
        }
        // id
        result["id"] = UUID().uuidString
        return try? JSONSerialization.data(withJSONObject: result)
    }
    
    
    private func request(body: Data?, completion: @escaping RpcResponseClosure) {
        if !self.acknowledgeExperimental {
            completion(.failure(error:.requestFailed(message:"Error: acknowledgeExperimental flag not set")))
            return
        }
        
        let url = URL(string: endpoint)!
        var urlRequest = URLRequest(url: url)

        requestHeaders.forEach {
            urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)
        }
        urlRequest.addValue( "application/json", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpMethod = "POST"
        if let body = body {
            urlRequest.httpBody = body
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error:.requestFailed(message:error.localizedDescription)))
                return
            }
            
            if let data = data, self.enableLogging {
                let log = String(decoding: data, as: UTF8.self)
                print(log)
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                var message:String!
                if let data = data {
                    message = String(data: data, encoding: String.Encoding.utf8)
                }
                if message == nil {
                    message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                }
                
                switch httpResponse.statusCode {
                case 200, 201, 202:
                    break
                default:
                    completion(.failure(error:.requestFailed(message:message)))
                    return
                }
            }
            if let data = data {
                completion(.success(data: data))
            } else {
                completion(.failure(error:.requestFailed(message:"empty response")))
            }
        }
        
        task.resume()
    }
}
