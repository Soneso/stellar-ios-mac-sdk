//
//  TxRepSorobanTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TxRepSorobanTestCase: XCTestCase {

    func testSorobanTransactionDataTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 50000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let functionName = "hello"
        let args = [SCValXDR.u32(5)]

        let invokeOperation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: contractId,
            functionName: functionName,
            functionArguments: args,
            sourceAccountId: nil,
            auth: []
        )

        let resources = SorobanResourcesXDR(
            footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
            instructions: 100000,
            diskReadBytes: 1000,
            writeBytes: 1000
        )

        let sorobanData = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 50000
        )

        let preconditions = TransactionPreconditions(ledgerBounds: LedgerBounds(minLedger: 0, maxLedger: 0))

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [invokeOperation],
            memo: Memo.none,
            preconditions: preconditions,
            sorobanTransactionData: sorobanData
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.ext.v: 1"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.ext.v: 0"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readOnly.len: 0"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readWrite.len: 0"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.instructions: 100000"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.diskReadBytes: 1000"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.writeBytes: 1000"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resourceFee: 50000"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testInvokeContractTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 51000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let functionName = "increment"
        let args = [SCValXDR.u32(10)]

        let invokeOperation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: contractId,
            functionName: functionName,
            functionArguments: args,
            sourceAccountId: nil,
            auth: []
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [invokeOperation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: INVOKE_HOST_FUNCTION"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.type: SC_ADDRESS_TYPE_CONTRACT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.functionName:"))
        XCTAssertTrue(txRep.contains("increment"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testSorobanAuthEntriesTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 52000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let functionName = "auth_test"

        let credentials = SorobanCredentialsXDR.sourceAccount
        let rootInvocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: contractId),
                functionName: functionName,
                args: []
            )),
            subInvocations: []
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: rootInvocation
        )

        let invokeOperation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: contractId,
            functionName: functionName,
            functionArguments: [],
            sourceAccountId: nil,
            auth: [authEntry]
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [invokeOperation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        // Verify auth entries are serialized
        XCTAssertTrue(txRep.contains("auth.len:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testSCValTypesTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 53000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

        let boolVal = SCValXDR.bool(true)
        let u32Val = SCValXDR.u32(42)
        let i32Val = SCValXDR.i32(-100)
        let u64Val = SCValXDR.u64(1000000)
        let i64Val = SCValXDR.i64(-2000000)
        let symbolVal = SCValXDR.symbol("test")
        let stringVal = SCValXDR.string("hello world")

        let args = [boolVal, u32Val, i32Val, u64Val, i64Val, symbolVal, stringVal]

        let invokeOperation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: contractId,
            functionName: "test_types",
            functionArguments: args,
            sourceAccountId: nil,
            auth: []
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [invokeOperation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args.len: 7"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[0].type: SCV_BOOL"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[1].type: SCV_U32"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[2].type: SCV_I32"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[3].type: SCV_U64"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[4].type: SCV_I64"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[5].type: SCV_SYMBOL"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[6].type: SCV_STRING"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testLedgerKeysTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 54000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

        let invokeOperation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: contractId,
            functionName: "read_data",
            functionArguments: [],
            sourceAccountId: nil,
            auth: []
        )

        let contractAddress = try SCAddressXDR(contractId: contractId)
        let storageKey = SCValXDR.symbol("balance")

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: storageKey,
            durability: .persistent
        )

        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)

        let resources = SorobanResourcesXDR(
            footprint: LedgerFootprintXDR(readOnly: [ledgerKey], readWrite: []),
            instructions: 50000,
            diskReadBytes: 500,
            writeBytes: 0
        )

        let sorobanData = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 25000
        )

        let preconditions = TransactionPreconditions(ledgerBounds: LedgerBounds(minLedger: 0, maxLedger: 0))

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [invokeOperation],
            memo: Memo.none,
            preconditions: preconditions,
            sorobanTransactionData: sorobanData
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readOnly.len: 1"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readOnly[0].type: CONTRACT_DATA"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readOnly[0].contractData.contract.type: SC_ADDRESS_TYPE_CONTRACT"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readOnly[0].contractData.key.type: SCV_SYMBOL"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readOnly[0].contractData.durability: PERSISTENT"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testUploadContractWasmTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 55000)

        let wasmCode = Data([0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00])

        let uploadOperation = try InvokeHostFunctionOperation.forUploadingContractWasm(
            contractCode: wasmCode,
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [uploadOperation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: INVOKE_HOST_FUNCTION"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.wasm:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testCreateContractTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 56000)

        let wasmId = "7e1c8e5a15a7f50c80f5f48e8e06eb8bb2866e4c2fc1a9e1e5e01b4c1a7a8b3d"
        let address = try SCAddressXDR(accountId: source.accountId)

        let createOperation = try InvokeHostFunctionOperation.forCreatingContract(
            wasmId: wasmId,
            address: address,
            salt: nil,
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [createOperation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: INVOKE_HOST_FUNCTION"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.contractIDPreimage.type: CONTRACT_ID_PREIMAGE_FROM_ADDRESS"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.executable.type: CONTRACT_EXECUTABLE_WASM"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testExtendFootprintTTLOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 57000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let contractAddress = try SCAddressXDR(contractId: contractId)
        let storageKey = SCValXDR.symbol("counter")

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: storageKey,
            durability: .persistent
        )

        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)

        let extendOp = ExtendFootprintTTLOperation(
            ledgersToExpire: 100000,
            sourceAccountId: nil
        )

        let resources = SorobanResourcesXDR(
            footprint: LedgerFootprintXDR(readOnly: [ledgerKey], readWrite: []),
            instructions: 10000,
            diskReadBytes: 100,
            writeBytes: 0
        )

        let sorobanData = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 5000
        )

        let preconditions = TransactionPreconditions(ledgerBounds: LedgerBounds(minLedger: 0, maxLedger: 0))

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [extendOp],
            memo: Memo.none,
            preconditions: preconditions,
            sorobanTransactionData: sorobanData
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: EXTEND_FOOTPRINT_TTL"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.extendFootprintTTLOp.extendTo: 100000"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testRestoreFootprintOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 58000)

        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let contractAddress = try SCAddressXDR(contractId: contractId)
        let storageKey = SCValXDR.symbol("archived_data")

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: storageKey,
            durability: .persistent
        )

        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)

        let restoreOp = RestoreFootprintOperation(sourceAccountId: nil)

        let resources = SorobanResourcesXDR(
            footprint: LedgerFootprintXDR(readOnly: [], readWrite: [ledgerKey]),
            instructions: 15000,
            diskReadBytes: 0,
            writeBytes: 200
        )

        let sorobanData = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 7500
        )

        let preconditions = TransactionPreconditions(ledgerBounds: LedgerBounds(minLedger: 0, maxLedger: 0))

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [restoreOp],
            memo: Memo.none,
            preconditions: preconditions,
            sorobanTransactionData: sorobanData
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: RESTORE_FOOTPRINT"))
        XCTAssertTrue(txRep.contains("tx.sorobanData.resources.footprint.readWrite.len: 1"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }
}
