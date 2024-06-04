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

public enum GetNetworkResponseEnum {
    case success(response: GetNetworkResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetLedgerEntriesResponseEnum {
    case success(response: GetLedgerEntriesResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetLatestLedgerResponseEnum {
    case success(response: GetLatestLedgerResponse)
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

public enum GetTransactionResponseEnum {
    case success(response: GetTransactionResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetEventsResponseEnum {
    case success(response: GetEventsResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetNonceResponseEnum {
    case success(response: UInt64)
    case failure(error: SorobanRpcRequestError)
}

public enum GetContractCodeResponseEnum {
    case success(response: ContractCodeEntryXDR)
    case failure(error: SorobanRpcRequestError)
}

public enum GetAccountResponseEnum {
    case success(response: Account)
    case failure(error: SorobanRpcRequestError)
}

public enum GetContractDataResponseEnum {
    case success(response: LedgerEntry)
    case failure(error: SorobanRpcRequestError)
}

/// A closure to be called with the response from a post challenge request.
public typealias GetHealthResponseClosure = (_ response:GetHealthResponseEnum) -> (Void)
public typealias GetNetworkResponseClosure = (_ response:GetNetworkResponseEnum) -> (Void)
public typealias GetLedgerEntriesResponseClosure = (_ response:GetLedgerEntriesResponseEnum) -> (Void)
public typealias GetLatestLedgerResponseClosure = (_ response:GetLatestLedgerResponseEnum) -> (Void)
public typealias SimulateTransactionResponseClosure = (_ response:SimulateTransactionResponseEnum) -> (Void)
public typealias SendTransactionResponseClosure = (_ response:SendTransactionResponseEnum) -> (Void)
public typealias GetTransactionResponseClosure = (_ response:GetTransactionResponseEnum) -> (Void)
public typealias GetEventsResponseClosure = (_ response:GetEventsResponseEnum) -> (Void)
public typealias GetNonceResponseClosure = (_ response:GetNonceResponseEnum) -> (Void)
public typealias GetContractCodeResponseClosure = (_ response:GetContractCodeResponseEnum) -> (Void)
public typealias GetAccountResponseClosure = (_ response:GetAccountResponseEnum) -> (Void)
public typealias GetContractDataResponseClosure = (_ response:GetContractDataResponseEnum) -> (Void)

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
    
    /// Init a SorobanServer instance
    ///
    /// - Parameter endpoint: Endpoint representing the url of the soroban rpc server to use
    ///
    public init(endpoint:String) {
        self.endpoint = endpoint
    }
    
    /// General node health check request.
    /// See: https://soroban.stellar.org/api/methods/getHealth
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
    
    /// General info about the currently configured network.
    /// See: https://soroban.stellar.org/api/methods/getNetwork
    public func getNetwork(completion:@escaping GetNetworkResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getNetwork")) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let network = try self.jsonDecoder.decode(GetNetworkResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: network))
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
    /// See: https://soroban.stellar.org/api/methods/getLedgerEntries
    public func getLedgerEntries(base64EncodedKeys: [String], completion:@escaping GetLedgerEntriesResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getLedgerEntries", args: ["keys" : base64EncodedKeys])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(GetLedgerEntriesResponse.self, from: JSONSerialization.data(withJSONObject: result))
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
    
    /// For finding out the current latest known ledger of this node. This is a subset of the ledger info from Horizon.
    /// See: https://soroban.stellar.org/api/methods/getLatestLedger
    public func getLatestLedger(completion:@escaping GetLatestLedgerResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getLatestLedger")) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let response = try self.jsonDecoder.decode(GetLatestLedgerResponse.self, from: JSONSerialization.data(withJSONObject: result))
                            completion(.success(response: response))
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
    
    /// loads the contract code (wasm binary) for the given wasmId
    public func getContractCodeForWasmId(wasmId: String, completion:@escaping GetContractCodeResponseClosure) {
        let contractCodeKey = LedgerKeyContractCodeXDR(wasmId: wasmId)
        let ledgerKey = LedgerKeyXDR.contractCode(contractCodeKey)
        if let ledgerKeyBase64 = ledgerKey.xdrEncoded {
            self.getLedgerEntries(base64EncodedKeys:[ledgerKeyBase64]) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    let data = try? LedgerEntryDataXDR(fromBase64: response.entries[0].xdr)
                    if let contractCode = data?.contractCode {
                        completion(.success(response: contractCode))
                    }
                    else {
                        completion(.failure(error: .requestFailed(message: "could not extract code")))
                    }
                case .failure(let error):
                    completion(.failure(error: error))
                }
            }
        } else {
            completion(.failure(error: .requestFailed(message: "could not create ledger key")))
        }
    }
    
    /// loads the contract code (wasm binary) for the given contractId
    public func getContractCodeForContractId(contractId: String, completion:@escaping GetContractCodeResponseClosure) throws {
        let contractDataKey = LedgerKeyContractDataXDR(contract: try SCAddressXDR.init(contractId: contractId),
                                                       key: SCValXDR.ledgerKeyContractInstance,
                                                       durability: ContractDataDurability.persistent)
        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
        if let ledgerKeyBase64 = ledgerKey.xdrEncoded {
            self.getLedgerEntries(base64EncodedKeys:[ledgerKeyBase64]) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    let data = try? LedgerEntryDataXDR(fromBase64: response.entries[0].xdr)
                    if let contractData = data?.contractData, let wasmId = contractData.val.contractInstance?.executable.wasm?.wrapped.hexEncodedString() {
                        self.getContractCodeForWasmId(wasmId: wasmId) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                completion(.success(response: response))
                            case .failure(let error):
                                completion(.failure(error: error))
                            }
                        }
                    }
                    else {
                        completion(.failure(error: .requestFailed(message: "could not extract wasm id")))
                    }
                case .failure(let error):
                    completion(.failure(error: error))
                }
            }
        } else {
            completion(.failure(error: .requestFailed(message: "could not create ledger key")))
        }
    }
    
    /// Fetches a minimal set of current info about a Stellar account. Needed to get the current sequence
    /// number for the account, so you can build a successful transaction. Fails if the account was not found or accountiId is invalid
    public func getAccount(accountId:String, completion:@escaping GetAccountResponseClosure) {
        if let publicKey = try? PublicKey(accountId: accountId) {
            let accountKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: publicKey))
            if let ledgerKeyBase64 = accountKey.xdrEncoded {
                self.getLedgerEntries(base64EncodedKeys:[ledgerKeyBase64]) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        let data = try? LedgerEntryDataXDR(fromBase64: response.entries[0].xdr)
                        if let accountData = data?.account {
                            let account = Account(keyPair: KeyPair(publicKey: accountData.accountID), sequenceNumber: accountData.sequenceNumber);
                            completion(.success(response: account))
                        }
                        else {
                            completion(.failure(error: .requestFailed(message: "could not find account")))
                        }
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                }
            } else {
                completion(.failure(error: .requestFailed(message: "could not create ledger key")))
            }
        } else {
            completion(.failure(error: .requestFailed(message: "invalid accountId")))
        }
        
    }
    
    /// Reads the current value of contract data ledger entries directly.
    public func getContractData(contractId: String, key: SCValXDR, durability: ContractDataDurability, completion:@escaping GetContractDataResponseClosure) {
        if let contractAddress = try? SCAddressXDR.init(contractId: contractId) {
            let contractDataKey = LedgerKeyContractDataXDR(contract: contractAddress, key: key, durability: durability)
            let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
            if let ledgerKeyBase64 = ledgerKey.xdrEncoded {
                self.getLedgerEntries(base64EncodedKeys:[ledgerKeyBase64]) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        if let result = response.entries.first {
                            completion(.success(response: result))
                        }
                        else {
                            completion(.failure(error: .requestFailed(message: "could not find contract data")))
                        }
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                }
            } else {
                completion(.failure(error: .requestFailed(message: "could not create ledger key")))
            }
        } else {
            completion(.failure(error: .requestFailed(message: "invalid contractId")))
        }
    }
    
    /// Submit a trial contract invocation to get back return values, expected ledger footprint, and expected costs.
    /// See: https://soroban.stellar.org/api/methods/simulateTransaction
    public func simulateTransaction(simulateTxRequest: SimulateTransactionRequest, completion:@escaping SimulateTransactionResponseClosure) {
        
        request(body: try? buildRequestJson(method: "simulateTransaction", args: simulateTxRequest.buildRequestParams())) { (result) -> (Void) in
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
    /// See: https://soroban.stellar.org/api/methods/sendTransaction
    public func sendTransaction(transaction: Transaction, completion:@escaping SendTransactionResponseClosure) {
        
        request(body: try? buildRequestJson(method: "sendTransaction", args: ["transaction": transaction.encodedEnvelope()])) { (result) -> (Void) in
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
    /// See: https://soroban.stellar.org/api/methods/getTransaction
    public func getTransaction(transactionHash:String, completion:@escaping GetTransactionResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getTransaction", args: ["hash": transactionHash])) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(GetTransactionResponse.self, from: JSONSerialization.data(withJSONObject: result))
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
    
    /// Clients can request a filtered list of events emitted by a given ledger range.
    /// Soroban-RPC will support querying within a maximum 24 hours of recent ledgers.
    /// Note, this could be used by the client to only prompt a refresh when there is a new ledger with relevant events. It should also be used by backend Dapp components to "ingest" events into their own database for querying and serving.
    /// If making multiple requests, clients should deduplicate any events received, based on the event's unique id field. This prevents double-processing in the case of duplicate events being received.
    /// By default soroban-rpc retains the most recent 24 hours of events.
    /// See: https://soroban.stellar.org/api/methods/getEvents
    public func getEvents(startLedger:Int, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil, completion:@escaping GetEventsResponseClosure) {
        
        request(body: try? buildRequestJson(method: "getEvents", args: buildEventsRequestParams(startLedger: startLedger, eventFilters: eventFilters, paginationOptions: paginationOptions))) { (result) -> (Void) in
            switch result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = response["result"] as? [String: Any] {
                        do {
                            let decoded = try self.jsonDecoder.decode(GetEventsResponse.self, from: JSONSerialization.data(withJSONObject: result))
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
    
    private func buildEventsRequestParams(startLedger:Int, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil) -> [String : Any] {
        var result: [String : Any] = [
            "startLedger": startLedger
        ]
        // filters
        if (eventFilters != nil && eventFilters!.count > 0) {
            var arr:[[String : Any]] = []
            for event in eventFilters! {
                arr.append(event.buildRequestParams())
            }
            result["filters"] = arr
        }
        
        // pagination options
        if (paginationOptions != nil) {
            let params = paginationOptions!.buildRequestParams()
            if (params != nil) {
                result["pagination"] = params
            }
        }
        return result;
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
