//
//  XDRTransactionMiscUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Round-trip unit tests for miscellaneous types from Stellar-transaction.x
/// that are NOT covered by Batch 12 (operations) or Batch 13 (results).
///
/// Types tested in this file:
/// - MemoType enum
/// - MemoXDR union (all arms)
/// - PreconditionType enum
/// - OperationID struct (standalone)
/// - RevokeID struct (standalone)
/// - HashIDPreimageContractIDXDR struct (standalone)
/// - HashIDPreimageSorobanAuthorizationXDR struct (standalone)
/// - HashIDPreimageXDR.sorobanAuthorization arm
/// - TransactionSignaturePayload struct
/// - TransactionSignaturePayloadTaggedTransactionXDR union
class XDRTransactionMiscUnitTests: XCTestCase {

    // MARK: - Test Helpers

    private func testContractAddress() -> SCAddressXDR {
        .contract(WrappedData32(Data(repeating: 0xAB, count: 32)))
    }

    private func testAccountAddress() throws -> SCAddressXDR {
        .account(try XDRTestHelpers.publicKey())
    }

    private func testNetworkId() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xCD, count: 32))
    }

    private func testSalt() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xEF, count: 32))
    }

    private func testWasmHash() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xBE, count: 32))
    }

    private func testPoolId() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xBB, count: 32))
    }

    private func makeSimpleSorobanInvocation() throws -> SorobanAuthorizedInvocationXDR {
        let contractAddr = testContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "transfer",
            args: [.u64(500)]
        )
        let func_ = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        return SorobanAuthorizedInvocationXDR(function: func_, subInvocations: [])
    }

    // Build a minimal TransactionXDR for use in TransactionSignaturePayload tests.
    // TransactionXDR is a SKIP_TYPE so we cannot test it directly, but we can
    // use it as a component.
    private func makeMinimalTransactionXDR() throws -> TransactionXDR {
        let pk = try XDRTestHelpers.publicKey()
        let bumpSeqOp = BumpSequenceOperationXDR(bumpTo: 100)
        let muxedAccount: MuxedAccountXDR? = nil
        let op = OperationXDR(sourceAccount: muxedAccount, body: .bumpSequenceOp(bumpSeqOp))
        return TransactionXDR(
            sourceAccount: pk,
            seqNum: 1000,
            cond: .none,
            memo: .none,
            operations: [op],
            maxOperationFee: 100
        )
    }

    // MARK: - MemoType Enum Round-Trip

    func testMemoTypeEnumRoundTrip() throws {
        let allCases: [MemoType] = [
            .MEMO_TYPE_NONE,
            .MEMO_TYPE_TEXT,
            .MEMO_TYPE_ID,
            .MEMO_TYPE_HASH,
            .MEMO_TYPE_RETURN
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(MemoType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    func testMemoTypeRawValues() {
        XCTAssertEqual(MemoType.MEMO_TYPE_NONE.rawValue, 0)
        XCTAssertEqual(MemoType.MEMO_TYPE_TEXT.rawValue, 1)
        XCTAssertEqual(MemoType.MEMO_TYPE_ID.rawValue, 2)
        XCTAssertEqual(MemoType.MEMO_TYPE_HASH.rawValue, 3)
        XCTAssertEqual(MemoType.MEMO_TYPE_RETURN.rawValue, 4)
    }

    // MARK: - MemoXDR Union Round-Trip (all arms)

    func testMemoXDRNoneRoundTrip() throws {
        let original = MemoXDR.none
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), MemoType.MEMO_TYPE_NONE.rawValue)
        if case .none = decoded {
            // success
        } else {
            XCTFail("Expected .none")
        }
    }

    func testMemoXDRTextRoundTrip() throws {
        let original = MemoXDR.text("Hello Stellar")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), MemoType.MEMO_TYPE_TEXT.rawValue)
        if case .text(let text) = decoded {
            XCTAssertEqual(text, "Hello Stellar")
        } else {
            XCTFail("Expected .text")
        }
    }

    func testMemoXDRTextMaxLength() throws {
        // Memo text max length is 28 bytes
        let maxText = String(repeating: "A", count: 28)
        let original = MemoXDR.text(maxText)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        if case .text(let text) = decoded {
            XCTAssertEqual(text, maxText)
            XCTAssertEqual(text.count, 28)
        } else {
            XCTFail("Expected .text")
        }
    }

    func testMemoXDRIdRoundTrip() throws {
        let original = MemoXDR.id(987654321)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), MemoType.MEMO_TYPE_ID.rawValue)
        if case .id(let id) = decoded {
            XCTAssertEqual(id, 987654321)
        } else {
            XCTFail("Expected .id")
        }
    }

    func testMemoXDRIdMaxValue() throws {
        let original = MemoXDR.id(UInt64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        if case .id(let id) = decoded {
            XCTAssertEqual(id, UInt64.max)
        } else {
            XCTFail("Expected .id")
        }
    }

    func testMemoXDRHashRoundTrip() throws {
        let hashData = WrappedData32(Data(repeating: 0x42, count: 32))
        let original = MemoXDR.hash(hashData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), MemoType.MEMO_TYPE_HASH.rawValue)
        if case .hash(let decodedHash) = decoded {
            XCTAssertEqual(decodedHash.wrapped, hashData.wrapped)
        } else {
            XCTFail("Expected .hash")
        }
    }

    func testMemoXDRReturnHashRoundTrip() throws {
        let hashData = WrappedData32(Data(repeating: 0x77, count: 32))
        let original = MemoXDR.returnHash(hashData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), MemoType.MEMO_TYPE_RETURN.rawValue)
        if case .returnHash(let decodedHash) = decoded {
            XCTAssertEqual(decodedHash.wrapped, hashData.wrapped)
        } else {
            XCTFail("Expected .returnHash")
        }
    }

    func testMemoXDRAllArmsByteLevel() throws {
        // Verify byte-level round-trip for all arms
        let memos: [MemoXDR] = [
            .none,
            .text("test"),
            .id(42),
            .hash(WrappedData32(Data(repeating: 0x11, count: 32))),
            .returnHash(WrappedData32(Data(repeating: 0x22, count: 32)))
        ]
        for original in memos {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(MemoXDR.self, data: encoded)
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded, "Byte-level round-trip failed for MemoXDR type \(original.type())")
        }
    }

    // MARK: - PreconditionType Enum Round-Trip

    func testPreconditionTypeEnumRoundTrip() throws {
        let allCases: [PreconditionType] = [.none, .time, .v2]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(PreconditionType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    func testPreconditionTypeRawValues() {
        XCTAssertEqual(PreconditionType.none.rawValue, 0)
        XCTAssertEqual(PreconditionType.time.rawValue, 1)
        XCTAssertEqual(PreconditionType.v2.rawValue, 2)
    }

    // MARK: - OperationID Struct Round-Trip (standalone)

    func testOperationIDStandaloneRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = OperationID(sourceAccount: pk, seqNum: 555888999, opNum: 3)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationID.self, data: encoded)
        XCTAssertEqual(decoded.sourceAccount.accountId, pk.accountId)
        XCTAssertEqual(decoded.seqNum, 555888999)
        XCTAssertEqual(decoded.opNum, 3)
    }

    func testOperationIDBoundaryValues() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = OperationID(sourceAccount: pk, seqNum: Int64.max, opNum: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationID.self, data: encoded)
        XCTAssertEqual(decoded.seqNum, Int64.max)
        XCTAssertEqual(decoded.opNum, UInt32.max)
    }

    func testOperationIDZeroValues() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = OperationID(sourceAccount: pk, seqNum: 0, opNum: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationID.self, data: encoded)
        XCTAssertEqual(decoded.seqNum, 0)
        XCTAssertEqual(decoded.opNum, 0)
    }

    func testOperationIDByteLevel() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = OperationID(sourceAccount: pk, seqNum: 42, opNum: 7)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationID.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - RevokeID Struct Round-Trip (standalone)

    func testRevokeIDStandaloneRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let poolId = testPoolId()
        let original = RevokeID(
            sourceAccount: pk,
            seqNum: 123456789,
            opNum: 5,
            liquidityPoolID: poolId,
            asset: .native
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(RevokeID.self, data: encoded)
        XCTAssertEqual(decoded.sourceAccount.accountId, pk.accountId)
        XCTAssertEqual(decoded.seqNum, 123456789)
        XCTAssertEqual(decoded.opNum, 5)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
        if case .native = decoded.asset {
            // success
        } else {
            XCTFail("Expected native asset")
        }
    }

    func testRevokeIDWithCreditAsset() throws {
        let pk = try XDRTestHelpers.publicKey()
        let poolId = testPoolId()
        let assetCode = WrappedData4(Data("USD".utf8) + Data(repeating: 0, count: 1))
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCode, issuer: pk))
        let original = RevokeID(
            sourceAccount: pk,
            seqNum: 987654321,
            opNum: 2,
            liquidityPoolID: poolId,
            asset: asset
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(RevokeID.self, data: encoded)
        XCTAssertEqual(decoded.seqNum, 987654321)
        XCTAssertEqual(decoded.opNum, 2)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
        if case .alphanum4(let alpha) = decoded.asset {
            XCTAssertEqual(alpha.issuer.accountId, pk.accountId)
        } else {
            XCTFail("Expected alphanum4 asset")
        }
    }

    func testRevokeIDByteLevel() throws {
        let pk = try XDRTestHelpers.publicKey()
        let poolId = testPoolId()
        let original = RevokeID(
            sourceAccount: pk,
            seqNum: 111222333,
            opNum: 1,
            liquidityPoolID: poolId,
            asset: .native
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(RevokeID.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - HashIDPreimageContractIDXDR Struct Round-Trip (standalone)

    func testHashIDPreimageContractIDXDRStandaloneRoundTrip() throws {
        let networkId = testNetworkId()
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let original = HashIDPreimageContractIDXDR(
            networkID: networkId,
            contractIDPreimage: preimage
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageContractIDXDR.self, data: encoded)
        XCTAssertEqual(decoded.networkID.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.contractIDPreimage.type(), ContractIDPreimageType.fromAddress.rawValue)
        if case .fromAddress(let addr) = decoded.contractIDPreimage {
            XCTAssertEqual(addr.salt.wrapped, salt.wrapped)
        } else {
            XCTFail("Expected .fromAddress")
        }
    }

    func testHashIDPreimageContractIDXDRFromAsset() throws {
        let networkId = testNetworkId()
        let preimage = ContractIDPreimageXDR.fromAsset(.native)
        let original = HashIDPreimageContractIDXDR(
            networkID: networkId,
            contractIDPreimage: preimage
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageContractIDXDR.self, data: encoded)
        XCTAssertEqual(decoded.networkID.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.contractIDPreimage.type(), ContractIDPreimageType.fromAsset.rawValue)
    }

    func testHashIDPreimageContractIDXDRByteLevel() throws {
        let networkId = testNetworkId()
        let preimage = ContractIDPreimageXDR.fromAsset(.native)
        let original = HashIDPreimageContractIDXDR(
            networkID: networkId,
            contractIDPreimage: preimage
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageContractIDXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - HashIDPreimageSorobanAuthorizationXDR Struct Round-Trip (standalone)

    func testHashIDPreimageSorobanAuthorizationXDRStandaloneRoundTrip() throws {
        let networkId = testNetworkId()
        let invocation = try makeSimpleSorobanInvocation()
        let original = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: 42,
            signatureExpirationLedger: 500000,
            invocation: invocation
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageSorobanAuthorizationXDR.self, data: encoded)
        XCTAssertEqual(decoded.networkID.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.nonce, 42)
        XCTAssertEqual(decoded.signatureExpirationLedger, 500000)
        if case .contractFn(let fn) = decoded.invocation.function {
            XCTAssertEqual(fn.functionName, "transfer")
        } else {
            XCTFail("Expected .contractFn")
        }
    }

    func testHashIDPreimageSorobanAuthorizationXDRBoundaryValues() throws {
        let networkId = testNetworkId()
        let invocation = try makeSimpleSorobanInvocation()
        let original = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: Int64.max,
            signatureExpirationLedger: UInt32.max,
            invocation: invocation
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageSorobanAuthorizationXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, Int64.max)
        XCTAssertEqual(decoded.signatureExpirationLedger, UInt32.max)
    }

    func testHashIDPreimageSorobanAuthorizationXDRByteLevel() throws {
        let networkId = testNetworkId()
        let invocation = try makeSimpleSorobanInvocation()
        let original = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: 99999,
            signatureExpirationLedger: 300000,
            invocation: invocation
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageSorobanAuthorizationXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - HashIDPreimageXDR.sorobanAuthorization Arm

    func testHashIDPreimageXDRSorobanAuthorizationArm() throws {
        let networkId = testNetworkId()
        let invocation = try makeSimpleSorobanInvocation()
        let sorobanAuth = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: 12345,
            signatureExpirationLedger: 750000,
            invocation: invocation
        )
        let original = HashIDPreimageXDR.sorobanAuthorization(sorobanAuth)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), EnvelopeType.sorobanAuthorization.rawValue)
        if case .sorobanAuthorization(let decodedAuth) = decoded {
            XCTAssertEqual(decodedAuth.nonce, 12345)
            XCTAssertEqual(decodedAuth.signatureExpirationLedger, 750000)
            XCTAssertEqual(decodedAuth.networkID.wrapped, networkId.wrapped)
            if case .contractFn(let fn) = decodedAuth.invocation.function {
                XCTAssertEqual(fn.functionName, "transfer")
            } else {
                XCTFail("Expected .contractFn invocation")
            }
        } else {
            XCTFail("Expected .sorobanAuthorization")
        }
    }

    func testHashIDPreimageXDRSorobanAuthorizationByteLevel() throws {
        let networkId = testNetworkId()
        let invocation = try makeSimpleSorobanInvocation()
        let sorobanAuth = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: 777,
            signatureExpirationLedger: 100000,
            invocation: invocation
        )
        let original = HashIDPreimageXDR.sorobanAuthorization(sorobanAuth)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testHashIDPreimageXDRSorobanAuthorizationBase64() throws {
        let networkId = testNetworkId()
        let invocation = try makeSimpleSorobanInvocation()
        let sorobanAuth = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: 555,
            signatureExpirationLedger: 200000,
            invocation: invocation
        )
        let original = HashIDPreimageXDR.sorobanAuthorization(sorobanAuth)
        guard let base64 = original.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }
        let decoded = try HashIDPreimageXDR(xdr: base64)
        XCTAssertEqual(decoded.type(), EnvelopeType.sorobanAuthorization.rawValue)
        if case .sorobanAuthorization(let decodedAuth) = decoded {
            XCTAssertEqual(decodedAuth.nonce, 555)
            XCTAssertEqual(decodedAuth.signatureExpirationLedger, 200000)
        } else {
            XCTFail("Expected .sorobanAuthorization")
        }
    }

    // MARK: - HashIDPreimageXDR All Arms Comprehensive

    func testHashIDPreimageXDRAllArmsByteLevel() throws {
        let pk = try XDRTestHelpers.publicKey()
        let networkId = testNetworkId()
        let poolId = testPoolId()

        // operationId arm
        let opId = OperationID(sourceAccount: pk, seqNum: 100, opNum: 1)
        let opIdPreimage = HashIDPreimageXDR.operationId(opId)

        // revokeId arm
        let revokeId = RevokeID(sourceAccount: pk, seqNum: 200, opNum: 2, liquidityPoolID: poolId, asset: .native)
        let revokePreimage = HashIDPreimageXDR.revokeId(revokeId)

        // contractID arm
        let contractPreimage = ContractIDPreimageXDR.fromAsset(.native)
        let contractIdStruct = HashIDPreimageContractIDXDR(networkID: networkId, contractIDPreimage: contractPreimage)
        let contractPreimageXDR = HashIDPreimageXDR.contractID(contractIdStruct)

        // sorobanAuthorization arm
        let invocation = try makeSimpleSorobanInvocation()
        let sorobanAuth = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId, nonce: 42, signatureExpirationLedger: 100, invocation: invocation
        )
        let sorobanPreimage = HashIDPreimageXDR.sorobanAuthorization(sorobanAuth)

        let allPreimages: [HashIDPreimageXDR] = [opIdPreimage, revokePreimage, contractPreimageXDR, sorobanPreimage]
        let expectedTypes: [Int32] = [
            EnvelopeType.opId.rawValue,
            EnvelopeType.poolRevokeOpId.rawValue,
            EnvelopeType.contractId.rawValue,
            EnvelopeType.sorobanAuthorization.rawValue
        ]

        for (idx, original) in allPreimages.enumerated() {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded, "Byte-level round-trip failed for arm \(idx)")
            XCTAssertEqual(decoded.type(), expectedTypes[idx], "Type mismatch for arm \(idx)")
        }
    }

    // MARK: - TransactionSignaturePayloadTaggedTransactionXDR Union Round-Trip

    func testTransactionSignaturePayloadTaggedTransactionXDRTxArm() throws {
        let tx = try makeMinimalTransactionXDR()
        let original = TransactionSignaturePayloadTaggedTransactionXDR.tx(tx)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayloadTaggedTransactionXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), EnvelopeType.tx.rawValue)
        if case .tx(let decodedTx) = decoded {
            XCTAssertEqual(decodedTx.seqNum, 1000)
            XCTAssertEqual(decodedTx.fee, 100)
            XCTAssertEqual(decodedTx.operations.count, 1)
        } else {
            XCTFail("Expected .tx arm")
        }
    }

    func testTransactionSignaturePayloadTaggedTransactionXDRTxByteLevel() throws {
        let tx = try makeMinimalTransactionXDR()
        let original = TransactionSignaturePayloadTaggedTransactionXDR.tx(tx)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayloadTaggedTransactionXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - TransactionSignaturePayload Struct Round-Trip

    func testTransactionSignaturePayloadWithTxArm() throws {
        let networkId = testNetworkId()
        let tx = try makeMinimalTransactionXDR()
        let taggedTx = TransactionSignaturePayloadTaggedTransactionXDR.tx(tx)
        let original = TransactionSignaturePayload(
            networkId: networkId,
            taggedTransaction: taggedTx
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayload.self, data: encoded)
        XCTAssertEqual(decoded.networkId.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.taggedTransaction.type(), EnvelopeType.tx.rawValue)
        if case .tx(let decodedTx) = decoded.taggedTransaction {
            XCTAssertEqual(decodedTx.seqNum, 1000)
            XCTAssertEqual(decodedTx.fee, 100)
        } else {
            XCTFail("Expected .tx tagged transaction")
        }
    }

    func testTransactionSignaturePayloadByteLevel() throws {
        let networkId = testNetworkId()
        let tx = try makeMinimalTransactionXDR()
        let taggedTx = TransactionSignaturePayloadTaggedTransactionXDR.tx(tx)
        let original = TransactionSignaturePayload(
            networkId: networkId,
            taggedTransaction: taggedTx
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayload.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testTransactionSignaturePayloadWithDifferentNetworkId() throws {
        let networkId = WrappedData32(Data(repeating: 0xFF, count: 32))
        let tx = try makeMinimalTransactionXDR()
        let taggedTx = TransactionSignaturePayloadTaggedTransactionXDR.tx(tx)
        let original = TransactionSignaturePayload(
            networkId: networkId,
            taggedTransaction: taggedTx
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayload.self, data: encoded)
        XCTAssertEqual(decoded.networkId.wrapped, Data(repeating: 0xFF, count: 32))
    }

    // MARK: - TransactionSignaturePayload feeBump Arm

    func testTransactionSignaturePayloadFeeBumpArm() throws {
        // Build a minimal FeeBumpTransactionXDR
        let pk = try XDRTestHelpers.publicKey()
        let feeSourceMuxed = MuxedAccountXDR.ed25519(pk.bytes)
        let innerTx = try makeMinimalTransactionXDR()
        let innerEnvelope = TransactionV1EnvelopeXDR(tx: innerTx, signatures: [])
        let innerTxWrapped = FeeBumpTransactionXDRInnerTxXDR.v1(innerEnvelope)
        let feeBumpTx = FeeBumpTransactionXDR(
            sourceAccount: feeSourceMuxed,
            innerTx: innerTxWrapped,
            fee: 200
        )
        let taggedTx = TransactionSignaturePayloadTaggedTransactionXDR.feeBump(feeBumpTx)
        let networkId = testNetworkId()
        let original = TransactionSignaturePayload(
            networkId: networkId,
            taggedTransaction: taggedTx
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayload.self, data: encoded)
        XCTAssertEqual(decoded.networkId.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.taggedTransaction.type(), EnvelopeType.txFeeBump.rawValue)
        if case .feeBump(let decodedFeeBump) = decoded.taggedTransaction {
            XCTAssertEqual(decodedFeeBump.fee, 200)
        } else {
            XCTFail("Expected .feeBump tagged transaction")
        }
    }

    func testTransactionSignaturePayloadFeeBumpByteLevel() throws {
        let pk = try XDRTestHelpers.publicKey()
        let feeSourceMuxed = MuxedAccountXDR.ed25519(pk.bytes)
        let innerTx = try makeMinimalTransactionXDR()
        let innerEnvelope = TransactionV1EnvelopeXDR(tx: innerTx, signatures: [])
        let innerTxWrapped = FeeBumpTransactionXDRInnerTxXDR.v1(innerEnvelope)
        let feeBumpTx = FeeBumpTransactionXDR(
            sourceAccount: feeSourceMuxed,
            innerTx: innerTxWrapped,
            fee: 300
        )
        let taggedTx = TransactionSignaturePayloadTaggedTransactionXDR.feeBump(feeBumpTx)
        let networkId = testNetworkId()
        let original = TransactionSignaturePayload(
            networkId: networkId,
            taggedTransaction: taggedTx
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSignaturePayload.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - EnvelopeType Enum Extended Round-Trip

    func testEnvelopeTypeAllValuesRoundTrip() throws {
        let allCases: [EnvelopeType] = [
            .txV0, .scp, .tx, .auth, .scpvalue,
            .txFeeBump, .opId, .poolRevokeOpId,
            .contractId, .sorobanAuthorization
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(EnvelopeType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    func testEnvelopeTypeRawValuesComprehensive() {
        XCTAssertEqual(EnvelopeType.txV0.rawValue, 0)
        XCTAssertEqual(EnvelopeType.scp.rawValue, 1)
        XCTAssertEqual(EnvelopeType.tx.rawValue, 2)
        XCTAssertEqual(EnvelopeType.auth.rawValue, 3)
        XCTAssertEqual(EnvelopeType.scpvalue.rawValue, 4)
        XCTAssertEqual(EnvelopeType.txFeeBump.rawValue, 5)
        XCTAssertEqual(EnvelopeType.opId.rawValue, 6)
        XCTAssertEqual(EnvelopeType.poolRevokeOpId.rawValue, 7)
        XCTAssertEqual(EnvelopeType.contractId.rawValue, 8)
        XCTAssertEqual(EnvelopeType.sorobanAuthorization.rawValue, 9)
    }

    // MARK: - HashIDPreimageXDR with nested SubInvocations

    func testHashIDPreimageSorobanWithNestedSubInvocations() throws {
        let networkId = testNetworkId()
        let contractAddr = testContractAddress()

        // Create child invocation
        let childInvokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "approve",
            args: [.u64(100)]
        )
        let childInvocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(childInvokeArgs),
            subInvocations: []
        )

        // Create parent invocation with child
        let parentInvokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "swap",
            args: [.u64(1000), .bool(true)]
        )
        let parentInvocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(parentInvokeArgs),
            subInvocations: [childInvocation]
        )

        let sorobanAuth = HashIDPreimageSorobanAuthorizationXDR(
            networkID: networkId,
            nonce: 88888,
            signatureExpirationLedger: 400000,
            invocation: parentInvocation
        )
        let original = HashIDPreimageXDR.sorobanAuthorization(sorobanAuth)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)

        if case .sorobanAuthorization(let decodedAuth) = decoded {
            XCTAssertEqual(decodedAuth.nonce, 88888)
            XCTAssertEqual(decodedAuth.signatureExpirationLedger, 400000)
            // Check parent invocation
            if case .contractFn(let parentFn) = decodedAuth.invocation.function {
                XCTAssertEqual(parentFn.functionName, "swap")
                XCTAssertEqual(parentFn.args.count, 2)
            } else {
                XCTFail("Expected .contractFn for parent")
            }
            // Check child invocation
            XCTAssertEqual(decodedAuth.invocation.subInvocations.count, 1)
            if case .contractFn(let childFn) = decodedAuth.invocation.subInvocations[0].function {
                XCTAssertEqual(childFn.functionName, "approve")
            } else {
                XCTFail("Expected .contractFn for child")
            }
        } else {
            XCTFail("Expected .sorobanAuthorization")
        }
    }

    // MARK: - MemoXDR Base64 Round-Trip

    func testMemoXDRBase64RoundTrip() throws {
        // Test all arms via base64 encoding
        let memos: [MemoXDR] = [
            .none,
            .text("base64 test"),
            .id(42424242),
            .hash(WrappedData32(Data(repeating: 0x33, count: 32))),
            .returnHash(WrappedData32(Data(repeating: 0x44, count: 32)))
        ]
        for original in memos {
            guard let base64 = original.xdrEncoded else {
                XCTFail("Failed to encode MemoXDR to base64 for type \(original.type())")
                continue
            }
            let decoded = try MemoXDR(xdr: base64)
            XCTAssertEqual(decoded.type(), original.type())
        }
    }

    // MARK: - OperationID Base64 Round-Trip

    func testOperationIDBase64RoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = OperationID(sourceAccount: pk, seqNum: 999, opNum: 10)
        guard let base64 = original.xdrEncoded else {
            XCTFail("Failed to encode OperationID to base64")
            return
        }
        let decoded = try OperationID(xdr: base64)
        XCTAssertEqual(decoded.sourceAccount.accountId, pk.accountId)
        XCTAssertEqual(decoded.seqNum, 999)
        XCTAssertEqual(decoded.opNum, 10)
    }

    // MARK: - RevokeID Base64 Round-Trip

    func testRevokeIDBase64RoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let poolId = testPoolId()
        let original = RevokeID(
            sourceAccount: pk,
            seqNum: 444,
            opNum: 3,
            liquidityPoolID: poolId,
            asset: .native
        )
        guard let base64 = original.xdrEncoded else {
            XCTFail("Failed to encode RevokeID to base64")
            return
        }
        let decoded = try RevokeID(xdr: base64)
        XCTAssertEqual(decoded.seqNum, 444)
        XCTAssertEqual(decoded.opNum, 3)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
    }

    // MARK: - TransactionSignaturePayload Base64 Round-Trip

    func testTransactionSignaturePayloadBase64RoundTrip() throws {
        let networkId = testNetworkId()
        let tx = try makeMinimalTransactionXDR()
        let taggedTx = TransactionSignaturePayloadTaggedTransactionXDR.tx(tx)
        let original = TransactionSignaturePayload(
            networkId: networkId,
            taggedTransaction: taggedTx
        )
        guard let base64 = original.xdrEncoded else {
            XCTFail("Failed to encode TransactionSignaturePayload to base64")
            return
        }
        let decoded = try TransactionSignaturePayload(xdr: base64)
        XCTAssertEqual(decoded.networkId.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.taggedTransaction.type(), EnvelopeType.tx.rawValue)
    }

    // MARK: - HashIDPreimageContractIDXDR Base64 Round-Trip

    func testHashIDPreimageContractIDXDRBase64RoundTrip() throws {
        let networkId = testNetworkId()
        let preimage = ContractIDPreimageXDR.fromAsset(.native)
        let original = HashIDPreimageContractIDXDR(
            networkID: networkId,
            contractIDPreimage: preimage
        )
        guard let base64 = original.xdrEncoded else {
            XCTFail("Failed to encode HashIDPreimageContractIDXDR to base64")
            return
        }
        let decoded = try HashIDPreimageContractIDXDR(xdr: base64)
        XCTAssertEqual(decoded.networkID.wrapped, networkId.wrapped)
        XCTAssertEqual(decoded.contractIDPreimage.type(), ContractIDPreimageType.fromAsset.rawValue)
    }
}
