//
//  AssembledTransactionP27UnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 12.06.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for the Protocol-27 additions in SimulateTransactionRequest,
/// MethodOptions, and AssembledTransaction.
///
/// Tests assert behavior, not merely absence of throws.
final class AssembledTransactionP27UnitTests: XCTestCase {

    // MARK: - Shared fixtures

    var keyPair: KeyPair!
    var delegateKeyPair: KeyPair!
    var mockRpcUrl: String!
    var mockContractId: String!
    var clientOptions: ClientOptions!
    var network: Network!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        keyPair = try! KeyPair(secretSeed: "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF")
        delegateKeyPair = try! KeyPair.generateRandomKeyPair()
        mockRpcUrl = "https://soroban-testnet.stellar.org"
        mockContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        network = Network.testnet
        clientOptions = ClientOptions(
            sourceAccountKeyPair: keyPair,
            contractId: mockContractId,
            network: network,
            rpcUrl: mockRpcUrl
        )
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
        super.tearDown()
    }

    // MARK: - SimulateTransactionRequest useUpgradedAuth param tests

    /// useUpgradedAuth key must be absent when the default (false) is used.
    func testBuildRequestParams_useUpgradedAuthAbsentByDefault() throws {
        let tx = try makeMockTransaction()
        let request = SimulateTransactionRequest(transaction: tx)
        let params = request.buildRequestParams()
        XCTAssertNil(params["useUpgradedAuth"], "useUpgradedAuth key must be absent when not opted in")
    }

    /// useUpgradedAuth key must be absent when explicitly set to false.
    func testBuildRequestParams_useUpgradedAuthAbsentWhenExplicitlyFalse() throws {
        let tx = try makeMockTransaction()
        let request = SimulateTransactionRequest(transaction: tx, useUpgradedAuth: false)
        let params = request.buildRequestParams()
        XCTAssertNil(params["useUpgradedAuth"], "useUpgradedAuth key must be absent when explicitly false")
    }

    /// useUpgradedAuth key must be present as boolean true when opted in.
    func testBuildRequestParams_useUpgradedAuthPresentAsBooleanTrueWhenOptedIn() throws {
        let tx = try makeMockTransaction()
        let request = SimulateTransactionRequest(transaction: tx, useUpgradedAuth: true)
        let params = request.buildRequestParams()
        guard let val = params["useUpgradedAuth"] else {
            return XCTFail("useUpgradedAuth key must be present when opted in")
        }
        guard let boolVal = val as? Bool else {
            return XCTFail("useUpgradedAuth must be a Bool, got \(type(of: val))")
        }
        XCTAssertTrue(boolVal, "useUpgradedAuth value must be true")
    }

    /// Existing params (transaction, resourceConfig, authMode) are unaffected by useUpgradedAuth.
    func testBuildRequestParams_existingParamsUnaffected() throws {
        let tx = try makeMockTransaction()
        let resourceConfig = ResourceConfig(instructionLeeway: 3_000_000)
        let request = SimulateTransactionRequest(
            transaction: tx,
            resourceConfig: resourceConfig,
            authMode: "record",
            useUpgradedAuth: true
        )
        let params = request.buildRequestParams()
        XCTAssertNotNil(params["transaction"], "transaction key must be present")
        XCTAssertNotNil(params["resourceConfig"], "resourceConfig key must be present")
        XCTAssertEqual(params["authMode"] as? String, "record", "authMode must be preserved")
        XCTAssertTrue(params["useUpgradedAuth"] as? Bool == true, "useUpgradedAuth must be present")
    }

    // MARK: - MethodOptions useUpgradedAuth opt-in

    func testMethodOptions_useUpgradedAuthDefaultFalse() {
        let opts = MethodOptions()
        XCTAssertFalse(opts.useUpgradedAuth, "useUpgradedAuth must default to false")
    }

    func testMethodOptions_useUpgradedAuthExplicitTrue() {
        let opts = MethodOptions(useUpgradedAuth: true)
        XCTAssertTrue(opts.useUpgradedAuth)
    }

    func testMethodOptions_existingParamsUnaffectedByUseUpgradedAuth() {
        let opts = MethodOptions(fee: 5000, timeoutInSeconds: 120, simulate: false, restore: true, useUpgradedAuth: true)
        XCTAssertEqual(opts.fee, 5000)
        XCTAssertEqual(opts.timeoutInSeconds, 120)
        XCTAssertFalse(opts.simulate)
        XCTAssertTrue(opts.restore)
        XCTAssertTrue(opts.useUpgradedAuth)
    }

    // MARK: - needsNonInvokerSigningBy: ADDRESS arm

    func testNeedsNonInvokerSigningBy_legacyAddress_unsigned() throws {
        let tx = try makeTransactionWithAddressEntry(arm: .address, signed: false)
        let at = makeAssembledTransaction(tx: tx)
        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 1)
        XCTAssertEqual(signers[0], keyPair.accountId)
    }

    func testNeedsNonInvokerSigningBy_legacyAddress_signed_excluded() throws {
        let tx = try makeTransactionWithAddressEntry(arm: .address, signed: true)
        let at = makeAssembledTransaction(tx: tx)
        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 0)
    }

    func testNeedsNonInvokerSigningBy_legacyAddress_signed_includedWhenForced() throws {
        let tx = try makeTransactionWithAddressEntry(arm: .address, signed: true)
        let at = makeAssembledTransaction(tx: tx)
        let signers = try at.needsNonInvokerSigningBy(includeAlreadySigned: true)
        XCTAssertEqual(signers.count, 1)
    }

    // MARK: - needsNonInvokerSigningBy: ADDRESS_V2 arm

    func testNeedsNonInvokerSigningBy_addressV2_unsigned() throws {
        let tx = try makeTransactionWithAddressEntry(arm: .addressV2, signed: false)
        let at = makeAssembledTransaction(tx: tx)
        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 1)
        XCTAssertEqual(signers[0], keyPair.accountId)
    }

    func testNeedsNonInvokerSigningBy_addressV2_signed_excluded() throws {
        let tx = try makeTransactionWithAddressEntry(arm: .addressV2, signed: true)
        let at = makeAssembledTransaction(tx: tx)
        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 0)
    }

    // MARK: - needsNonInvokerSigningBy: WITH_DELEGATES arm

    /// The top-level void address is reported, AND each unsigned delegate node is reported.
    func testNeedsNonInvokerSigningBy_withDelegates_allUnsigned() throws {
        let entry = try makeWithDelegatesEntry(
            topLevelKeyPair: keyPair,
            delegateKeyPair: delegateKeyPair,
            topLevelSigned: false,
            delegateSigned: false
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 2, "Both top-level and delegate must appear when both are unsigned")
        XCTAssertTrue(signers.contains(keyPair.accountId), "Top-level address must appear")
        XCTAssertTrue(signers.contains(delegateKeyPair.accountId), "Delegate address must appear")
    }

    /// Delegate signed, top-level void: both nodes are still reported.
    /// The top-level is void (it did not sign), the delegate did sign so it must be excluded.
    func testNeedsNonInvokerSigningBy_withDelegates_delegateSigned_topLevelVoid() throws {
        let entry = try makeWithDelegatesEntry(
            topLevelKeyPair: keyPair,
            delegateKeyPair: delegateKeyPair,
            topLevelSigned: false,
            delegateSigned: true
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        let signers = try at.needsNonInvokerSigningBy()
        // Top-level void is always reported; signed delegate is excluded.
        XCTAssertTrue(signers.contains(keyPair.accountId), "Void top-level must appear")
        XCTAssertFalse(signers.contains(delegateKeyPair.accountId), "Signed delegate must NOT appear")
    }

    /// Top-level signed, delegate unsigned: only the unsigned delegate appears.
    func testNeedsNonInvokerSigningBy_withDelegates_topLevelSigned_delegateUnsigned() throws {
        let entry = try makeWithDelegatesEntry(
            topLevelKeyPair: keyPair,
            delegateKeyPair: delegateKeyPair,
            topLevelSigned: true,
            delegateSigned: false
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertFalse(signers.contains(keyPair.accountId), "Signed top-level must NOT appear")
        XCTAssertTrue(signers.contains(delegateKeyPair.accountId), "Unsigned delegate must appear")
    }

    // MARK: - send precheck: WITH_DELEGATES delegates-only pattern must not block

    /// When a WITH_DELEGATES entry has a void top-level but all delegates are signed,
    /// sign() must not throw multipleSignersRequired.
    func testSign_withDelegatesFullySigned_doesNotBlock() throws {
        let entry = try makeWithDelegatesEntry(
            topLevelKeyPair: keyPair,
            delegateKeyPair: delegateKeyPair,
            topLevelSigned: false,  // void top-level (delegates-only pattern)
            delegateSigned: true    // all delegates signed
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)
        at.simulationResponse = makeWriteCallSimResponse(authEntries: [entry])

        // Must not throw multipleSignersRequired despite the void top-level.
        XCTAssertNoThrow(try at.sign(force: true))
    }

    /// When a WITH_DELEGATES entry has unsigned delegates, sign() must block.
    func testSign_withDelegatesUnsignedDelegates_blocks() throws {
        let entry = try makeWithDelegatesEntry(
            topLevelKeyPair: keyPair,
            delegateKeyPair: delegateKeyPair,
            topLevelSigned: false,
            delegateSigned: false
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)
        at.simulationResponse = makeWriteCallSimResponse(authEntries: [entry])

        do {
            try at.sign(force: true)
            XCTFail("Expected multipleSignersRequired")
        } catch AssembledTransactionError.multipleSignersRequired {
            // Expected.
        }
    }

    // MARK: - signAuthEntries: arm preservation

    /// Signing an ADDRESS_V2 entry keeps the ARM as addressV2.
    func testSignAuthEntries_addressV2_armPreserved() async throws {
        setupGetLatestLedgerMock()

        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 42,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.addressV2(creds),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        try await at.signAuthEntries(signerKeyPair: keyPair, validUntilLedgerSeq: 1_000_000)

        let ops = at.tx!.operations
        let invokeOp = ops.first as! InvokeHostFunctionOperation
        let signedEntry = invokeOp.auth[0]

        // Arm must remain addressV2.
        guard case .addressV2(let signedCreds) = signedEntry.credentials else {
            return XCTFail("Arm must remain .addressV2 after signing, got \(signedEntry.credentials)")
        }
        // Signature must be non-void after signing.
        XCTAssertNotEqual(signedCreds.signature.type(), SCValType.void.rawValue, "Signature must be non-void after signing")
    }

    /// Signing a WITH_DELEGATES entry as the delegate lands the signature in the delegate
    /// node and leaves the top-level untouched.
    func testSignAuthEntries_withDelegates_signatureLandsInDelegateNode() async throws {
        setupGetLatestLedgerMock()

        let baseEntry = try makeAddressV2Entry(keyPair: keyPair)
        var withDelegatesEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: baseEntry,
            delegates: [SorobanDelegateDescriptor(address: delegateKeyPair.accountId)],
            expirationLedger: 1_000_000
        )
        // Ensure top-level is void (default after withDelegates).
        if case .addressWithDelegates(let wd) = withDelegatesEntry.credentials {
            XCTAssertEqual(wd.addressCredentials.signature.type(), SCValType.void.rawValue, "Top-level must start as void")
        }

        let tx = try makeTransactionWithEntry(withDelegatesEntry)
        let at = makeAssembledTransaction(tx: tx)

        // Sign as the delegate.
        try await at.signAuthEntries(signerKeyPair: delegateKeyPair, validUntilLedgerSeq: 1_000_000)

        let ops = at.tx!.operations
        let invokeOp = ops.first as! InvokeHostFunctionOperation
        let resultEntry = invokeOp.auth[0]

        guard case .addressWithDelegates(let resultWD) = resultEntry.credentials else {
            return XCTFail("Arm must remain .addressWithDelegates")
        }

        // Top-level must still be void (delegate-only signing).
        XCTAssertEqual(
            resultWD.addressCredentials.signature.type(),
            SCValType.void.rawValue,
            "Top-level signature must remain void after delegate signs"
        )

        // Delegate node must carry a non-void signature.
        XCTAssertFalse(resultWD.delegates.isEmpty, "Delegate array must not be empty")
        let delegateNode = resultWD.delegates[0]
        XCTAssertNotEqual(
            delegateNode.signature.type(),
            SCValType.void.rawValue,
            "Delegate node signature must be non-void after signing"
        )
    }

    /// Signing an ADDRESS entry as the top-level works and keeps the ADDRESS arm.
    func testSignAuthEntries_address_armPreserved() async throws {
        setupGetLatestLedgerMock()

        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 99,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(creds),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        try await at.signAuthEntries(signerKeyPair: keyPair, validUntilLedgerSeq: 1_000_000)

        let ops = at.tx!.operations
        let invokeOp = ops.first as! InvokeHostFunctionOperation
        let signedEntry = invokeOp.auth[0]

        guard case .address(let signedCreds) = signedEntry.credentials else {
            return XCTFail("Arm must remain .address")
        }
        XCTAssertNotEqual(signedCreds.signature.type(), SCValType.void.rawValue)
    }

    // MARK: - signAuthEntries: mismatched signer is silently skipped

    /// An entry for a different address is not signed and the original is preserved.
    func testSignAuthEntries_mismatchedSigner_entryUnchanged() async throws {
        setupGetLatestLedgerMock()

        let otherKeyPair = try KeyPair.generateRandomKeyPair()
        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: otherKeyPair.accountId),
            nonce: 77,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(creds),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        // Sign as keyPair, which does NOT match otherKeyPair's address.
        try await at.signAuthEntries(signerKeyPair: keyPair, validUntilLedgerSeq: 1_000_000)

        let ops = at.tx!.operations
        let invokeOp = ops.first as! InvokeHostFunctionOperation
        let resultEntry = invokeOp.auth[0]

        // Entry should be unchanged: still void signature.
        if case .address(let resultCreds) = resultEntry.credentials {
            XCTAssertEqual(resultCreds.signature.type(), SCValType.void.rawValue, "Unmatched entry must remain unsigned")
        } else {
            XCTFail("Arm must not change")
        }
    }

    // MARK: - needsNonInvokerSigningBy: sourceAccount entries are ignored

    func testNeedsNonInvokerSigningBy_sourceAccountEntry_ignored() throws {
        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.sourceAccount,
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)
        let signers = try at.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 0, "sourceAccount entries must be ignored")
    }

    // MARK: - signAuthEntries: sourceAccount entries are skipped without error

    func testSignAuthEntries_sourceAccountEntry_skippedWithoutError() async throws {
        setupGetLatestLedgerMock()

        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.sourceAccount,
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)
        // Must not throw for sourceAccount entries.
        try await at.signAuthEntries(signerKeyPair: keyPair, validUntilLedgerSeq: 1_000_000)
    }

    // MARK: - needsNonInvokerSigningBy: includeAlreadySigned with WITH_DELEGATES

    func testNeedsNonInvokerSigningBy_withDelegates_includeAlreadySigned() throws {
        let entry = try makeWithDelegatesEntry(
            topLevelKeyPair: keyPair,
            delegateKeyPair: delegateKeyPair,
            topLevelSigned: true,
            delegateSigned: true
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        let signersExcluded = try at.needsNonInvokerSigningBy(includeAlreadySigned: false)
        let signersIncluded = try at.needsNonInvokerSigningBy(includeAlreadySigned: true)

        XCTAssertEqual(signersExcluded.count, 0, "All signed: none should appear without includeAlreadySigned")
        XCTAssertEqual(signersIncluded.count, 2, "All signed: both should appear with includeAlreadySigned")
    }

    // MARK: - Helpers

    private func makeMockTransaction() throws -> Transaction {
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)
        let op = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: mockContractId,
            functionName: "test",
            functionArguments: []
        )
        return try Transaction(sourceAccount: account, operations: [op], memo: Memo.none)
    }

    private enum AddressArm { case address, addressV2 }

    private func makeTransactionWithAddressEntry(arm: AddressArm, signed: Bool) throws -> Transaction {
        let sigVal: SCValXDR = signed
            ? makeMockSignatureVec()
            : SCValXDR.void
        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 1,
            signatureExpirationLedger: 1_000_000,
            signature: sigVal
        )
        let credentials: SorobanCredentialsXDR = arm == .address
            ? .address(creds)
            : .addressV2(creds)
        let entry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: makeRootInvocation()
        )
        return try makeTransactionWithEntry(entry)
    }

    private func makeWithDelegatesEntry(
        topLevelKeyPair: KeyPair,
        delegateKeyPair: KeyPair,
        topLevelSigned: Bool,
        delegateSigned: Bool
    ) throws -> SorobanAuthorizationEntryXDR {
        let delegateSig: SCValXDR = delegateSigned ? makeMockSignatureVec() : SCValXDR.void
        let descriptor = SorobanDelegateDescriptor(
            address: delegateKeyPair.accountId,
            signature: delegateSig
        )
        let sourceEntry = try makeAddressV2Entry(keyPair: topLevelKeyPair)
        var entry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [descriptor],
            expirationLedger: 1_000_000
        )
        if topLevelSigned {
            // Stamp a mock signature into the top-level credentials.
            if case .addressWithDelegates(var wd) = entry.credentials {
                wd.addressCredentials.signature = makeMockSignatureVec()
                entry.credentials = .addressWithDelegates(wd)
            }
        }
        return entry
    }

    private func makeAddressV2Entry(keyPair: KeyPair) throws -> SorobanAuthorizationEntryXDR {
        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 1,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.addressV2(creds),
            rootInvocation: makeRootInvocation()
        )
    }

    private func makeTransactionWithEntry(_ entry: SorobanAuthorizationEntryXDR) throws -> Transaction {
        try makeTransactionWithEntries([entry])
    }

    private func makeTransactionWithEntries(_ entries: [SorobanAuthorizationEntryXDR]) throws -> Transaction {
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)
        let op = InvokeHostFunctionOperation(
            hostFunction: HostFunctionXDR.invokeContract(
                InvokeContractArgsXDR(
                    contractAddress: try SCAddressXDR(contractId: mockContractId),
                    functionName: "test",
                    args: []
                )
            ),
            auth: entries,
            sourceAccountId: nil
        )
        return try Transaction(sourceAccount: account, operations: [op], memo: Memo.none)
    }

    private func makeRootInvocation() -> SorobanAuthorizedInvocationXDR {
        SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(
                InvokeContractArgsXDR(
                    contractAddress: try! SCAddressXDR(contractId: mockContractId),
                    functionName: "test",
                    args: []
                )
            ),
            subInvocations: []
        )
    }

    private func makeAssembledTransaction(tx: Transaction) -> AssembledTransaction {
        let methodOptions = MethodOptions()
        let opts = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )
        let at = AssembledTransaction(options: opts)
        at.tx = tx
        return at
    }

    /// Builds a mock SimulateTransactionResponse with write footprint and provided auth entries.
    private func makeWriteCallSimResponse(authEntries: [SorobanAuthorizationEntryXDR]) -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(
                    readOnly: [],
                    readWrite: [LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
                        contract: try! SCAddressXDR(contractId: mockContractId),
                        key: SCValXDR.u32(1),
                        durability: .persistent
                    ))]
                ),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let authXdrStrings = authEntries.compactMap { $0.xdrEncoded }
        let authJson = authXdrStrings.map { "\"\($0)\"" }.joined(separator: ",")
        let txDataXdr = transactionData.xdrEncoded!
        let returnValueXdr = SCValXDR.void.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "transactionData": "\(txDataXdr)",
            "minResourceFee": "10000",
            "results": [
                {
                    "auth": [\(authJson)],
                    "xdr": "\(returnValueXdr)"
                }
            ]
        }
        """
        let jsonData = jsonResponse.data(using: .utf8)!
        return try! JSONDecoder().decode(SimulateTransactionResponse.self, from: jsonData)
    }

    /// A minimal non-void SCVal that can serve as a mock signature vector element.
    private func makeMockSignatureVec() -> SCValXDR {
        // Use a vec with a single u32 to represent "signed" in tests that only check
        // whether the signature is void or non-void.
        return SCValXDR.vec([SCValXDR.u32(1)])
    }

    // MARK: - delegateTreeContainsAccountId recursive path

    /// Exercises the recursive call in `delegateTreeContainsAccountId`:
    /// the signing signer address matches only in the second level of a 2-level delegate tree.
    /// `needsNonInvokerSigningBy` must report the nested (unsigned) delegate address.
    func testNeedsNonInvokerSigningBy_nestedDelegate_reportedUnsigned() throws {
        // Build a 2-level delegate tree manually: top-level is the keyPair's account,
        // inner delegate is the delegateKeyPair's account (unsigned).
        let topLevelAddr = try SCAddressXDR(accountId: keyPair.accountId)
        let innerAddr = try SCAddressXDR(accountId: delegateKeyPair.accountId)

        let innerNode = SorobanDelegateSignatureXDR(
            address: innerAddr,
            signature: .void,
            nestedDelegates: []
        )
        // Outer delegate node (signed) with an inner unsigned nested delegate.
        let outerNode = SorobanDelegateSignatureXDR(
            address: topLevelAddr,
            signature: makeMockSignatureVec(),
            nestedDelegates: [innerNode]
        )

        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: mockContractId),
            nonce: 1,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: creds,
            delegates: [outerNode]
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        let signers = try at.needsNonInvokerSigningBy()
        // Top-level (contract address) is not an account so it is excluded by the
        // G-address filter. The outer delegate (signed) must be excluded.
        // The inner nested delegate (unsigned G-address) must appear.
        XCTAssertFalse(signers.contains(keyPair.accountId),
                       "Signed outer delegate must NOT appear in needsNonInvokerSigningBy")
        XCTAssertTrue(signers.contains(delegateKeyPair.accountId),
                      "Unsigned inner nested delegate must appear in needsNonInvokerSigningBy")
    }

    /// Exercises `delegateTreeContainsAccountId` via `signAuthEntries`: signer address is found
    /// only in the second level of the delegate tree (nested delegate), triggering the recursive
    /// call in AssembledTransaction.swift.
    func testSignAuthEntries_nestedDelegateSigner_routedCorrectly() async throws {
        setupGetLatestLedgerMock()

        // Build a 2-level delegate tree: outer node is a contract address (does NOT match
        // the signer's G-address), inner node IS the signer's G-address.
        let outerContractAddr = try SCAddressXDR(contractId: mockContractId)
        let innerAccountAddr = try SCAddressXDR(accountId: delegateKeyPair.accountId)

        let innerNode = SorobanDelegateSignatureXDR(
            address: innerAccountAddr,
            signature: .void,
            nestedDelegates: []
        )
        let outerNode = SorobanDelegateSignatureXDR(
            address: outerContractAddr,
            signature: .void,
            nestedDelegates: [innerNode]
        )

        // Top-level credentials address is the keyPair's account (not the delegate signer's).
        let topLevelCreds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 1,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: topLevelCreds,
            delegates: [outerNode]
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        // signAuthEntries with delegateKeyPair: the signer's address is only in the inner
        // nested delegate, so delegateTreeContainsAccountId must recurse to find it.
        // Confirming this does NOT throw verifies the recursive path was exercised and matched.
        try await at.signAuthEntries(signerKeyPair: delegateKeyPair)

        // The signAuthEntries call would throw `.unexpectedTxType` or skip (continue) the entry
        // if the recursive search failed. Reaching here confirms the nested delegate was found.
        // Read the updated auth from the AssembledTransaction's tx reference.
        guard let updatedTx = at.tx,
              let updatedOp = updatedTx.operations.first as? InvokeHostFunctionOperation,
              case .addressWithDelegates(let wd) = updatedOp.auth.first?.credentials,
              let outerDelegate = wd.delegates.first else {
            // If the operation or credentials are not found, the test structure is invalid.
            XCTFail("Could not access updated auth entries after signAuthEntries")
            return
        }
        // Outer node (contract address) must still be void (contract addresses don't match G-address signers).
        XCTAssertTrue(outerDelegate.signature.isVoid,
                      "Outer delegate (contract address) must remain void when only the nested node matches")
        // Inner node must have a non-void signature.
        if let nestedDelegate = outerDelegate.nestedDelegates.first {
            XCTAssertFalse(nestedDelegate.signature.isVoid,
                           "Inner nested delegate (signer's account) must have a non-void signature after signAuthEntries")
        } else {
            XCTFail("Expected a nested delegate node")
        }
    }

    /// Exercises the path in `delegateTreeContainsAccountId`: when the signer address
    /// is not present in any delegate node, the function exhausts the array and returns `false`.
    /// The entry is then skipped (signAuthEntries continues to the next entry).
    func testSignAuthEntries_withDelegates_nonMatchingSigner_skipsEntry() async throws {
        setupGetLatestLedgerMock()

        // Create a WITH_DELEGATES entry where neither the top-level credentials nor any
        // delegate node matches the signer's address.
        let unrelatedKeyPair = try KeyPair.generateRandomKeyPair()
        let topLevelAddr = try SCAddressXDR(contractId: mockContractId)
        let delegateAddr = try SCAddressXDR(accountId: keyPair.accountId)

        let delegateNode = SorobanDelegateSignatureXDR(
            address: delegateAddr,
            signature: .void,
            nestedDelegates: []
        )
        let creds = SorobanAddressCredentialsXDR(
            address: topLevelAddr,
            nonce: 1,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: creds,
            delegates: [delegateNode]
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        // Sign with unrelatedKeyPair: neither top-level (contract) nor delegate (keyPair) matches.
        // delegateTreeContainsAccountId must exhaust the array and return false → entry skipped.
        // Confirming no throw proves the return-false path was taken without error.
        try await at.signAuthEntries(signerKeyPair: unrelatedKeyPair)

        // Entry must remain unchanged (top-level and delegate signatures still void).
        guard let updatedTx = at.tx,
              let updatedOp = updatedTx.operations.first as? InvokeHostFunctionOperation,
              case .addressWithDelegates(let updatedWD) = updatedOp.auth.first?.credentials else {
            XCTFail("Could not read updated auth from AssembledTransaction")
            return
        }
        XCTAssertTrue(updatedWD.addressCredentials.signature.isVoid,
                      "Top-level signature must remain void when signer does not match")
        XCTAssertTrue(updatedWD.delegates.first?.signature.isVoid ?? true,
                      "Delegate signature must remain void when signer does not match")
    }

    // MARK: - signAuthEntries authorizeEntryCallback paths

    /// Exercises the `authorizeEntryCallback` path for the `.addressV2` arm.
    /// When a callback is provided, signAuthEntries must route the V2 entry through the callback
    /// rather than directly calling `entry.sign`.
    func testSignAuthEntries_addressV2_withCallback_routesThroughCallback() async throws {
        setupGetLatestLedgerMock()

        let v2Entry = try makeAddressV2Entry(keyPair: keyPair)
        let tx = try makeTransactionWithEntry(v2Entry)
        let at = makeAssembledTransaction(tx: tx)

        var callbackInvoked = false
        var receivedEntry: SorobanAuthorizationEntryXDR?
        try await at.signAuthEntries(
            signerKeyPair: keyPair,
            authorizeEntryCallback: { entry, _ in
                callbackInvoked = true
                receivedEntry = entry
                return entry
            }
        )

        XCTAssertTrue(callbackInvoked, "authorizeEntryCallback must be called for ADDRESS_V2 entry")
        if let received = receivedEntry {
            if case .addressV2 = received.credentials {
                // arm preserved — expected
            } else {
                XCTFail("Callback must receive a .addressV2 entry, got \(received.credentials)")
            }
        }
    }

    /// Exercises the `authorizeEntryCallback` path for the `.addressWithDelegates` arm.
    /// When a callback is provided, signAuthEntries must route the WITH_DELEGATES entry through the
    /// callback for any signer that matches the entry (top-level or delegate).
    func testSignAuthEntries_withDelegates_withCallback_routesThroughCallback() async throws {
        setupGetLatestLedgerMock()

        let delegateAddr = try SCAddressXDR(accountId: keyPair.accountId)
        let delegateNode = SorobanDelegateSignatureXDR(
            address: delegateAddr,
            signature: .void,
            nestedDelegates: []
        )
        let topCreds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 1,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: topCreds,
            delegates: [delegateNode]
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        var callbackInvoked = false
        var receivedEntry: SorobanAuthorizationEntryXDR?
        try await at.signAuthEntries(
            signerKeyPair: keyPair,
            authorizeEntryCallback: { entry, _ in
                callbackInvoked = true
                receivedEntry = entry
                return entry
            }
        )

        XCTAssertTrue(callbackInvoked, "authorizeEntryCallback must be called for WITH_DELEGATES entry when signer matches")
        if let received = receivedEntry {
            if case .addressWithDelegates = received.credentials {
                // arm preserved — expected
            } else {
                XCTFail("Callback must receive a .addressWithDelegates entry, got \(received.credentials)")
            }
        }
    }

    // MARK: - Gap 2: missingPrivateKey for ADDRESS_V2 and WITH_DELEGATES arms

    /// Verifies that signAuthEntries throws AssembledTransactionError.missingPrivateKey when
    /// the signer is a public-key-only KeyPair and no callback is provided, for the
    /// .addressV2 arm.
    func testSignAuthEntries_addressV2_publicKeyOnlySigner_throwsMissingPrivateKey() async throws {
        setupGetLatestLedgerMock()

        // Build a V2 entry whose credential address matches the public-key-only signer.
        let publicOnlySigner = try KeyPair(accountId: keyPair.accountId)
        XCTAssertNil(publicOnlySigner.privateKey, "Expected nil privateKey on public-key-only KeyPair")

        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: publicOnlySigner.accountId),
            nonce: 55,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.addressV2(creds),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        do {
            try await at.signAuthEntries(signerKeyPair: publicOnlySigner, validUntilLedgerSeq: 1_000_000)
            XCTFail("Expected AssembledTransactionError.missingPrivateKey for ADDRESS_V2 arm with public-key-only signer")
        } catch AssembledTransactionError.missingPrivateKey {
            // Expected: the ADDRESS_V2 arm must throw missingPrivateKey when no callback provided.
        }
    }

    /// Verifies that signAuthEntries throws AssembledTransactionError.missingPrivateKey when
    /// the signer is a public-key-only KeyPair and no callback is provided, for the
    /// .addressWithDelegates arm (top-level address matches the signer).
    func testSignAuthEntries_withDelegates_publicKeyOnlySigner_throwsMissingPrivateKey() async throws {
        setupGetLatestLedgerMock()

        let publicOnlySigner = try KeyPair(accountId: keyPair.accountId)
        XCTAssertNil(publicOnlySigner.privateKey, "Expected nil privateKey on public-key-only KeyPair")

        // Top-level address matches the public-key-only signer.
        let topCreds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: publicOnlySigner.accountId),
            nonce: 77,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let unrelatedDelegate = SorobanDelegateSignatureXDR(
            address: try SCAddressXDR(contractId: mockContractId),
            signature: .void,
            nestedDelegates: []
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: topCreds,
            delegates: [unrelatedDelegate]
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        do {
            try await at.signAuthEntries(signerKeyPair: publicOnlySigner, validUntilLedgerSeq: 1_000_000)
            XCTFail("Expected AssembledTransactionError.missingPrivateKey for WITH_DELEGATES arm with public-key-only signer")
        } catch AssembledTransactionError.missingPrivateKey {
            // Expected: the WITH_DELEGATES arm must throw missingPrivateKey when no callback provided.
        }
    }

    // MARK: - Gap 3: delegate-only callback routing (contract top-level, G-address delegate)

    /// Verifies that when the top-level address is a CONTRACT (C-address) and the sole
    /// delegate is a G-address matching the signer, signAuthEntries routes the entry through
    /// the authorizeEntryCallback and the callback receives a .addressWithDelegates entry.
    /// This proves that delegateMatches routing (not topLevelMatches) fires the callback.
    func testSignAuthEntries_withDelegates_contractTopLevel_delegateMatchesSigner_callbackFired() async throws {
        setupGetLatestLedgerMock()

        // Top-level is a contract (C-address) — never matches the signer's G-address.
        let contractTopLevelAddr = try SCAddressXDR(contractId: mockContractId)
        // The sole delegate is the signer's G-address.
        let delegateAddr = try SCAddressXDR(accountId: keyPair.accountId)
        let delegateNode = SorobanDelegateSignatureXDR(
            address: delegateAddr,
            signature: .void,
            nestedDelegates: []
        )
        let topCreds = SorobanAddressCredentialsXDR(
            address: contractTopLevelAddr,
            nonce: 99,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: topCreds,
            delegates: [delegateNode]
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: makeRootInvocation()
        )
        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        var callbackInvokeCount = 0
        var receivedEntry: SorobanAuthorizationEntryXDR?
        try await at.signAuthEntries(
            signerKeyPair: keyPair,
            authorizeEntryCallback: { entry, _ in
                callbackInvokeCount += 1
                receivedEntry = entry
                return entry
            },
            validUntilLedgerSeq: 1_000_000
        )

        XCTAssertEqual(callbackInvokeCount, 1,
                       "Callback must be invoked exactly once via the delegateMatches routing path")

        guard let received = receivedEntry else {
            XCTFail("Callback must receive the WITH_DELEGATES entry"); return
        }
        if case .addressWithDelegates = received.credentials {
            // arm preserved — expected
        } else {
            XCTFail("Callback must receive a .addressWithDelegates entry, got \(received.credentials)")
        }
    }

    // MARK: - signAuthEntries: callback receives the stamped expiration

    /// The signer stamps `signatureExpirationLedger` onto the entry's credentials BEFORE
    /// handing it to `authorizeEntryCallback`. The entry observed inside the callback must
    /// already carry the requested expiration, not the stale value stored in the credentials.
    ///
    /// Uses the legacy `.address` arm. The fixture starts with `signatureExpirationLedger == 0`;
    /// the callback captures the entry and the captured value must equal the requested ledger.
    func testSignAuthEntries_callbackReceivesStampedExpiration() async throws {
        setupGetLatestLedgerMock()

        let creds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 31,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(creds),
            rootInvocation: makeRootInvocation()
        )
        // Sanity: fixture starts at expiration 0.
        XCTAssertEqual(entry.credentials.addressCredentials?.signatureExpirationLedger, 0,
                       "Fixture must start with signatureExpirationLedger == 0")

        let tx = try makeTransactionWithEntry(entry)
        let at = makeAssembledTransaction(tx: tx)

        let requestedExpiration: UInt32 = 1_000_000
        var capturedExpiration: UInt32?
        try await at.signAuthEntries(
            signerKeyPair: keyPair,
            authorizeEntryCallback: { received, _ in
                capturedExpiration = received.credentials.addressCredentials?.signatureExpirationLedger
                return received
            },
            validUntilLedgerSeq: requestedExpiration
        )

        XCTAssertEqual(
            capturedExpiration, requestedExpiration,
            "The callback must observe the stamped signatureExpirationLedger, not the stale value"
        )
    }

    // MARK: - signAuthEntries: callback must not corrupt a sibling entry signed by another party

    /// `signAuthEntries` signs only the entries whose address matches the signer; the matching
    /// guard gates the callback. An entry already signed by a different party must be left
    /// byte-identical, and the callback must fire exactly once for the single matching entry.
    func testSignAuthEntries_callbackDoesNotModifySiblingSignedByAnotherParty() async throws {
        setupGetLatestLedgerMock()

        let keyPairA = try KeyPair.generateRandomKeyPair()
        let keyPairB = try KeyPair.generateRandomKeyPair()

        // Entry A: already signed by keyPairA (non-void signature).
        let credsA = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPairA.accountId),
            nonce: 11,
            signatureExpirationLedger: 1_000_000,
            signature: SCValXDR.void
        )
        var entryA = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(credsA),
            rootInvocation: makeRootInvocation()
        )
        try entryA.sign(signer: keyPairA, network: network)
        // Confirm entry A is now signed.
        XCTAssertNotEqual(
            entryA.credentials.addressCredentials?.signature.type(), SCValType.void.rawValue,
            "Entry A must be signed before the call"
        )
        guard let entryABefore = entryA.xdrEncoded else {
            return XCTFail("Could not encode entry A to base64 XDR")
        }

        // Entry B: void, addressed to keyPairB (the signer in this call).
        let credsB = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPairB.accountId),
            nonce: 22,
            signatureExpirationLedger: 0,
            signature: SCValXDR.void
        )
        let entryB = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(credsB),
            rootInvocation: makeRootInvocation()
        )

        let tx = try makeTransactionWithEntries([entryA, entryB])
        let at = makeAssembledTransaction(tx: tx)

        var callbackInvokeCount = 0
        try await at.signAuthEntries(
            signerKeyPair: keyPairB,
            authorizeEntryCallback: { received, net in
                callbackInvokeCount += 1
                var toSign = received
                try toSign.sign(signer: keyPairB, network: net)
                return toSign
            },
            validUntilLedgerSeq: 1_000_000
        )

        let ops = at.tx!.operations
        let invokeOp = ops.first as! InvokeHostFunctionOperation
        let resultEntryA = invokeOp.auth[0]
        let resultEntryB = invokeOp.auth[1]

        // Entry A must be byte-identical: the callback must never touch a non-matching sibling.
        XCTAssertEqual(
            resultEntryA.xdrEncoded, entryABefore,
            "Sibling entry signed by another party must be byte-identical after the call"
        )
        // Entry B must have been routed through the callback and signed.
        XCTAssertNotEqual(
            resultEntryB.credentials.addressCredentials?.signature.type(), SCValType.void.rawValue,
            "Matching entry B must be signed by the callback"
        )
        // The callback must fire exactly once: only the matching entry reaches it.
        XCTAssertEqual(
            callbackInvokeCount, 1,
            "Callback must be invoked exactly once for the single matching entry"
        )
    }

    // MARK: - MethodOptions.useUpgradedAuth threads through simulate() into JSON-RPC request

    /// Verifies that MethodOptions(useUpgradedAuth: true) causes simulate() to include
    /// "useUpgradedAuth": true in the JSON-RPC request body sent to the server.
    ///
    /// URLProtocol delivers the body via httpBodyStream (not httpBody) once a request enters
    /// the protocol pipeline, so both paths are checked.
    func testSimulate_withUseUpgradedAuthTrue_sendsUseUpgradedAuthInRequest() async throws {
        var capturedBodyData: Data?

        let handler: MockHandler = { mock, request in
            // URLProtocol puts the POST body into httpBodyStream, not httpBody.
            if let data = request.httpBody {
                capturedBodyData = data
            } else if let stream = request.httpBodyStream {
                capturedBodyData = stream.readfully()
            }
            mock.statusCode = 200
            return self.makeMinimalSimulateResponse()
        }
        ServerMock.add(mock: RequestMock(
            host: "soroban-testnet.stellar.org",
            path: "*",
            httpMethod: "POST",
            mockHandler: handler
        ))

        let methodOptions = MethodOptions(useUpgradedAuth: true)
        let opts = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )
        let at = AssembledTransaction(options: opts)
        at.tx = try makeMockTransaction()

        try await at.simulate()

        guard let bodyData = capturedBodyData,
              let jsonObj = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let params = jsonObj["params"] as? [String: Any] else {
            XCTFail("Could not read or parse the captured JSON-RPC request body")
            return
        }

        guard let useUpgradedAuthVal = params["useUpgradedAuth"] as? Bool else {
            XCTFail("'useUpgradedAuth' key must be present in params when MethodOptions(useUpgradedAuth: true) is used; got params keys: \(params.keys.sorted())")
            return
        }
        XCTAssertTrue(useUpgradedAuthVal, "useUpgradedAuth value must be true")
    }

    /// Verifies that the default MethodOptions() causes simulate() to omit the "useUpgradedAuth"
    /// key entirely from the JSON-RPC request body.
    func testSimulate_defaultMethodOptions_useUpgradedAuthKeyAbsent() async throws {
        var capturedBodyData: Data?

        let handler: MockHandler = { mock, request in
            if let data = request.httpBody {
                capturedBodyData = data
            } else if let stream = request.httpBodyStream {
                capturedBodyData = stream.readfully()
            }
            mock.statusCode = 200
            return self.makeMinimalSimulateResponse()
        }
        ServerMock.add(mock: RequestMock(
            host: "soroban-testnet.stellar.org",
            path: "*",
            httpMethod: "POST",
            mockHandler: handler
        ))

        let opts = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(),
            method: "test"
        )
        let at = AssembledTransaction(options: opts)
        at.tx = try makeMockTransaction()

        try await at.simulate()

        guard let bodyData = capturedBodyData,
              let jsonObj = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let params = jsonObj["params"] as? [String: Any] else {
            XCTFail("Could not read or parse the captured JSON-RPC request body")
            return
        }

        XCTAssertNil(params["useUpgradedAuth"],
                     "useUpgradedAuth key must be ABSENT from params when MethodOptions uses the default (false)")
    }

    // MARK: - Helper: minimal simulate response

    private func makeMinimalSimulateResponse() -> String {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                instructions: 100,
                diskReadBytes: 0,
                writeBytes: 0
            ),
            resourceFee: 100
        )
        let txDataXdr = transactionData.xdrEncoded!
        let returnValueXdr = SCValXDR.void.xdrEncoded!
        return """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "result": {
                "latestLedger": 1000000,
                "transactionData": "\(txDataXdr)",
                "minResourceFee": "100",
                "results": [
                    {
                        "auth": [],
                        "xdr": "\(returnValueXdr)"
                    }
                ]
            }
        }
        """
    }

    private func setupGetLatestLedgerMock() {
        let handler: MockHandler = { mock, _ in
            mock.statusCode = 200
            return """
            {
                "jsonrpc": "2.0",
                "id": 1,
                "result": {
                    "id": "abc123",
                    "sequence": 999900,
                    "protocolVersion": 27
                }
            }
            """
        }
        ServerMock.add(mock: RequestMock(
            host: "soroban-testnet.stellar.org",
            path: "*",
            httpMethod: "POST",
            mockHandler: handler
        ))
    }
}
