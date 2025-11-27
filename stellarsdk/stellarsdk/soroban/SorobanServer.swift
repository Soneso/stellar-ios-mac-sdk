//
//  SorobanServer.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response enum for health check requests.
///
/// Represents the result of a Soroban RPC health check operation.
public enum GetHealthResponseEnum {
    /// Successfully retrieved health status from Soroban RPC.
    case success(response: GetHealthResponse)
    /// Failed to retrieve health status, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for network information requests.
///
/// Returned when querying general information about the Soroban network configuration.
public enum GetNetworkResponseEnum {
    /// Successfully retrieved network information from Soroban RPC.
    case success(response: GetNetworkResponse)
    /// Failed to retrieve network information, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for fee statistics requests.
///
/// Contains inclusion fee statistics used for transaction prioritization and spam prevention.
public enum GetFeeStatsResponseEnum {
    /// Successfully retrieved fee statistics from Soroban RPC.
    case success(response: GetFeeStatsResponse)
    /// Failed to retrieve fee statistics, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for version information requests.
///
/// Returns RPC and Captive Core version information.
public enum GetVersionInfoResponseEnum {
    /// Successfully retrieved version information from Soroban RPC.
    case success(response: GetVersionInfoResponse)
    /// Failed to retrieve version information, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for ledger entries requests.
///
/// Used when reading the current value of ledger entries directly, including contract state.
public enum GetLedgerEntriesResponseEnum {
    /// Successfully retrieved ledger entries from Soroban RPC.
    case success(response: GetLedgerEntriesResponse)
    /// Failed to retrieve ledger entries, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for latest ledger requests.
///
/// Returns information about the most recent known ledger.
public enum GetLatestLedgerResponseEnum {
    /// Successfully retrieved latest ledger information from Soroban RPC.
    case success(response: GetLatestLedgerResponse)
    /// Failed to retrieve latest ledger information, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for transaction simulation requests.
///
/// Contains simulation results including return values, resource costs, and ledger footprint
/// for a contract invocation without submitting to the network.
public enum SimulateTransactionResponseEnum {
    /// Successfully simulated transaction on Soroban RPC.
    case success(response: SimulateTransactionResponse)
    /// Failed to simulate transaction, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for transaction submission requests.
///
/// Returned when submitting a transaction to the Soroban network.
/// Note that submission does not wait for completion.
public enum SendTransactionResponseEnum {
    /// Successfully submitted transaction to Soroban RPC.
    case success(response: SendTransactionResponse)
    /// Failed to submit transaction, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for transaction status requests.
///
/// Used to poll for transaction completion status after submission.
public enum GetTransactionResponseEnum {
    /// Successfully retrieved transaction status from Soroban RPC.
    case success(response: GetTransactionResponse)
    /// Failed to retrieve transaction status, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for transactions list requests.
///
/// Returns a paginated list of transactions starting from a specified ledger.
public enum GetTransactionsResponseEnum {
    /// Successfully retrieved transactions list from Soroban RPC.
    case success(response: GetTransactionsResponse)
    /// Failed to retrieve transactions list, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for events query requests.
///
/// Returns contract events emitted within a specified ledger range.
public enum GetEventsResponseEnum {
    /// Successfully retrieved contract events from Soroban RPC.
    case success(response: GetEventsResponse)
    /// Failed to retrieve contract events, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for account nonce requests.
///
/// Returns the current nonce for an account.
public enum GetNonceResponseEnum {
    /// Successfully retrieved account nonce from Soroban RPC.
    case success(response: UInt64)
    /// Failed to retrieve account nonce, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for ledgers list requests.
///
/// Returns a paginated list of ledgers starting from a specified point.
public enum GetLedgersResponseEnum {
    /// Successfully retrieved ledgers list from Soroban RPC.
    case success(response: GetLedgersResponse)
    /// Failed to retrieve ledgers list, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for contract code requests.
///
/// Returns the WebAssembly bytecode for a deployed contract.
public enum GetContractCodeResponseEnum {
    /// Successfully retrieved contract code from Soroban RPC.
    case success(response: ContractCodeEntryXDR)
    /// Failed to retrieve contract code, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for contract information requests.
///
/// Returns parsed contract metadata including spec entries, environment info, and contract metadata.
public enum GetContractInfoEnum {
    /// Successfully retrieved and parsed contract information from Soroban RPC.
    case success(response: SorobanContractInfo)
    /// Failed to parse contract bytecode, error details in associated value.
    case parsingFailure(error: SorobanContractParserError)
    /// Failed to retrieve contract information from RPC, error details in associated value.
    case rpcFailure(error: SorobanRpcRequestError)
}

/// Response enum for account information requests.
///
/// Returns minimal account information needed for transaction construction.
public enum GetAccountResponseEnum {
    /// Successfully retrieved account information from Soroban RPC.
    case success(response: Account)
    /// Failed to retrieve account information, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Response enum for contract data requests.
///
/// Returns the current value of contract storage entries.
public enum GetContractDataResponseEnum {
    /// Successfully retrieved contract data from Soroban RPC.
    case success(response: LedgerEntry)
    /// Failed to retrieve contract data, error details in associated value.
    case failure(error: SorobanRpcRequestError)
}

/// Callback closure for Soroban RPC health check operations.
public typealias GetHealthResponseClosure = (_ response:GetHealthResponseEnum) -> (Void)
/// Callback closure for retrieving Soroban network information.
public typealias GetNetworkResponseClosure = (_ response:GetNetworkResponseEnum) -> (Void)
/// Callback closure for retrieving Soroban fee statistics.
public typealias GetFeeStatsResponseClosure = (_ response:GetFeeStatsResponseEnum) -> (Void)
/// Callback closure for retrieving Soroban RPC version information.
public typealias GetVersionInfoResponseClosure = (_ response:GetVersionInfoResponseEnum) -> (Void)
/// Callback closure for retrieving ledger entries from Soroban state.
public typealias GetLedgerEntriesResponseClosure = (_ response:GetLedgerEntriesResponseEnum) -> (Void)
/// Callback closure for retrieving the latest ledger information from Soroban.
public typealias GetLatestLedgerResponseClosure = (_ response:GetLatestLedgerResponseEnum) -> (Void)
/// Callback closure for simulating Soroban smart contract transactions.
public typealias SimulateTransactionResponseClosure = (_ response:SimulateTransactionResponseEnum) -> (Void)
/// Callback closure for submitting Soroban transactions to the network.
public typealias SendTransactionResponseClosure = (_ response:SendTransactionResponseEnum) -> (Void)
/// Callback closure for retrieving a single Soroban transaction by hash.
public typealias GetTransactionResponseClosure = (_ response:GetTransactionResponseEnum) -> (Void)
/// Callback closure for retrieving multiple Soroban transactions.
public typealias GetTransactionsResponseClosure = (_ response:GetTransactionsResponseEnum) -> (Void)
/// Callback closure for retrieving contract events from Soroban.
public typealias GetEventsResponseClosure = (_ response:GetEventsResponseEnum) -> (Void)
/// Callback closure for retrieving the current nonce for an account.
public typealias GetNonceResponseClosure = (_ response:GetNonceResponseEnum) -> (Void)
/// Callback closure for retrieving Soroban smart contract code.
public typealias GetContractCodeResponseClosure = (_ response:GetContractCodeResponseEnum) -> (Void)
/// Callback closure for retrieving Soroban smart contract information.
public typealias GetContractInfoClosure = (_ response:GetContractInfoEnum) -> (Void)
/// Callback closure for retrieving Soroban account information.
public typealias GetAccountResponseClosure = (_ response:GetAccountResponseEnum) -> (Void)
/// Callback closure for retrieving Soroban smart contract data entries.
public typealias GetContractDataResponseClosure = (_ response:GetContractDataResponseEnum) -> (Void)
/// Callback closure for retrieving multiple ledgers from Soroban.
public typealias GetLedgersResponseClosure = (_ response:GetLedgersResponseEnum) -> (Void)

/// Internal result type distinguishing successful RPC responses from errors.
/// Used for internal HTTP request handling before type-specific parsing.
private enum RpcResult {
    case success(data: Data)
    case failure(error: SorobanRpcRequestError)
}

/// Callback closure for internal HTTP response handling.
/// Invoked when raw RPC response data is received before decoding.
private typealias RpcResponseClosure = (_ response:RpcResult) -> (Void)

/// Soroban RPC client for interacting with smart contracts on the Stellar network.
///
/// SorobanServer provides access to Soroban RPC endpoints for smart contract operations including:
/// - Contract invocation simulation and submission
/// - Reading contract state and ledger entries
/// - Querying contract events
/// - Transaction status polling
/// - Network and fee information
///
/// Initialize with your Soroban RPC endpoint URL. For testnet, use the public RPC endpoint
/// or run your own RPC server. For production, always use a reliable RPC provider.
///
/// Example usage:
/// ```swift
/// // Connect to testnet RPC
/// let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
///
/// // Get network information
/// let networkResponse = await server.getNetwork()
/// switch networkResponse {
/// case .success(let network):
///     print("Network passphrase: \(network.passphrase)")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
///
/// // Simulate a contract invocation
/// let simulateRequest = SimulateTransactionRequest(transaction: transaction)
/// let simResponse = await server.simulateTransaction(simulateTxRequest: simulateRequest)
/// switch simResponse {
/// case .success(let simulation):
///     print("Resource cost: \(simulation.cost)")
/// case .failure(let error):
///     print("Simulation failed: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [SorobanClient] for high-level contract interaction
/// - [AssembledTransaction] for transaction construction
public class SorobanServer {
    /// Soroban RPC endpoint URL for all network requests.
    private let endpoint: String
    /// JSON decoder instance for parsing RPC responses.
    private let jsonDecoder = JSONDecoder()

    /// HTTP header name for SDK version identification.
    static let clientVersionHeader = "X-Client-Version"
    /// HTTP header name for SDK client name identification.
    static let clientNameHeader = "X-Client-Name"
    /// HTTP header name for application name identification.
    static let clientApplicationNameHeader = "X-App-Name"
    /// HTTP header name for application version identification.
    static let clientApplicationVersionHeader = "X-App-Version"

    /// Automatically populated HTTP headers for RPC requests including SDK and application metadata.
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

    /// Enable detailed request/response logging for debugging. Default: false.
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
    @available(*, renamed: "getHealth()")
    public func getHealth(completion:@escaping GetHealthResponseClosure) {
        Task {
            let result = await getHealth()
            completion(result)
        }
    }
    
    /// General node health check request.
    /// See: https://soroban.stellar.org/api/methods/getHealth
    public func getHealth() async -> GetHealthResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getHealth"))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let health = try self.jsonDecoder.decode(GetHealthResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: health)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// General info about the currently configured network.
    /// See: https://soroban.stellar.org/api/methods/getNetwork
    @available(*, renamed: "getNetwork()")
    public func getNetwork(completion:@escaping GetNetworkResponseClosure) {
        Task {
            let result = await getNetwork()
            completion(result)
        }
    }
    
    /// General info about the currently configured network.
    /// See: https://soroban.stellar.org/api/methods/getNetwork
    public func getNetwork() async -> GetNetworkResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getNetwork"))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let network = try self.jsonDecoder.decode(GetNetworkResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: network)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Statistics for charged inclusion fees. The inclusion fee statistics are calculated
    /// from the inclusion fees that were paid for the transactions to be included onto the ledger.
    /// For Soroban transactions and Stellar transactions, they each have their own inclusion fees
    /// and own surge pricing. Inclusion fees are used to prevent spam and prioritize transactions
    /// during network traffic surge.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "getFeeStats()")
    public func getFeeStats(completion:@escaping GetFeeStatsResponseClosure) {
        Task {
            let result = await getFeeStats()
            completion(result)
        }
    }
    
    /// Statistics for charged inclusion fees. The inclusion fee statistics are calculated
    /// from the inclusion fees that were paid for the transactions to be included onto the ledger.
    /// For Soroban transactions and Stellar transactions, they each have their own inclusion fees
    /// and own surge pricing. Inclusion fees are used to prevent spam and prioritize transactions
    /// during network traffic surge.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    public func getFeeStats() async -> GetFeeStatsResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getFeeStats"))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let feeStats = try self.jsonDecoder.decode(GetFeeStatsResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: feeStats)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Version information about the RPC and Captive core. RPC manages its own,
    /// pared-down version of Stellar Core optimized for its own subset of needs.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "getVersionInfo()")
    public func getVersionInfo(completion:@escaping GetVersionInfoResponseClosure) {
        Task {
            let result = await getVersionInfo()
            completion(result)
        }
    }
    
    /// Version information about the RPC and Captive core. RPC manages its own,
    /// pared-down version of Stellar Core optimized for its own subset of needs.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    public func getVersionInfo() async -> GetVersionInfoResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getVersionInfo"))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let versionInfo = try self.jsonDecoder.decode(GetVersionInfoResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: versionInfo)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// For reading the current value of ledger entries directly. Allows you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry.
    /// This is a backup way to access your contract data which may not be available via events or simulateTransaction.
    /// To fetch contract wasm byte-code, use the ContractCode ledger entry key.
    /// See: https://soroban.stellar.org/api/methods/getLedgerEntries
    @available(*, renamed: "getLedgerEntries(base64EncodedKeys:)")
    public func getLedgerEntries(base64EncodedKeys: [String], completion:@escaping GetLedgerEntriesResponseClosure) {
        Task {
            let result = await getLedgerEntries(base64EncodedKeys: base64EncodedKeys)
            completion(result)
        }
    }
    
    /// For reading the current value of ledger entries directly. Allows you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry.
    /// This is a backup way to access your contract data which may not be available via events or simulateTransaction.
    /// To fetch contract wasm byte-code, use the ContractCode ledger entry key.
    /// See: https://soroban.stellar.org/api/methods/getLedgerEntries
    public func getLedgerEntries(base64EncodedKeys: [String]) async -> GetLedgerEntriesResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getLedgerEntries", args: ["keys" : base64EncodedKeys]))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(GetLedgerEntriesResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// For finding out the current latest known ledger of this node. This is a subset of the ledger info from Horizon.
    /// See: https://soroban.stellar.org/api/methods/getLatestLedger
    @available(*, renamed: "getLatestLedger()")
    public func getLatestLedger(completion:@escaping GetLatestLedgerResponseClosure) {
        Task {
            let result = await getLatestLedger()
            completion(result)
        }
    }
    
    /// For finding out the current latest known ledger of this node. This is a subset of the ledger info from Horizon.
    /// See: https://soroban.stellar.org/api/methods/getLatestLedger
    public func getLatestLedger() async -> GetLatestLedgerResponseEnum {

        let result = await request(body: try? buildRequestJson(method: "getLatestLedger"))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let response = try self.jsonDecoder.decode(GetLatestLedgerResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: response)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }

    /// Retrieve a list of ledgers starting from the specified starting point.
    /// The getLedgers method return a detailed list of ledgers starting from
    /// the user specified starting point that you can paginate as long as the pages
    /// fall within the history retention of their corresponding RPC provider.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "getLedgers(startLedger:paginationOptions:format:)")
    public func getLedgers(startLedger: UInt32, paginationOptions: PaginationOptions? = nil, format: String? = nil, completion: @escaping GetLedgersResponseClosure) {
        Task {
            let result = await getLedgers(startLedger: startLedger, paginationOptions: paginationOptions, format: format)
            completion(result)
        }
    }

    /// Retrieve a list of ledgers starting from the specified starting point.
    /// The getLedgers method return a detailed list of ledgers starting from
    /// the user specified starting point that you can paginate as long as the pages
    /// fall within the history retention of their corresponding RPC provider.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    public func getLedgers(startLedger: UInt32, paginationOptions: PaginationOptions? = nil, format: String? = nil) async -> GetLedgersResponseEnum {

        let result = await request(body: try? buildRequestJson(method: "getLedgers", args: buildLedgersRequestParams(startLedger: startLedger, paginationOptions: paginationOptions, format: format)))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(GetLedgersResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// loads the contract code (wasm binary) for the given wasmId
    @available(*, renamed: "getContractCodeForWasmId(wasmId:)")
    public func getContractCodeForWasmId(wasmId: String, completion:@escaping GetContractCodeResponseClosure) {
        Task {
            let result = await getContractCodeForWasmId(wasmId: wasmId)
            completion(result)
        }
    }
    
    /// loads the contract code (wasm binary) for the given wasmId
    public func getContractCodeForWasmId(wasmId: String) async -> GetContractCodeResponseEnum {
        let contractCodeKey = LedgerKeyContractCodeXDR(wasmId: wasmId)
        let ledgerKey = LedgerKeyXDR.contractCode(contractCodeKey)
        if let ledgerKeyBase64 = ledgerKey.xdrEncoded {
            let response = await self.getLedgerEntries(base64EncodedKeys: [ledgerKeyBase64])
            switch response {
            case .success(let response):
                let data = try? LedgerEntryDataXDR(fromBase64: response.entries[0].xdr)
                if let contractCode = data?.contractCode {
                    return .success(response: contractCode)
                }
                else {
                    return .failure(error: .requestFailed(message: "could not extract code"))
                }
            case .failure(let error):
                return .failure(error: error)
            }
        } else {
            return .failure(error: .requestFailed(message: "could not create ledger key"))
        }
    }
    
    /// loads the contract code (wasm binary) for the given contractId
    @available(*, renamed: "getContractCodeForContractId(contractId:)")
    public func getContractCodeForContractId(contractId: String, completion:@escaping GetContractCodeResponseClosure) {
        Task {
            let result = await getContractCodeForContractId(contractId: contractId)
            completion(result)
        }
    }
    
    /// loads the contract code (wasm binary) for the given contractId
    public func getContractCodeForContractId(contractId: String) async -> GetContractCodeResponseEnum {
        var contractDataKey:LedgerKeyContractDataXDR? = nil
        do {
            contractDataKey = LedgerKeyContractDataXDR(contract: try SCAddressXDR.init(contractId: contractId),
                                                           key: SCValXDR.ledgerKeyContractInstance,
                                                           durability: ContractDataDurability.persistent)
        } catch {
            return .failure(error: .requestFailed(message: "invalid contract id"))
        }
        
        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey!)
        if let ledgerKeyBase64 = ledgerKey.xdrEncoded {
            let response = await self.getLedgerEntries(base64EncodedKeys: [ledgerKeyBase64])
            switch response {
            case .success(let response):
                guard let firstEntry = response.entries.first else {
                    return .failure(error: .requestFailed(message: "could not extract wasm id"))
                }
                let data = try? LedgerEntryDataXDR(fromBase64: firstEntry.xdr)
                if let contractData = data?.contractData, let wasmId = contractData.val.contractInstance?.executable.wasm?.wrapped.hexEncodedString() {
                    let response = await self.getContractCodeForWasmId(wasmId: wasmId)
                    switch response {
                    case .success(let response):
                        return .success(response: response)
                    case .failure(let error):
                        return .failure(error: error)
                    }
                }
                else {
                    return .failure(error: .requestFailed(message: "could not extract wasm id"))
                }
            case .failure(let error):
                return .failure(error: error)
            }
        } else {
            return .failure(error: .requestFailed(message: "could not create ledger key"))
        }
    }
    
    /// Loads contract source byte code for the given contractId and extracts
    /// the information (Environment Meta, Contract Spec, Contract Meta).
    @available(*, renamed: "getContractInfoForContractId(contractId:)")
    public func getContractInfoForContractId(contractId: String, completion:@escaping GetContractInfoClosure) {
        Task {
            let result = await getContractInfoForContractId(contractId: contractId)
            completion(result)
        }
    }
    
    /// Loads contract source byte code for the given contractId and extracts
    /// the information (Environment Meta, Contract Spec, Contract Meta).
    public func getContractInfoForContractId(contractId: String) async -> GetContractInfoEnum {
        let response = await getContractCodeForContractId(contractId: contractId)
        switch response {
        case .success(let response):
            do {
                let info = try SorobanContractParser.parseContractByteCode(byteCode: response.code)
                return .success(response: info)
            } catch let error as SorobanContractParserError {
                return .parsingFailure(error: error)
            } catch {
                return .parsingFailure(error: SorobanContractParserError.invalidByteCode)
            }
        case .failure(let error):
            return .rpcFailure(error: error)
        }
    }
    
    /// Loads contract source byte code for the given wasm id and extracts
    /// the information (Environment Meta, Contract Spec, Contract Meta).
    @available(*, renamed: "getContractInfoForWasmId(wasmId:)")
    public func getContractInfoForWasmId(wasmId: String, completion:@escaping GetContractInfoClosure) {
        Task {
            let result = await getContractInfoForWasmId(wasmId: wasmId)
            completion(result)
        }
    }
    
    /// Loads contract source byte code for the given wasm id and extracts
    /// the information (Environment Meta, Contract Spec, Contract Meta).
    public func getContractInfoForWasmId(wasmId: String) async -> GetContractInfoEnum {
        let response = await getContractCodeForWasmId(wasmId: wasmId)
        switch response {
        case .success(let response):
            do {
                let info = try SorobanContractParser.parseContractByteCode(byteCode: response.code)
                return .success(response: info)
            } catch let error as SorobanContractParserError {
                return .parsingFailure(error: error)
            } catch {
                return .parsingFailure(error: SorobanContractParserError.invalidByteCode)
            }
        case .failure(let error):
            return .rpcFailure(error: error)
        }
    }
    
    /// Fetches a minimal set of current info about a Stellar account. Needed to get the current sequence
    /// number for the account, so you can build a successful transaction. Fails if the account was not found or accountiId is invalid
    @available(*, renamed: "getAccount(accountId:)")
    public func getAccount(accountId:String, completion:@escaping GetAccountResponseClosure) {
        Task {
            let result = await getAccount(accountId: accountId)
            completion(result)
        }
    }
    
    /// Fetches a minimal set of current info about a Stellar account. Needed to get the current sequence
    /// number for the account, so you can build a successful transaction. Fails if the account was not found or accountiId is invalid
    public func getAccount(accountId:String) async -> GetAccountResponseEnum {
        if let publicKey = try? PublicKey(accountId: accountId) {
            let accountKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: publicKey))
            if let ledgerKeyBase64 = accountKey.xdrEncoded {
                let response = await self.getLedgerEntries(base64EncodedKeys: [ledgerKeyBase64])
                switch response {
                case .success(let response):
                    var data:LedgerEntryDataXDR?
                    if let firstEntry = response.entries.first {
                        data = try? LedgerEntryDataXDR(fromBase64: firstEntry.xdr)
                    }
                    if let accountData = data?.account {
                        let account = Account(keyPair: KeyPair(publicKey: accountData.accountID), sequenceNumber: accountData.sequenceNumber);
                        return .success(response: account)
                    }
                    else {
                        return .failure(error: .requestFailed(message: "could not find account"))
                    }
                case .failure(let error):
                    return .failure(error: error)
                }
            } else {
                return .failure(error: .requestFailed(message: "could not create ledger key"))
            }
        } else {
            return .failure(error: .requestFailed(message: "invalid accountId"))
        }
    }
    
    /// Reads the current value of contract data ledger entries directly.
    @available(*, renamed: "getContractData(contractId:key:durability:)")
    public func getContractData(contractId: String, key: SCValXDR, durability: ContractDataDurability, completion:@escaping GetContractDataResponseClosure) {
        Task {
            let result = await getContractData(contractId: contractId, key: key, durability: durability)
            completion(result)
        }
    }
    
    /// Reads the current value of contract data ledger entries directly.
    public func getContractData(contractId: String, key: SCValXDR, durability: ContractDataDurability) async -> GetContractDataResponseEnum {
        if let contractAddress = try? SCAddressXDR.init(contractId: contractId) {
            let contractDataKey = LedgerKeyContractDataXDR(contract: contractAddress, key: key, durability: durability)
            let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
            if let ledgerKeyBase64 = ledgerKey.xdrEncoded {
                let response = await self.getLedgerEntries(base64EncodedKeys: [ledgerKeyBase64])
                switch response {
                case .success(let response):
                    if let result = response.entries.first {
                        return .success(response: result)
                    }
                    else {
                        return .failure(error: .requestFailed(message: "could not find contract data"))
                    }
                case .failure(let error):
                    return .failure(error: error)
                }
            } else {
                return .failure(error: .requestFailed(message: "could not create ledger key"))
            }
        } else {
            return .failure(error: .requestFailed(message: "invalid contractId"))
        }
    }
    
    /// Simulates a contract invocation without submitting to the network.
    ///
    /// Transaction simulation is essential for Soroban contract interactions. It provides:
    /// - Return values from read-only contract calls
    /// - Resource consumption estimates (CPU instructions, memory, ledger I/O)
    /// - Required ledger footprint for the transaction
    /// - Authorization requirements for multi-party transactions
    ///
    /// Always simulate before submitting write transactions to ensure they will succeed
    /// and to obtain the correct resource limits and footprint.
    ///
    /// - Parameter simulateTxRequest: The simulation request containing the transaction to simulate
    /// - Parameter completion: Callback with simulation results or error
    ///
    /// Example:
    /// ```swift
    /// let request = SimulateTransactionRequest(transaction: transaction)
    /// server.simulateTransaction(simulateTxRequest: request) { response in
    ///     switch response {
    ///     case .success(let simulation):
    ///         if let result = simulation.results?.first {
    ///             print("Contract returned: \(result.returnValue)")
    ///         }
    ///         print("Cost: \(simulation.cost)")
    ///     case .failure(let error):
    ///         print("Simulation error: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "simulateTransaction(simulateTxRequest:)")
    public func simulateTransaction(simulateTxRequest: SimulateTransactionRequest, completion:@escaping SimulateTransactionResponseClosure) {
        Task {
            let result = await simulateTransaction(simulateTxRequest: simulateTxRequest)
            completion(result)
        }
    }

    /// Simulates a contract invocation without submitting to the network.
    ///
    /// Transaction simulation is essential for Soroban contract interactions. It provides:
    /// - Return values from read-only contract calls
    /// - Resource consumption estimates (CPU instructions, memory, ledger I/O)
    /// - Required ledger footprint for the transaction
    /// - Authorization requirements for multi-party transactions
    ///
    /// Always simulate before submitting write transactions to ensure they will succeed
    /// and to obtain the correct resource limits and footprint.
    ///
    /// - Parameter simulateTxRequest: The simulation request containing the transaction to simulate
    /// - Returns: SimulateTransactionResponseEnum with simulation results or error
    ///
    /// Example:
    /// ```swift
    /// let request = SimulateTransactionRequest(transaction: transaction)
    /// let response = await server.simulateTransaction(simulateTxRequest: request)
    /// switch response {
    /// case .success(let simulation):
    ///     if let result = simulation.results?.first {
    ///         print("Contract returned: \(result.returnValue)")
    ///     }
    ///     print("Cost: \(simulation.cost)")
    /// case .failure(let error):
    ///     print("Simulation error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    public func simulateTransaction(simulateTxRequest: SimulateTransactionRequest) async -> SimulateTransactionResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "simulateTransaction", args: simulateTxRequest.buildRequestParams()))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(SimulateTransactionResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Submits a transaction to the Stellar network for execution.
    ///
    /// This is the only way to make on-chain changes with smart contracts. Before calling this:
    /// 1. Simulate the transaction with simulateTransaction
    /// 2. Add the resource limits and footprint from simulation
    /// 3. Sign the transaction with all required signers
    ///
    /// Important: Unlike Horizon, this method does not wait for transaction completion.
    /// It validates and enqueues the transaction, then returns immediately. Use getTransaction
    /// to poll for completion status.
    ///
    /// - Parameter transaction: The signed transaction to submit
    /// - Parameter completion: Callback with submission result or error
    ///
    /// Example:
    /// ```swift
    /// // After simulation and signing
    /// server.sendTransaction(transaction: signedTransaction) { response in
    ///     switch response {
    ///     case .success(let result):
    ///         print("Transaction hash: \(result.hash)")
    ///         print("Status: \(result.status)")
    ///         // Poll for completion
    ///     case .failure(let error):
    ///         print("Submission failed: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    /// - getTransaction(transactionHash:) for status polling
    @available(*, renamed: "sendTransaction(transaction:)")
    public func sendTransaction(transaction: Transaction, completion:@escaping SendTransactionResponseClosure) {
        Task {
            let result = await sendTransaction(transaction: transaction)
            completion(result)
        }
    }

    /// Submits a transaction to the Stellar network for execution.
    ///
    /// This is the only way to make on-chain changes with smart contracts. Before calling this:
    /// 1. Simulate the transaction with simulateTransaction
    /// 2. Add the resource limits and footprint from simulation
    /// 3. Sign the transaction with all required signers
    ///
    /// Important: Unlike Horizon, this method does not wait for transaction completion.
    /// It validates and enqueues the transaction, then returns immediately. Use getTransaction
    /// to poll for completion status.
    ///
    /// - Parameter transaction: The signed transaction to submit
    /// - Returns: SendTransactionResponseEnum with submission result or error
    ///
    /// Example:
    /// ```swift
    /// // After simulation and signing
    /// let response = await server.sendTransaction(transaction: signedTransaction)
    /// switch response {
    /// case .success(let result):
    ///     print("Transaction hash: \(result.hash)")
    ///     print("Status: \(result.status)")
    ///     // Poll for completion
    /// case .failure(let error):
    ///     print("Submission failed: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    /// - getTransaction(transactionHash:) for status polling
    public func sendTransaction(transaction: Transaction) async -> SendTransactionResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "sendTransaction", args: ["transaction": transaction.encodedEnvelope()]))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(SendTransactionResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Polls for transaction completion status.
    ///
    /// After submitting a transaction with sendTransaction, use this method to check
    /// if the transaction has been included in a ledger and whether it succeeded or failed.
    ///
    /// Transaction lifecycle:
    /// 1. PENDING: Transaction received but not yet in a ledger
    /// 2. SUCCESS: Transaction successfully executed
    /// 3. FAILED: Transaction failed during execution
    /// 4. NOT_FOUND: Transaction not found (may have expired)
    ///
    /// Poll this endpoint until status is SUCCESS or FAILED. Typical polling interval is 1-2 seconds.
    ///
    /// - Parameter transactionHash: The transaction hash returned from sendTransaction
    /// - Parameter completion: Callback with transaction status or error
    ///
    /// Example:
    /// ```swift
    /// func pollTransaction(hash: String) {
    ///     server.getTransaction(transactionHash: hash) { response in
    ///         switch response {
    ///         case .success(let txInfo):
    ///             switch txInfo.status {
    ///             case GetTransactionResponse.STATUS_SUCCESS:
    ///                 print("Transaction succeeded!")
    ///                 if let result = txInfo.resultValue {
    ///                     print("Return value: \(result)")
    ///                 }
    ///             case GetTransactionResponse.STATUS_FAILED:
    ///                 print("Transaction failed: \(txInfo.resultXdr ?? "")")
    ///             default:
    ///                 // Still pending, poll again
    ///                 DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    ///                     pollTransaction(hash: hash)
    ///                 }
    ///             }
    ///         case .failure(let error):
    ///             print("Error: \(error)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "getTransaction(transactionHash:)")
    public func getTransaction(transactionHash:String, completion:@escaping GetTransactionResponseClosure) {
        Task {
            let result = await getTransaction(transactionHash: transactionHash)
            completion(result)
        }
    }

    /// Polls for transaction completion status.
    ///
    /// After submitting a transaction with sendTransaction, use this method to check
    /// if the transaction has been included in a ledger and whether it succeeded or failed.
    ///
    /// Transaction lifecycle:
    /// 1. PENDING: Transaction received but not yet in a ledger
    /// 2. SUCCESS: Transaction successfully executed
    /// 3. FAILED: Transaction failed during execution
    /// 4. NOT_FOUND: Transaction not found (may have expired)
    ///
    /// Poll this endpoint until status is SUCCESS or FAILED. Typical polling interval is 1-2 seconds.
    ///
    /// - Parameter transactionHash: The transaction hash returned from sendTransaction
    /// - Returns: GetTransactionResponseEnum with transaction status or error
    ///
    /// Example:
    /// ```swift
    /// let response = await server.getTransaction(transactionHash: hash)
    /// switch response {
    /// case .success(let txInfo):
    ///     switch txInfo.status {
    ///     case GetTransactionResponse.STATUS_SUCCESS:
    ///         print("Transaction succeeded!")
    ///         if let result = txInfo.resultValue {
    ///             print("Return value: \(result)")
    ///         }
    ///     case GetTransactionResponse.STATUS_FAILED:
    ///         print("Transaction failed: \(txInfo.resultXdr ?? "")")
    ///     default:
    ///         print("Still pending...")
    ///     }
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    public func getTransaction(transactionHash:String) async -> GetTransactionResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getTransaction", args: ["hash": transactionHash]))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(GetTransactionResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// The getTransactions method return a detailed list of transactions starting from
    /// the user specified starting point that you can paginate as long as the pages
    /// fall within the history retention of their corresponding RPC provider.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "getTransactions(startLedger:paginationOptions:)")
    public func getTransactions(startLedger:Int? = nil, paginationOptions:PaginationOptions? = nil, completion:@escaping GetTransactionsResponseClosure) {
        Task {
            let result = await getTransactions(startLedger: startLedger, paginationOptions: paginationOptions)
            completion(result)
        }
    }
    
    /// The getTransactions method return a detailed list of transactions starting from
    /// the user specified starting point that you can paginate as long as the pages
    /// fall within the history retention of their corresponding RPC provider.
    /// See: [Stellar developer docs](https://developers.stellar.org)
    public func getTransactions(startLedger:Int? = nil, paginationOptions:PaginationOptions? = nil) async -> GetTransactionsResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getTransactions", args: buildTransactionssRequestParams(startLedger: startLedger, paginationOptions: paginationOptions)))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(GetTransactionsResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Queries contract events emitted within a specified ledger range.
    ///
    /// Contract events provide a way for smart contracts to emit structured data that can be
    /// queried by off-chain applications. Use this method to:
    /// - Monitor contract state changes
    /// - Track token transfers in custom assets
    /// - Build event-driven applications
    /// - Populate application databases with on-chain data
    ///
    /// Important notes:
    /// - By default, Soroban RPC retains only the most recent 24 hours of events
    /// - Deduplicate events by their unique ID to prevent double-processing
    /// - Use filters to narrow results to specific contracts or event types
    ///
    /// - Parameter startLedger: Starting ledger sequence number (optional)
    /// - Parameter endLedger: Ending ledger sequence number (optional)
    /// - Parameter eventFilters: Filters to narrow event results by contract ID or topics
    /// - Parameter paginationOptions: Pagination settings for large result sets
    /// - Parameter completion: Callback with events or error
    ///
    /// Example:
    /// ```swift
    /// // Query all events from a specific contract
    /// let filter = EventFilter(
    ///     type: "contract",
    ///     contractIds: ["CCONTRACT123..."]
    /// )
    /// server.getEvents(
    ///     startLedger: 1000000,
    ///     eventFilters: [filter],
    ///     paginationOptions: PaginationOptions(limit: 100)
    /// ) { response in
    ///     switch response {
    ///     case .success(let eventsResponse):
    ///         for event in eventsResponse.events {
    ///             print("Event ID: \(event.id)")
    ///             print("Topics: \(event.topic)")
    ///             print("Value: \(event.value)")
    ///         }
    ///     case .failure(let error):
    ///         print("Error: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    /// - [Stellar developer docs](https://developers.stellar.org)
    @available(*, renamed: "getEvents(startLedger:eventFilters:paginationOptions:)")
    public func getEvents(startLedger:Int? = nil, endLedger:Int? = nil, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil, completion:@escaping GetEventsResponseClosure) {
        Task {
            let result = await getEvents(startLedger: startLedger, endLedger: endLedger, eventFilters: eventFilters, paginationOptions: paginationOptions)
            completion(result)
        }
    }

    /// Queries contract events emitted within a specified ledger range.
    ///
    /// Contract events provide a way for smart contracts to emit structured data that can be
    /// queried by off-chain applications. Use this method to:
    /// - Monitor contract state changes
    /// - Track token transfers in custom assets
    /// - Build event-driven applications
    /// - Populate application databases with on-chain data
    ///
    /// Important notes:
    /// - By default, Soroban RPC retains only the most recent 24 hours of events
    /// - Deduplicate events by their unique ID to prevent double-processing
    /// - Use filters to narrow results to specific contracts or event types
    ///
    /// - Parameter startLedger: Starting ledger sequence number (optional)
    /// - Parameter endLedger: Ending ledger sequence number (optional)
    /// - Parameter eventFilters: Filters to narrow event results by contract ID or topics
    /// - Parameter paginationOptions: Pagination settings for large result sets
    /// - Returns: GetEventsResponseEnum with events or error
    ///
    /// Example:
    /// ```swift
    /// // Query all events from a specific contract
    /// let filter = EventFilter(
    ///     type: "contract",
    ///     contractIds: ["CCONTRACT123..."]
    /// )
    /// let response = await server.getEvents(
    ///     startLedger: 1000000,
    ///     eventFilters: [filter],
    ///     paginationOptions: PaginationOptions(limit: 100)
    /// )
    /// switch response {
    /// case .success(let eventsResponse):
    ///     for event in eventsResponse.events {
    ///         print("Event ID: \(event.id)")
    ///         print("Topics: \(event.topic)")
    ///         print("Value: \(event.value)")
    ///     }
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    /// - [Stellar developer docs](https://developers.stellar.org)
    public func getEvents(startLedger:Int? = nil, endLedger:Int? = nil, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil) async -> GetEventsResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getEvents", args: buildEventsRequestParams(startLedger: startLedger, endLedger: endLedger, eventFilters: eventFilters, paginationOptions: paginationOptions)))
        switch result {
        case .success(let data):
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let result = response["result"] as? [String: Any] {
                    do {
                        let decoded = try self.jsonDecoder.decode(GetEventsResponse.self, from: JSONSerialization.data(withJSONObject: result))
                        return .success(response: decoded)
                    } catch {
                        return .failure(error: .parsingResponseFailed(message: error.localizedDescription, responseData: data))
                    }
                } else if let error = response["error"] as? [String: Any] {
                    return .failure(error: .errorResponse(errorData: error))
                } else {
                    return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
                }
            } else {
                return .failure(error: .parsingResponseFailed(message: "Invalid JSON", responseData: data))
            }
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    /// Constructs request parameters for the getEvents RPC call.
    /// Assembles ledger range, event filters, and pagination settings into a parameter dictionary.
    private func buildEventsRequestParams(startLedger:Int? = nil, endLedger:Int?=nil, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil) -> [String : Any] {
        var result: [String : Any] = [:]
        
        if (startLedger != nil) {
            result["startLedger"] = startLedger
        }
        
        if (endLedger != nil) {
            result["endLedger"] = endLedger
        }
        
        // filters
        if let eventFilters = eventFilters, !eventFilters.isEmpty {
            var arr:[[String : Any]] = []
            for event in eventFilters {
                arr.append(event.buildRequestParams())
            }
            result["filters"] = arr
        }

        // pagination options
        if let paginationOptions = paginationOptions {
            result["pagination"] = paginationOptions.buildRequestParams()
        }
        return result;
    }
    
    /// Constructs request parameters for the getTransactions RPC call.
    /// Combines starting ledger and pagination options into the RPC request parameter dictionary.
    private func buildTransactionssRequestParams(startLedger:Int? = nil, paginationOptions:PaginationOptions? = nil) -> [String : Any] {
        var result: [String : Any] = [:]

        if (startLedger != nil) {
            result["startLedger"] = startLedger
        }

        // pagination options
        if let paginationOptions = paginationOptions {
            result["pagination"] = paginationOptions.buildRequestParams()
        }

        return result;
    }

    /// Constructs request parameters for the getLedgers RPC call.
    /// Assembles starting ledger, XDR format preference, and pagination settings into the request parameter dictionary.
    private func buildLedgersRequestParams(startLedger: UInt32, paginationOptions: PaginationOptions? = nil, format: String? = nil) -> [String : Any] {
        var result: [String : Any] = [:]

        result["startLedger"] = startLedger

        // format (xdrFormat parameter)
        if let format = format {
            result["xdrFormat"] = format
        }

        // pagination options
        if let paginationOptions = paginationOptions {
            result["pagination"] = paginationOptions.buildRequestParams()
        }

        return result
    }
    
    /// Builds a JSON-RPC 2.0 request body for Soroban RPC calls.
    /// Constructs the standard JSON-RPC envelope with method name, parameters, and unique request ID.
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
    
    
    /// Legacy callback-based HTTP request wrapper for Soroban RPC calls.
    /// Deprecated in favor of async/await variant. Forwards to async implementation.
    @available(*, renamed: "request(body:)")
    private func request(body: Data?, completion: @escaping RpcResponseClosure) {
        Task {
            let result = await request(body: body)
            completion(result)
        }
    }
    
    /// Executes HTTP POST request to Soroban RPC endpoint with JSON-RPC 2.0 protocol.
    /// Handles request headers, response validation, and error mapping for all RPC operations.
    private func request(body: Data?) async -> RpcResult {
        let url = URL(string: endpoint)!
        var urlRequest = URLRequest(url: url)

        requestHeaders.forEach {
            urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)
        }
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        urlRequest.httpMethod = "POST"
        if let body = body {
            urlRequest.httpBody = body
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if enableLogging {
                let log = String(decoding: data, as: UTF8.self)
                print(log)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(error: .requestFailed(message: "Invalid response"))
            }

            var message: String!
            message = String(data: data, encoding: String.Encoding.utf8)
            if message == nil {
                message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }

            switch httpResponse.statusCode {
            case 200, 201, 202:
                return .success(data: data)
            default:
                return .failure(error: .requestFailed(message: message))
            }
        } catch {
            return .failure(error: .requestFailed(message: error.localizedDescription))
        }
    }
}
