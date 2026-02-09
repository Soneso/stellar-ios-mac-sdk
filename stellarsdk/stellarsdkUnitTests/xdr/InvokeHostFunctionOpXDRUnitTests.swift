//
//  InvokeHostFunctionOpXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class InvokeHostFunctionOpXDRUnitTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func createTestContractAddress() throws -> SCAddressXDR {
        // Create a 32-byte contract ID
        let contractIdBytes = Data(repeating: 0xAB, count: 32)
        return .contract(WrappedData32(contractIdBytes))
    }

    private func createTestAccountAddress() throws -> SCAddressXDR {
        let keyPair = try KeyPair.generateRandomKeyPair()
        return .account(keyPair.publicKey)
    }

    private func createTestWasmHash() -> WrappedData32 {
        let wasmHashBytes = Data(repeating: 0xCD, count: 32)
        return WrappedData32(wasmHashBytes)
    }

    private func createTestSalt() -> WrappedData32 {
        let saltBytes = Data(repeating: 0xEF, count: 32)
        return WrappedData32(saltBytes)
    }

    // MARK: - HostFunctionXDR Tests

    func testHostFunctionXDRInvokeContract() throws {
        let contractAddress = try createTestContractAddress()
        let functionName = "transfer"
        let args: [SCValXDR] = [
            .u64(1000),
            .bool(true)
        ]

        let invokeContractArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: functionName,
            args: args
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeContractArgs)

        let encoded = try XDREncoder.encode(hostFunction)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), HostFunctionType.invokeContract.rawValue)
        XCTAssertNotNil(decoded.invokeContract)
        XCTAssertEqual(decoded.invokeContract?.functionName, functionName)
        XCTAssertEqual(decoded.invokeContract?.args.count, 2)
    }

    func testHostFunctionXDRCreateContract() throws {
        let accountAddress = try createTestAccountAddress()
        let salt = createTestSalt()
        let wasmHash = createTestWasmHash()

        let preimageFromAddress = ContractIDPreimageFromAddressXDR(
            address: accountAddress,
            salt: salt
        )
        let preimage = ContractIDPreimageXDR.fromAddress(preimageFromAddress)
        let executable = ContractExecutableXDR.wasm(wasmHash)

        let createContractArgs = CreateContractArgsXDR(
            contractIDPreimage: preimage,
            executable: executable
        )
        let hostFunction = HostFunctionXDR.createContract(createContractArgs)

        let encoded = try XDREncoder.encode(hostFunction)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), HostFunctionType.createContract.rawValue)
        XCTAssertNotNil(decoded.createContract)
        XCTAssertNotNil(decoded.createContract?.executable.wasm)
        XCTAssertEqual(decoded.createContract?.executable.wasm?.wrapped, wasmHash.wrapped)
    }

    func testHostFunctionXDRUploadWasm() throws {
        let wasmCode = Data([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]) // Minimal WASM header

        let hostFunction = HostFunctionXDR.uploadContractWasm(wasmCode)

        let encoded = try XDREncoder.encode(hostFunction)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), HostFunctionType.uploadContractWasm.rawValue)
        XCTAssertNotNil(decoded.uploadContractWasm)
        XCTAssertEqual(decoded.uploadContractWasm, wasmCode)
    }

    // MARK: - InvokeHostFunctionOpXDR Tests

    func testInvokeHostFunctionOpXDREncodeDecode() throws {
        let contractAddress = try createTestContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "initialize",
            args: []
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        let invokeOp = InvokeHostFunctionOpXDR(
            hostFunction: hostFunction,
            auth: []
        )

        let encoded = try XDREncoder.encode(invokeOp)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionOpXDR.self, data: encoded)

        XCTAssertNotNil(decoded.hostFunction.invokeContract)
        XCTAssertEqual(decoded.hostFunction.invokeContract?.functionName, "initialize")
        XCTAssertEqual(decoded.auth.count, 0)
    }

    func testInvokeHostFunctionOpXDRWithAuth() throws {
        let contractAddress = try createTestContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "mint",
            args: [.u64(1000000)]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Create authorization entry with source account credentials
        let authorizedFunction = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: authorizedFunction,
            subInvocations: []
        )
        let credentials = SorobanCredentialsXDR.sourceAccount
        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )

        let invokeOp = InvokeHostFunctionOpXDR(
            hostFunction: hostFunction,
            auth: [authEntry]
        )

        let encoded = try XDREncoder.encode(invokeOp)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.auth.count, 1)
        XCTAssertNotNil(decoded.auth[0].rootInvocation.function.contractFn)
    }

    func testInvokeHostFunctionOpXDRWithMultipleAuth() throws {
        let contractAddress = try createTestContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "swap",
            args: [.u64(500), .u64(1000)]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Create multiple authorization entries
        let authorizedFunction = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: authorizedFunction,
            subInvocations: []
        )
        let credentials = SorobanCredentialsXDR.sourceAccount

        let authEntry1 = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )
        let authEntry2 = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )
        let authEntry3 = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )

        let invokeOp = InvokeHostFunctionOpXDR(
            hostFunction: hostFunction,
            auth: [authEntry1, authEntry2, authEntry3]
        )

        let encoded = try XDREncoder.encode(invokeOp)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.auth.count, 3)
    }

    func testInvokeHostFunctionOpXDRRoundTrip() throws {
        let contractAddress = try createTestContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "balance",
            args: []
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        let invokeOp = InvokeHostFunctionOpXDR(
            hostFunction: hostFunction,
            auth: []
        )

        // Encode to base64
        guard let base64 = invokeOp.xdrEncoded else {
            XCTFail("Failed to encode InvokeHostFunctionOpXDR to base64")
            return
        }

        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        let decoded = try InvokeHostFunctionOpXDR(xdr: base64)

        XCTAssertEqual(decoded.hostFunction.type(), HostFunctionType.invokeContract.rawValue)
        XCTAssertEqual(decoded.hostFunction.invokeContract?.functionName, "balance")
    }

    // MARK: - SorobanAuthorizationEntry Tests

    func testSorobanAuthorizationEntryXDREncodeDecode() throws {
        let contractAddress = try createTestContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "approve",
            args: [.u64(999)]
        )

        let authorizedFunction = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: authorizedFunction,
            subInvocations: []
        )
        let credentials = SorobanCredentialsXDR.sourceAccount
        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )

        let encoded = try XDREncoder.encode(authEntry)
        let decoded = try XDRDecoder.decode(SorobanAuthorizationEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.credentials.type(), SorobanCredentialsType.sourceAccount.rawValue)
        XCTAssertNotNil(decoded.rootInvocation.function.contractFn)
        XCTAssertEqual(decoded.rootInvocation.function.contractFn?.functionName, "approve")
    }

    func testSorobanAuthorizedFunctionXDRContractFn() throws {
        let contractAddress = try createTestContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "deposit",
            args: [.u128(UInt128PartsXDR(hi: 0, lo: 5000))]
        )

        let authorizedFunction = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)

        let encoded = try XDREncoder.encode(authorizedFunction)
        let decoded = try XDRDecoder.decode(SorobanAuthorizedFunctionXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SorobanAuthorizedFunctionType.contractFn.rawValue)
        XCTAssertNotNil(decoded.contractFn)
        XCTAssertEqual(decoded.contractFn?.functionName, "deposit")
        XCTAssertEqual(decoded.contractFn?.args.count, 1)
    }

    func testSorobanCredentialsXDRSourceAccount() throws {
        let credentials = SorobanCredentialsXDR.sourceAccount

        let encoded = try XDREncoder.encode(credentials)
        let decoded = try XDRDecoder.decode(SorobanCredentialsXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SorobanCredentialsType.sourceAccount.rawValue)
        XCTAssertNil(decoded.address)
    }

    // MARK: - InvokeHostFunctionResult Tests

    func testInvokeHostFunctionResultXDRSuccess() throws {
        let successHash = WrappedData32(Data(repeating: 0x11, count: 32))
        let result = InvokeHostFunctionResultXDR.success(successHash)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .success(let hash):
            XCTAssertEqual(hash.wrapped, successHash.wrapped)
        default:
            XCTFail("Expected success case")
        }
    }

    func testInvokeHostFunctionResultXDRMalformed() throws {
        let result = InvokeHostFunctionResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        if case .malformed = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected malformed case but got \(decoded)")
        }
    }

    func testInvokeHostFunctionResultXDRTrapped() throws {
        let result = InvokeHostFunctionResultXDR.trapped

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        if case .trapped = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected trapped case but got \(decoded)")
        }
    }

    func testInvokeHostFunctionResultXDRResourceLimitExceeded() throws {
        let result = InvokeHostFunctionResultXDR.resourceLimitExceeded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        if case .resourceLimitExceeded = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected resourceLimitExceeded case but got \(decoded)")
        }
    }

    func testInvokeHostFunctionResultXDREntryExpired() throws {
        let result = InvokeHostFunctionResultXDR.entryExpired

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        if case .entryExpired = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected entryExpired case but got \(decoded)")
        }
    }
}
