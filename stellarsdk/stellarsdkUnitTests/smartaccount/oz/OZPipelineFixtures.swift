//
//  OZPipelineFixtures.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Reusable XDR fixture builders for the OZ smart-account pipeline tests.
//  Builds JSON-RPC envelopes (as `String` payloads ready to feed back to the
//  scriptable `MockSorobanServerScript`) carrying valid Base64-encoded XDR for
//  every shape the pipeline consumes: simulate / send / get-transaction /
//  get-account / get-contract-data / get-latest-ledger.
//
//  Each builder returns the JSON-RPC `result` payload as a Swift dictionary
//  the caller hands to the script via the existing setters. The XDR pieces are
//  produced with the SDK's own XDR types and serialised via `.xdrEncoded`, so
//  any change to the SDK's XDR encoding is reflected here without manual
//  byte-level edits.
//

import Foundation
@testable import stellarsdk

// ============================================================================
// OZPipelineFixtures
// ============================================================================

/// Reusable XDR fixture builders for the OZ smart-account pipeline tests.
///
/// Every builder returns either a Base64-encoded XDR string (for fields nested
/// inside a JSON-RPC payload) or a fully-formed `[String: Any]` dictionary
/// matching the JSON-RPC `result` payload that `SorobanServer` expects to
/// decode. Tests pass these dictionaries to the existing `MockSorobanServerScript`
/// setters (or extended setters added below) so the scripted-response transport
/// never has to construct XDR by hand at the call site.
enum OZPipelineFixtures {

    // ========================================================================
    // SorobanTransactionData / SorobanResources fixtures
    // ========================================================================

    /// Returns a minimal `SorobanTransactionDataXDR` Base64 string with empty
    /// footprint and zero resources. The pipeline only consumes
    /// `transactionData` as an opaque blob to attach to the rebuilt
    /// transaction; the network would reject it but the in-process pipeline
    /// never re-validates the contents.
    static func transactionDataBase64(resourceFee: Int64 = 0) -> String {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let resources = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 0,
            diskReadBytes: 0,
            writeBytes: 0
        )
        let data = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: resourceFee
        )
        return data.xdrEncoded ?? ""
    }

    // ========================================================================
    // SorobanAuthorizationEntry fixtures
    // ========================================================================

    /// Builds an `Address`-credentials authorization entry whose credential
    /// address is the supplied contract id, with a `void` placeholder
    /// signature and the supplied nonce / expiration.
    ///
    /// Matches what Soroban simulation returns for unsigned auth entries: the
    /// OZ AuthPayload codec accepts `void` as an empty payload.
    static func addressCredentialsAuthEntry(
        contractAddress: String,
        targetContract: String? = nil,
        targetFn: String = "noop",
        nonce: Int64 = 0,
        expirationLedger: UInt32 = 0
    ) throws -> SorobanAuthorizationEntryXDR {
        let target = targetContract ?? contractAddress
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: target),
            functionName: targetFn,
            args: []
        )
        let function = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: function,
            subInvocations: []
        )
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: contractAddress),
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )
    }

    /// Builds a `SourceAccount`-credentials authorization entry whose root
    /// invocation calls `targetFn` on `targetContract`.
    ///
    /// Used for `fundWallet` conversion tests and relayer Mode 2 routing
    /// tests.
    static func sourceAccountAuthEntry(
        targetContract: String,
        targetFn: String = "noop"
    ) throws -> SorobanAuthorizationEntryXDR {
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: targetContract),
            functionName: targetFn,
            args: []
        )
        let function = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: function,
            subInvocations: []
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
    }

    /// Returns the Base64 XDR of an authorization entry. Convenience wrapper
    /// over `XDREncodable.xdrEncoded`.
    static func authEntryBase64(_ entry: SorobanAuthorizationEntryXDR) -> String {
        return entry.xdrEncoded ?? ""
    }

    // ========================================================================
    // simulateTransaction JSON-RPC payload builders
    // ========================================================================

    /// Returns a successful `simulateTransaction` JSON-RPC `result` payload.
    ///
    /// - `latestLedger`: latest-ledger sequence reported alongside the result.
    /// - `minResourceFee`: optional resource-fee suggestion (UInt32 stringified
    ///   in the wire format).
    /// - `transactionData`: optional Base64 SorobanTransactionData; when nil
    ///   a fresh empty-footprint blob is generated.
    /// - `authEntries`: optional list of auth-entry XDR shapes that the
    ///   builder serialises to Base64.
    /// - `resultXdr`: optional Base64 ScVal returned as the host-function
    ///   result (defaults to a void ScVal so the pipeline can parse it).
    static func validSimulateTransactionResponse(
        latestLedger: Int = 1000,
        minResourceFee: UInt32? = 100_000,
        transactionData: String? = nil,
        authEntries: [SorobanAuthorizationEntryXDR] = [],
        resultXdr: String? = nil
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "latestLedger": NSNumber(value: latestLedger)
        ]
        if let minResourceFee = minResourceFee {
            payload["minResourceFee"] = String(minResourceFee)
        }
        let txData = transactionData ?? transactionDataBase64()
        if !txData.isEmpty {
            payload["transactionData"] = txData
        }
        let auth = authEntries.compactMap { $0.xdrEncoded }
        let resultEntry: [String: Any] = [
            "auth": auth,
            "xdr": resultXdr ?? voidScValBase64()
        ]
        payload["results"] = [resultEntry]
        return payload
    }

    /// Returns an `error`-bearing `simulateTransaction` JSON-RPC `result`
    /// payload. The pipeline lifts this into
    /// `SmartAccountTransactionException.SimulationFailed`.
    static func simulateErrorResponse(
        latestLedger: Int = 1000,
        message: String
    ) -> [String: Any] {
        return [
            "latestLedger": NSNumber(value: latestLedger),
            "error": message
        ]
    }

    // ========================================================================
    // sendTransaction JSON-RPC payload builders
    // ========================================================================

    /// Returns a `sendTransaction` JSON-RPC `result` payload.
    ///
    /// - `status`: one of `SendTransactionResponse.STATUS_*`.
    /// - `hash`: transaction hash assigned at submission time.
    /// - `errorResultXdr`: optional Base64 result XDR for failure paths.
    static func validSendTransactionResponse(
        status: String,
        hash: String,
        errorResultXdr: String? = nil,
        latestLedger: Int = 1000
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "hash": hash,
            "status": status,
            "latestLedger": NSNumber(value: latestLedger),
            "latestLedgerCloseTime": "0"
        ]
        if let xdr = errorResultXdr {
            payload["errorResultXdr"] = xdr
        }
        return payload
    }

    // ========================================================================
    // getTransaction JSON-RPC payload builders
    // ========================================================================

    /// Returns a `getTransaction` JSON-RPC `result` payload.
    ///
    /// - `status`: one of `GetTransactionResponse.STATUS_*`.
    /// - `ledger`: optional ledger sequence (present for SUCCESS and FAILED
    ///   statuses).
    /// - `envelopeXdr`: optional Base64 transaction envelope XDR.
    /// - `resultXdr`: optional Base64 transaction result XDR.
    /// - `resultMetaXdr`: optional Base64 transaction meta XDR.
    static func validGetTransactionResponse(
        status: String,
        ledger: Int? = nil,
        envelopeXdr: String? = nil,
        resultXdr: String? = nil,
        resultMetaXdr: String? = nil,
        latestLedger: Int = 1000
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "status": status,
            "latestLedger": NSNumber(value: latestLedger),
            "latestLedgerCloseTime": "0",
            "oldestLedger": NSNumber(value: max(0, latestLedger - 100)),
            "oldestLedgerCloseTime": "0"
        ]
        if let ledger = ledger {
            payload["ledger"] = NSNumber(value: ledger)
        }
        if let envelope = envelopeXdr {
            payload["envelopeXdr"] = envelope
        }
        if let result = resultXdr {
            payload["resultXdr"] = result
        }
        if let meta = resultMetaXdr {
            payload["resultMetaXdr"] = meta
        }
        return payload
    }

    // ========================================================================
    // getLatestLedger JSON-RPC payload builders
    // ========================================================================

    /// Returns a `getLatestLedger` JSON-RPC `result` payload.
    static func validGetLatestLedgerResponse(
        sequence: Int,
        id: String = "mock-ledger",
        protocolVersion: Int = 22
    ) -> [String: Any] {
        return [
            "id": id,
            "protocolVersion": NSNumber(value: protocolVersion),
            "sequence": NSNumber(value: sequence)
        ]
    }

    // ========================================================================
    // getLedgerEntries JSON-RPC payload builders (account / contract data)
    // ========================================================================

    /// Returns a `getLedgerEntries` JSON-RPC `result` payload carrying a
    /// single Account ledger entry for the supplied account id with the
    /// supplied sequence number.
    ///
    /// `SorobanServer.getAccount` consumes this shape: it parses the first
    /// entry's `xdr` field as `LedgerEntryDataXDR.account`, and constructs a
    /// `KeyPair` from `accountID` plus `sequenceNumber`.
    static func validGetAccountResponse(
        accountId: String,
        sequence: Int64,
        balance: Int64 = 100_000_000,
        latestLedger: Int = 1000,
        lastModifiedLedgerSeq: Int = 1000
    ) -> [String: Any]? {
        guard let publicKey = try? PublicKey(accountId: accountId) else {
            return nil
        }
        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: balance,
            sequenceNumber: sequence,
            numSubEntries: 0,
            inflationDest: nil,
            flags: 0,
            homeDomain: "",
            thresholds: WrappedData4(Data([0, 0, 0, 0])),
            signers: [],
            ext: .void
        )
        let entryData = LedgerEntryDataXDR.account(accountEntry)
        guard let xdrBase64 = entryData.xdrEncoded else {
            return nil
        }
        let key = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: publicKey))
        let keyBase64 = key.xdrEncoded ?? ""

        let entry: [String: Any] = [
            "key": keyBase64,
            "xdr": xdrBase64,
            "lastModifiedLedgerSeq": NSNumber(value: lastModifiedLedgerSeq)
        ]
        return [
            "latestLedger": NSNumber(value: latestLedger),
            "entries": [entry]
        ]
    }

    /// Returns a `getLedgerEntries` JSON-RPC `result` payload carrying a
    /// single ContractData ledger entry.
    ///
    /// Used by `connectWallet`'s end-of-cascade verify path: the SDK calls
    /// `getContractData` which underneath issues `getLedgerEntries` for the
    /// `LedgerKeyContractInstance` key.
    static func validGetContractDataResponse(
        contractId: String,
        keyXdr: SCValXDR? = nil,
        valueXdr: SCValXDR? = nil,
        durability: ContractDataDurability = .persistent,
        latestLedger: Int = 1000,
        lastModifiedLedgerSeq: Int = 1000
    ) throws -> [String: Any]? {
        let contractAddress = try SCAddressXDR(contractId: contractId)
        let key = keyXdr ?? .ledgerKeyContractInstance
        let value = valueXdr ?? .void

        let contractDataEntry = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: key,
            durability: durability,
            val: value
        )
        let entryData = LedgerEntryDataXDR.contractData(contractDataEntry)
        guard let xdrBase64 = entryData.xdrEncoded else {
            return nil
        }
        let ledgerKey = LedgerKeyXDR.contractData(
            LedgerKeyContractDataXDR(
                contract: contractAddress,
                key: key,
                durability: durability
            )
        )
        let keyBase64 = ledgerKey.xdrEncoded ?? ""

        let entry: [String: Any] = [
            "key": keyBase64,
            "xdr": xdrBase64,
            "lastModifiedLedgerSeq": NSNumber(value: lastModifiedLedgerSeq)
        ]
        return [
            "latestLedger": NSNumber(value: latestLedger),
            "entries": [entry]
        ]
    }

    /// Returns a `getLedgerEntries` JSON-RPC `result` payload with an empty
    /// `entries` array. Causes `getAccount` / `getContractData` to surface the
    /// "could not find" failure path the production code maps to typed
    /// exceptions.
    static func emptyGetLedgerEntriesResponse(latestLedger: Int = 1000) -> [String: Any] {
        return [
            "latestLedger": NSNumber(value: latestLedger),
            "entries": [[String: Any]]()
        ]
    }

    // ========================================================================
    // Internal helpers
    // ========================================================================

    /// Returns the Base64 XDR of `SCValXDR.void` — a stable placeholder for
    /// host-function result payloads in tests that do not exercise the result
    /// value.
    private static func voidScValBase64() -> String {
        return SCValXDR.void.xdrEncoded ?? ""
    }
}

// ============================================================================
// MockSorobanServerScript convenience extensions
// ============================================================================
//
// The base script (in `MockSorobanServer.swift`) provides primitive
// `enqueueSimulateSuccess`, `setSendSuccess`, etc. methods that build the
// JSON-RPC payload by hand. The extensions below thread the
// `OZPipelineFixtures` builders through those primitives so test cases can
// say `script.enqueueSimulate(authEntries: [...])` and have the entire
// XDR / JSON envelope generated for them.

extension MockSorobanServerScript {

    /// Enqueues a simulate-transaction success response built via the
    /// fixture library.
    ///
    /// - Parameters:
    ///   - authEntries: Auth-entry XDR shapes serialised into the response.
    ///   - minResourceFee: Optional resource-fee suggestion.
    ///   - latestLedger: Latest-ledger sequence reported alongside the result.
    ///   - transactionData: Optional Base64 SorobanTransactionData; defaults
    ///     to a fresh empty-footprint blob.
    ///   - resultXdr: Optional Base64 host-function result.
    func enqueueSimulate(
        authEntries: [SorobanAuthorizationEntryXDR] = [],
        minResourceFee: UInt32? = 100_000,
        latestLedger: Int = 1000,
        transactionData: String? = nil,
        resultXdr: String? = nil
    ) {
        let payload = OZPipelineFixtures.validSimulateTransactionResponse(
            latestLedger: latestLedger,
            minResourceFee: minResourceFee,
            transactionData: transactionData,
            authEntries: authEntries,
            resultXdr: resultXdr
        )
        ingestSimulateResponse(payload: payload)
    }

    /// Enqueues a `getTransaction` response built via the fixture library.
    func enqueueGetTransactionResponse(
        status: String,
        ledger: Int? = nil,
        envelopeXdr: String? = nil,
        resultXdr: String? = nil,
        resultMetaXdr: String? = nil,
        latestLedger: Int = 1000
    ) {
        let payload = OZPipelineFixtures.validGetTransactionResponse(
            status: status,
            ledger: ledger,
            envelopeXdr: envelopeXdr,
            resultXdr: resultXdr,
            resultMetaXdr: resultMetaXdr,
            latestLedger: latestLedger
        )
        ingestGetTransactionResponse(payload: payload)
    }

    /// Configures the deployer-account `getLedgerEntries` response so
    /// `getAccount(deployerAccountId)` succeeds with the supplied sequence
    /// number.
    func setGetAccountResponse(
        accountId: String,
        sequence: Int64,
        balance: Int64 = 100_000_000,
        latestLedger: Int = 1000
    ) {
        guard let payload = OZPipelineFixtures.validGetAccountResponse(
            accountId: accountId,
            sequence: sequence,
            balance: balance,
            latestLedger: latestLedger
        ) else {
            return
        }
        ingestGetLedgerEntriesResponse(payload: payload)
    }

    /// Configures a `getLedgerEntries` response for the supplied contract
    /// instance ledger entry. Used by `connectWallet`'s end-of-cascade verify.
    func setGetContractDataResponse(
        contractId: String,
        keyXdr: SCValXDR? = nil,
        valueXdr: SCValXDR? = nil,
        durability: ContractDataDurability = .persistent,
        latestLedger: Int = 1000
    ) throws {
        guard let payload = try OZPipelineFixtures.validGetContractDataResponse(
            contractId: contractId,
            keyXdr: keyXdr,
            valueXdr: valueXdr,
            durability: durability,
            latestLedger: latestLedger
        ) else {
            return
        }
        ingestGetLedgerEntriesResponse(payload: payload)
    }

    /// Configures an empty `getLedgerEntries` response.
    func setEmptyGetLedgerEntriesResponse(latestLedger: Int = 1000) {
        let payload = OZPipelineFixtures.emptyGetLedgerEntriesResponse(
            latestLedger: latestLedger
        )
        ingestGetLedgerEntriesResponse(payload: payload)
    }
}
