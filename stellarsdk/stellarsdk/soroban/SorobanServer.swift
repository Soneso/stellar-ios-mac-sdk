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

public enum GetFeeStatsResponseEnum {
    case success(response: GetFeeStatsResponse)
    case failure(error: SorobanRpcRequestError)
}

public enum GetVersionInfoResponseEnum {
    case success(response: GetVersionInfoResponse)
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

public enum GetTransactionsResponseEnum {
    case success(response: GetTransactionsResponse)
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

public enum GetContractInfoEnum {
    case success(response: SorobanContractInfo)
    case parsingFailure(error: SorobanContractParserError)
    case rpcFailure(error: SorobanRpcRequestError)
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
public typealias GetFeeStatsResponseClosure = (_ response:GetFeeStatsResponseEnum) -> (Void)
public typealias GetVersionInfoResponseClosure = (_ response:GetVersionInfoResponseEnum) -> (Void)
public typealias GetLedgerEntriesResponseClosure = (_ response:GetLedgerEntriesResponseEnum) -> (Void)
public typealias GetLatestLedgerResponseClosure = (_ response:GetLatestLedgerResponseEnum) -> (Void)
public typealias SimulateTransactionResponseClosure = (_ response:SimulateTransactionResponseEnum) -> (Void)
public typealias SendTransactionResponseClosure = (_ response:SendTransactionResponseEnum) -> (Void)
public typealias GetTransactionResponseClosure = (_ response:GetTransactionResponseEnum) -> (Void)
public typealias GetTransactionsResponseClosure = (_ response:GetTransactionsResponseEnum) -> (Void)
public typealias GetEventsResponseClosure = (_ response:GetEventsResponseEnum) -> (Void)
public typealias GetNonceResponseClosure = (_ response:GetNonceResponseEnum) -> (Void)
public typealias GetContractCodeResponseClosure = (_ response:GetContractCodeResponseEnum) -> (Void)
public typealias GetContractInfoClosure = (_ response:GetContractInfoEnum) -> (Void)
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
    /// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getFeeStats
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
    /// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getFeeStats
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
    /// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getVersionInfo
    @available(*, renamed: "getVersionInfo()")
    public func getVersionInfo(completion:@escaping GetVersionInfoResponseClosure) {
        Task {
            let result = await getVersionInfo()
            completion(result)
        }
    }
    
    /// Version information about the RPC and Captive core. RPC manages its own,
    /// pared-down version of Stellar Core optimized for its own subset of needs.
    /// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getVersionInfo
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
                if (response.entries.isEmpty) {
                    return .failure(error: .requestFailed(message: "could not extract wasm id"))
                }
                let data = try? LedgerEntryDataXDR(fromBase64: response.entries.first!.xdr)
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
                    if (response.entries.count > 0) {
                        data = try? LedgerEntryDataXDR(fromBase64: response.entries.first!.xdr)
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
    
    /// Submit a trial contract invocation to get back return values, expected ledger footprint, and expected costs.
    /// See: https://soroban.stellar.org/api/methods/simulateTransaction
    @available(*, renamed: "simulateTransaction(simulateTxRequest:)")
    public func simulateTransaction(simulateTxRequest: SimulateTransactionRequest, completion:@escaping SimulateTransactionResponseClosure) {
        Task {
            let result = await simulateTransaction(simulateTxRequest: simulateTxRequest)
            completion(result)
        }
    }
    
    /// Submit a trial contract invocation to get back return values, expected ledger footprint, and expected costs.
    /// See: https://soroban.stellar.org/api/methods/simulateTransaction
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
    
    /// Submit a real transaction to the stellar network. This is the only way to make changes “on-chain”.
    /// Unlike Horizon, this does not wait for transaction completion. It simply validates and enqueues the transaction.
    /// Clients should call getTransactionStatus to learn about transaction success/failure.
    /// See: https://soroban.stellar.org/api/methods/sendTransaction
    @available(*, renamed: "sendTransaction(transaction:)")
    public func sendTransaction(transaction: Transaction, completion:@escaping SendTransactionResponseClosure) {
        Task {
            let result = await sendTransaction(transaction: transaction)
            completion(result)
        }
    }
    
    /// Submit a real transaction to the stellar network. This is the only way to make changes “on-chain”.
    /// Unlike Horizon, this does not wait for transaction completion. It simply validates and enqueues the transaction.
    /// Clients should call getTransactionStatus to learn about transaction success/failure.
    /// See: https://soroban.stellar.org/api/methods/sendTransaction
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
    
    /// Clients will poll this to tell when the transaction has been completed.
    /// See: https://soroban.stellar.org/api/methods/getTransaction
    @available(*, renamed: "getTransaction(transactionHash:)")
    public func getTransaction(transactionHash:String, completion:@escaping GetTransactionResponseClosure) {
        Task {
            let result = await getTransaction(transactionHash: transactionHash)
            completion(result)
        }
    }
    
    /// Clients will poll this to tell when the transaction has been completed.
    /// See: https://soroban.stellar.org/api/methods/getTransaction
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
    /// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getTransactions
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
    /// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getTransactions
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
    
    /// Clients can request a filtered list of events emitted by a given ledger range.
    /// Soroban-RPC will support querying within a maximum 24 hours of recent ledgers.
    /// Note, this could be used by the client to only prompt a refresh when there is a new ledger with relevant events. It should also be used by backend Dapp components to "ingest" events into their own database for querying and serving.
    /// If making multiple requests, clients should deduplicate any events received, based on the event's unique id field. This prevents double-processing in the case of duplicate events being received.
    /// By default soroban-rpc retains the most recent 24 hours of events.
    /// See: https://soroban.stellar.org/api/methods/getEvents
    @available(*, renamed: "getEvents(startLedger:eventFilters:paginationOptions:)")
    public func getEvents(startLedger:Int? = nil, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil, completion:@escaping GetEventsResponseClosure) {
        Task {
            let result = await getEvents(startLedger: startLedger, eventFilters: eventFilters, paginationOptions: paginationOptions)
            completion(result)
        }
    }
    
    /// Clients can request a filtered list of events emitted by a given ledger range.
    /// Soroban-RPC will support querying within a maximum 24 hours of recent ledgers.
    /// Note, this could be used by the client to only prompt a refresh when there is a new ledger with relevant events. It should also be used by backend Dapp components to "ingest" events into their own database for querying and serving.
    /// If making multiple requests, clients should deduplicate any events received, based on the event's unique id field. This prevents double-processing in the case of duplicate events being received.
    /// By default soroban-rpc retains the most recent 24 hours of events.
    /// See: https://soroban.stellar.org/api/methods/getEvents
    public func getEvents(startLedger:Int? = nil, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil) async -> GetEventsResponseEnum {
        
        let result = await request(body: try? buildRequestJson(method: "getEvents", args: buildEventsRequestParams(startLedger: startLedger, eventFilters: eventFilters, paginationOptions: paginationOptions)))
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
    
    private func buildEventsRequestParams(startLedger:Int? = nil, eventFilters: [EventFilter]? = nil, paginationOptions:PaginationOptions? = nil) -> [String : Any] {
        var result: [String : Any] = [:]
        
        if (startLedger != nil) {
            result["startLedger"] = startLedger
        }
        
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
            result["pagination"] = paginationOptions!.buildRequestParams()
        }
        return result;
    }
    
    private func buildTransactionssRequestParams(startLedger:Int? = nil, paginationOptions:PaginationOptions? = nil) -> [String : Any] {
        var result: [String : Any] = [:]
        
        if (startLedger != nil) {
            result["startLedger"] = startLedger
        }
        
        // pagination options
        if (paginationOptions != nil) {
            result["pagination"] = paginationOptions!.buildRequestParams()
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
    
    
    @available(*, renamed: "request(body:)")
    private func request(body: Data?, completion: @escaping RpcResponseClosure) {
        Task {
            let result = await request(body: body)
            completion(result)
        }
    }
    
    
    private func request(body: Data?) async -> RpcResult {
        
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
        
        return await withCheckedContinuation { continuation in
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.resume(returning: .failure(error:.requestFailed(message:error.localizedDescription)))
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
                        continuation.resume(returning: .failure(error:.requestFailed(message:message)))
                        return
                    }
                }
                if let data = data {
                    continuation.resume(returning: .success(data: data))
                } else {
                    continuation.resume(returning: .failure(error:.requestFailed(message:"empty response")))
                }
            }
            
            task.resume()
        }
    }
}
