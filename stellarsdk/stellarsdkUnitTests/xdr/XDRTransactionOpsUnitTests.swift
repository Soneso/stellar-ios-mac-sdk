//
//  XDRTransactionOpsUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDRTransactionOpsUnitTests: XCTestCase {

    // MARK: - Helpers

    private func testContractAddress() -> SCAddressXDR {
        .contract(WrappedData32(Data(repeating: 0xAB, count: 32)))
    }

    private func testAccountAddress() throws -> SCAddressXDR {
        .account(try XDRTestHelpers.publicKey())
    }

    private func testSalt() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xEF, count: 32))
    }

    private func testWasmHash() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xCD, count: 32))
    }

    private func testPoolId() -> WrappedData32 {
        WrappedData32(Data(repeating: 0xBB, count: 32))
    }

    // MARK: - OperationType Enum Round-Trip

    func testOperationTypeEnumRoundTrip() throws {
        let allCases: [OperationType] = [
            .accountCreated, .payment, .pathPayment, .manageSellOffer,
            .createPassiveSellOffer, .setOptions, .changeTrust, .allowTrust,
            .accountMerge, .inflation, .manageData, .bumpSequence,
            .manageBuyOffer, .pathPaymentStrictSend, .createClaimableBalance,
            .claimClaimableBalance, .beginSponsoringFutureReserves,
            .endSponsoringFutureReserves, .revokeSponsorship, .clawback,
            .clawbackClaimableBalance, .setTrustLineFlags, .liquidityPoolDeposit,
            .liquidityPoolWithdraw, .invokeHostFunction, .extendFootprintTTL,
            .restoreFootprint
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(OperationType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - HostFunctionType Enum Round-Trip

    func testHostFunctionTypeEnumRoundTrip() throws {
        let allCases: [HostFunctionType] = [
            .invokeContract, .createContract, .uploadContractWasm, .createContractV2
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(HostFunctionType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - ContractIDPreimageType Enum Round-Trip

    func testContractIDPreimageTypeEnumRoundTrip() throws {
        let allCases: [ContractIDPreimageType] = [.fromAddress, .fromAsset]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(ContractIDPreimageType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - SorobanAuthorizedFunctionType Enum Round-Trip

    func testSorobanAuthorizedFunctionTypeEnumRoundTrip() throws {
        let allCases: [SorobanAuthorizedFunctionType] = [
            .contractFn, .createContractHostFn, .createContractV2HostFn
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SorobanAuthorizedFunctionType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - SorobanCredentialsType Enum Round-Trip

    func testSorobanCredentialsTypeEnumRoundTrip() throws {
        let allCases: [SorobanCredentialsType] = [.sourceAccount, .address]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SorobanCredentialsType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - RevokeSponsorshipType Enum Round-Trip

    func testRevokeSponsorshipTypeEnumRoundTrip() throws {
        let allCases: [RevokeSponsorshipType] = [
            .revokeSponsorshipLedgerEntry, .revokeSponsorshipSignerEntry
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(RevokeSponsorshipType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - BumpSequenceOperationXDR Struct Round-Trip

    func testBumpSequenceOperationXDRRoundTrip() throws {
        let original = BumpSequenceOperationXDR(bumpTo: 987654321)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BumpSequenceOperationXDR.self, data: encoded)
        XCTAssertEqual(decoded.bumpTo, 987654321)
    }

    func testBumpSequenceOperationXDRMaxValue() throws {
        let original = BumpSequenceOperationXDR(bumpTo: Int64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BumpSequenceOperationXDR.self, data: encoded)
        XCTAssertEqual(decoded.bumpTo, Int64.max)
    }

    // MARK: - ManageDataOperationXDR Struct Round-Trip

    func testManageDataOperationXDRWithValue() throws {
        let dataValue: Data = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let original = ManageDataOperationXDR(dataName: "test_entry", dataValue: dataValue)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ManageDataOperationXDR.self, data: encoded)
        XCTAssertEqual(decoded.dataName, "test_entry")
        XCTAssertEqual(decoded.dataValue, dataValue)
    }

    func testManageDataOperationXDRWithNilValue() throws {
        let original = ManageDataOperationXDR(dataName: "delete_entry", dataValue: nil)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ManageDataOperationXDR.self, data: encoded)
        XCTAssertEqual(decoded.dataName, "delete_entry")
        XCTAssertNil(decoded.dataValue)
    }

    // MARK: - BeginSponsoringFutureReservesOpXDR Struct Round-Trip

    func testBeginSponsoringFutureReservesOpXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = BeginSponsoringFutureReservesOpXDR(sponsoredId: pk)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BeginSponsoringFutureReservesOpXDR.self, data: encoded)
        XCTAssertEqual(decoded.sponsoredId.accountId, pk.accountId)
    }

    // MARK: - LiquidityPoolDepositOpXDR Struct Round-Trip

    func testLiquidityPoolDepositOpXDRRoundTrip() throws {
        let poolId = testPoolId()
        let minPrice = PriceXDR(n: 1, d: 2)
        let maxPrice = PriceXDR(n: 3, d: 1)
        let original = LiquidityPoolDepositOpXDR(
            liquidityPoolID: poolId,
            maxAmountA: 50000000,
            maxAmountB: 100000000,
            minPrice: minPrice,
            maxPrice: maxPrice
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolDepositOpXDR.self, data: encoded)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
        XCTAssertEqual(decoded.maxAmountA, 50000000)
        XCTAssertEqual(decoded.maxAmountB, 100000000)
        XCTAssertEqual(decoded.minPrice.n, 1)
        XCTAssertEqual(decoded.minPrice.d, 2)
        XCTAssertEqual(decoded.maxPrice.n, 3)
        XCTAssertEqual(decoded.maxPrice.d, 1)
    }

    // MARK: - LiquidityPoolWithdrawOpXDR Struct Round-Trip

    func testLiquidityPoolWithdrawOpXDRRoundTrip() throws {
        let poolId = testPoolId()
        let original = LiquidityPoolWithdrawOpXDR(
            liquidityPoolID: poolId,
            amount: 25000000,
            minAmountA: 10000000,
            minAmountB: 12000000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolWithdrawOpXDR.self, data: encoded)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
        XCTAssertEqual(decoded.amount, 25000000)
        XCTAssertEqual(decoded.minAmountA, 10000000)
        XCTAssertEqual(decoded.minAmountB, 12000000)
    }

    // MARK: - ClawbackClaimableBalanceOpXDR Struct Round-Trip (standalone)

    func testClawbackClaimableBalanceOpXDRStandaloneRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let balanceId = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(hash)
        let original = ClawbackClaimableBalanceOpXDR(claimableBalanceID: balanceId)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceOpXDR.self, data: encoded)
        if case .claimableBalanceIDTypeV0(let decodedHash) = decoded.claimableBalanceID {
            XCTAssertEqual(decodedHash.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected claimableBalanceIDTypeV0")
        }
    }

    // MARK: - ContractIDPreimageXDR Union Round-Trip

    func testContractIDPreimageXDRFromAddressRoundTrip() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let fromAddr = ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        let original = ContractIDPreimageXDR.fromAddress(fromAddr)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractIDPreimageXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ContractIDPreimageType.fromAddress.rawValue)
        if case .fromAddress(let decodedAddr) = decoded {
            XCTAssertEqual(decodedAddr.salt.wrapped, salt.wrapped)
        } else {
            XCTFail("Expected .fromAddress")
        }
    }

    func testContractIDPreimageXDRFromAssetRoundTrip() throws {
        let original = ContractIDPreimageXDR.fromAsset(.native)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractIDPreimageXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ContractIDPreimageType.fromAsset.rawValue)
        if case .fromAsset(let asset) = decoded {
            if case .native = asset {
                // success
            } else {
                XCTFail("Expected native asset")
            }
        } else {
            XCTFail("Expected .fromAsset")
        }
    }

    // MARK: - ContractIDPreimageFromAddressXDR Struct Round-Trip

    func testContractIDPreimageFromAddressXDRRoundTrip() throws {
        let address = testContractAddress()
        let salt = testSalt()
        let original = ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractIDPreimageFromAddressXDR.self, data: encoded)
        XCTAssertEqual(decoded.salt.wrapped, salt.wrapped)
        if case .contract(let contractId) = decoded.address {
            XCTAssertEqual(contractId.wrapped, Data(repeating: 0xAB, count: 32))
        } else {
            XCTFail("Expected contract address")
        }
    }

    // MARK: - CreateContractArgsXDR Struct Round-Trip

    func testCreateContractArgsXDRRoundTrip() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let wasmHash = testWasmHash()
        let executable = ContractExecutableXDR.wasm(wasmHash)
        let original = CreateContractArgsXDR(
            contractIDPreimage: preimage,
            executable: executable
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CreateContractArgsXDR.self, data: encoded)
        XCTAssertEqual(decoded.contractIDPreimage.type(), ContractIDPreimageType.fromAddress.rawValue)
        if let wasm = decoded.executable.wasm {
            XCTAssertEqual(wasm.wrapped, wasmHash.wrapped)
        } else {
            XCTFail("Expected wasm executable")
        }
    }

    // MARK: - CreateContractV2ArgsXDR Struct Round-Trip

    func testCreateContractV2ArgsXDRRoundTrip() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let wasmHash = testWasmHash()
        let executable = ContractExecutableXDR.wasm(wasmHash)
        let constructorArgs: [SCValXDR] = [.u32(100), .bool(true)]
        let original = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: constructorArgs
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CreateContractV2ArgsXDR.self, data: encoded)
        XCTAssertEqual(decoded.contractIDPreimage.type(), ContractIDPreimageType.fromAddress.rawValue)
        XCTAssertEqual(decoded.constructorArgs.count, 2)
    }

    // MARK: - InvokeContractArgsXDR Struct Round-Trip (standalone)

    func testInvokeContractArgsXDRRoundTrip() throws {
        let contractAddr = testContractAddress()
        let original = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "transfer",
            args: [.u64(999), .bool(false)]
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(InvokeContractArgsXDR.self, data: encoded)
        XCTAssertEqual(decoded.functionName, "transfer")
        XCTAssertEqual(decoded.args.count, 2)
    }

    // MARK: - SorobanAddressCredentialsXDR Struct Round-Trip

    func testSorobanAddressCredentialsXDRRoundTrip() throws {
        let address = try testAccountAddress()
        let original = SorobanAddressCredentialsXDR(
            address: address,
            nonce: 123456789,
            signatureExpirationLedger: 500000,
            signature: .u32(42)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAddressCredentialsXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 123456789)
        XCTAssertEqual(decoded.signatureExpirationLedger, 500000)
    }

    // MARK: - SorobanCredentialsXDR Union - Address Arm

    func testSorobanCredentialsXDRAddressArmRoundTrip() throws {
        let address = try testAccountAddress()
        let addrCreds = SorobanAddressCredentialsXDR(
            address: address,
            nonce: 77777,
            signatureExpirationLedger: 300000,
            signature: .bool(true)
        )
        let original = SorobanCredentialsXDR.address(addrCreds)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanCredentialsXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SorobanCredentialsType.address.rawValue)
        if case .address(let creds) = decoded {
            XCTAssertEqual(creds.nonce, 77777)
            XCTAssertEqual(creds.signatureExpirationLedger, 300000)
        } else {
            XCTFail("Expected .address")
        }
    }

    // MARK: - SorobanAuthorizedFunctionXDR - createContractHostFn Arm

    func testSorobanAuthorizedFunctionXDRCreateContractHostFnRoundTrip() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let executable = ContractExecutableXDR.wasm(testWasmHash())
        let args = CreateContractArgsXDR(
            contractIDPreimage: preimage,
            executable: executable
        )
        let original = SorobanAuthorizedFunctionXDR.createContractHostFn(args)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAuthorizedFunctionXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SorobanAuthorizedFunctionType.createContractHostFn.rawValue)
        if case .createContractHostFn(let decodedArgs) = decoded {
            XCTAssertEqual(decodedArgs.contractIDPreimage.type(), ContractIDPreimageType.fromAddress.rawValue)
        } else {
            XCTFail("Expected .createContractHostFn")
        }
    }

    // MARK: - SorobanAuthorizedFunctionXDR - createContractV2HostFn Arm

    func testSorobanAuthorizedFunctionXDRCreateContractV2HostFnRoundTrip() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let executable = ContractExecutableXDR.wasm(testWasmHash())
        let args = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: [.u32(7)]
        )
        let original = SorobanAuthorizedFunctionXDR.createContractV2HostFn(args)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAuthorizedFunctionXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SorobanAuthorizedFunctionType.createContractV2HostFn.rawValue)
        if case .createContractV2HostFn(let decodedArgs) = decoded {
            XCTAssertEqual(decodedArgs.constructorArgs.count, 1)
        } else {
            XCTFail("Expected .createContractV2HostFn")
        }
    }

    // MARK: - SorobanAuthorizedInvocationXDR with SubInvocations

    func testSorobanAuthorizedInvocationXDRWithSubInvocations() throws {
        let contractAddr = testContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "approve",
            args: [.u64(500)]
        )
        let childFunc = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let childInvocation = SorobanAuthorizedInvocationXDR(
            function: childFunc,
            subInvocations: []
        )

        let parentFunc = SorobanAuthorizedFunctionXDR.contractFn(
            InvokeContractArgsXDR(
                contractAddress: contractAddr,
                functionName: "swap",
                args: [.u64(1000)]
            )
        )
        let original = SorobanAuthorizedInvocationXDR(
            function: parentFunc,
            subInvocations: [childInvocation]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAuthorizedInvocationXDR.self, data: encoded)

        if case .contractFn(let fn) = decoded.function {
            XCTAssertEqual(fn.functionName, "swap")
        } else {
            XCTFail("Expected .contractFn for parent")
        }
        XCTAssertEqual(decoded.subInvocations.count, 1)
        if case .contractFn(let subFn) = decoded.subInvocations[0].function {
            XCTAssertEqual(subFn.functionName, "approve")
        } else {
            XCTFail("Expected .contractFn for child")
        }
    }

    // MARK: - SorobanAuthorizationEntryXDR with Address Credentials

    func testSorobanAuthorizationEntryXDRWithAddressCredentials() throws {
        let accountAddr = try testAccountAddress()
        let addrCreds = SorobanAddressCredentialsXDR(
            address: accountAddr,
            nonce: 42,
            signatureExpirationLedger: 100000,
            signature: .u32(1)
        )
        let credentials = SorobanCredentialsXDR.address(addrCreds)

        let contractAddr = testContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "mint",
            args: []
        )
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(invokeArgs),
            subInvocations: []
        )

        let original = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAuthorizationEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.credentials.type(), SorobanCredentialsType.address.rawValue)
        if case .address(let creds) = decoded.credentials {
            XCTAssertEqual(creds.nonce, 42)
            XCTAssertEqual(creds.signatureExpirationLedger, 100000)
        } else {
            XCTFail("Expected .address credentials")
        }
        if case .contractFn(let fn) = decoded.rootInvocation.function {
            XCTAssertEqual(fn.functionName, "mint")
        } else {
            XCTFail("Expected .contractFn root invocation")
        }
    }

    // MARK: - HostFunctionXDR - createContractV2 Arm

    func testHostFunctionXDRCreateContractV2RoundTrip() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let executable = ContractExecutableXDR.wasm(testWasmHash())
        let args = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: [.u32(55), .bool(false)]
        )
        let original = HostFunctionXDR.createContractV2(args)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), HostFunctionType.createContractV2.rawValue)
    }

    // MARK: - ChangeTrustAssetXDR - poolShare Arm

    func testChangeTrustAssetXDRPoolShareRoundTrip() throws {
        let issuerPk = try XDRTestHelpers.publicKey()
        let assetA = AssetXDR.native
        let assetCodeData = Data("USDC".utf8)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let assetB = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPk))

        let constantProductParams = LiquidityPoolConstantProductParametersXDR(
            assetA: assetA,
            assetB: assetB,
            fee: 30
        )
        let poolParams = LiquidityPoolParametersXDR.constantProduct(constantProductParams)
        let original = ChangeTrustAssetXDR.poolShare(poolParams)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ChangeTrustAssetXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), AssetType.poolShare.rawValue)
        if case .poolShare(let params) = decoded {
            if case .constantProduct(let cp) = params {
                XCTAssertEqual(cp.fee, 30)
            } else {
                XCTFail("Expected .constantProduct params")
            }
        } else {
            XCTFail("Expected .poolShare")
        }
    }

    func testChangeTrustAssetXDRNativeRoundTrip() throws {
        let original = ChangeTrustAssetXDR.native
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ChangeTrustAssetXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), AssetType.native.rawValue)
    }

    func testChangeTrustAssetXDRAlphanum4RoundTrip() throws {
        let issuerPk = try XDRTestHelpers.publicKey()
        let assetCodeData = Data("EUR".utf8) + Data(repeating: 0, count: 1)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let alpha4 = Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPk)
        let original = ChangeTrustAssetXDR.alphanum4(alpha4)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ChangeTrustAssetXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), AssetType.creditAlphanum4.rawValue)
        if case .alphanum4(let decodedAlpha) = decoded {
            XCTAssertEqual(decodedAlpha.issuer.accountId, issuerPk.accountId)
        } else {
            XCTFail("Expected .alphanum4")
        }
    }

    // MARK: - LiquidityPoolParametersXDR Union Round-Trip

    func testLiquidityPoolParametersXDRRoundTrip() throws {
        let issuerPk = try XDRTestHelpers.publicKey()
        let assetA = AssetXDR.native
        let assetCodeData = Data("BTC".utf8) + Data(repeating: 0, count: 1)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let assetB = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPk))

        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: assetA,
            assetB: assetB,
            fee: 30
        )
        let original = LiquidityPoolParametersXDR.constantProduct(params)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolParametersXDR.self, data: encoded)
        if case .constantProduct(let cp) = decoded {
            XCTAssertEqual(cp.fee, 30)
        } else {
            XCTFail("Expected .constantProduct")
        }
    }

    // MARK: - RevokeSponsorshipSignerXDR Struct Round-Trip (standalone)

    func testRevokeSponsorshipSignerXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let signerKey = SignerKeyXDR.ed25519(XDRTestHelpers.wrappedData32())
        let original = RevokeSponsorshipSignerXDR(accountID: pk, signerKey: signerKey)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipSignerXDR.self, data: encoded)
        XCTAssertEqual(decoded.accountID.accountId, pk.accountId)
        if case .ed25519(let decodedKey) = decoded.signerKey {
            XCTAssertEqual(decodedKey.wrapped, XDRTestHelpers.wrappedData32().wrapped)
        } else {
            XCTFail("Expected .ed25519 signer key")
        }
    }

    // MARK: - SorobanResourcesExtV0 Struct Round-Trip

    func testSorobanResourcesExtV0RoundTrip() throws {
        let original = SorobanResourcesExtV0(archivedSorobanEntries: [0, 3, 7])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanResourcesExtV0.self, data: encoded)
        XCTAssertEqual(decoded.archivedSorobanEntries, [0, 3, 7])
    }

    func testSorobanResourcesExtV0EmptyRoundTrip() throws {
        let original = SorobanResourcesExtV0(archivedSorobanEntries: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanResourcesExtV0.self, data: encoded)
        XCTAssertEqual(decoded.archivedSorobanEntries, [])
    }

    // MARK: - SorobanResourcesExt Union Round-Trip

    func testSorobanResourcesExtVoidRoundTrip() throws {
        let original = SorobanResourcesExt.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanResourcesExt.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
    }

    func testSorobanResourcesExtWithExtV0RoundTrip() throws {
        let extV0 = SorobanResourcesExtV0(archivedSorobanEntries: [1, 5])
        let original = SorobanResourcesExt.resourceExt(extV0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanResourcesExt.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .resourceExt(let ext) = decoded {
            XCTAssertEqual(ext.archivedSorobanEntries, [1, 5])
        } else {
            XCTFail("Expected .resourceExt")
        }
    }

    // MARK: - SorobanResourcesXDR Struct Round-Trip

    func testSorobanResourcesXDRRoundTrip() throws {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let original = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 1000000,
            diskReadBytes: 2048,
            writeBytes: 4096
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanResourcesXDR.self, data: encoded)
        XCTAssertEqual(decoded.instructions, 1000000)
        XCTAssertEqual(decoded.diskReadBytes, 2048)
        XCTAssertEqual(decoded.writeBytes, 4096)
        XCTAssertEqual(decoded.footprint.readOnly.count, 0)
        XCTAssertEqual(decoded.footprint.readWrite.count, 0)
    }

    func testSorobanResourcesXDRWithFootprint() throws {
        let key = XDRTestHelpers.ledgerKey()
        let footprint = LedgerFootprintXDR(readOnly: [key], readWrite: [])
        let original = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 500000,
            diskReadBytes: 1024,
            writeBytes: 512
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanResourcesXDR.self, data: encoded)
        XCTAssertEqual(decoded.instructions, 500000)
        XCTAssertEqual(decoded.footprint.readOnly.count, 1)
    }

    // MARK: - SorobanTransactionDataXDR Struct Round-Trip

    func testSorobanTransactionDataXDRRoundTrip() throws {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let resources = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 2000000,
            diskReadBytes: 8192,
            writeBytes: 4096
        )
        let original = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 100000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.resources.instructions, 2000000)
        XCTAssertEqual(decoded.resources.diskReadBytes, 8192)
        XCTAssertEqual(decoded.resources.writeBytes, 4096)
        XCTAssertEqual(decoded.resourceFee, 100000)
    }

    func testSorobanTransactionDataXDRWithResourceExt() throws {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let resources = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 3000000,
            diskReadBytes: 1024,
            writeBytes: 2048
        )
        let extV0 = SorobanResourcesExtV0(archivedSorobanEntries: [2, 4])
        let original = SorobanTransactionDataXDR(
            ext: .resourceExt(extV0),
            resources: resources,
            resourceFee: 250000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.ext.type(), 1)
        if case .resourceExt(let decodedExt) = decoded.ext {
            XCTAssertEqual(decodedExt.archivedSorobanEntries, [2, 4])
        } else {
            XCTFail("Expected .resourceExt")
        }
        XCTAssertEqual(decoded.resources.instructions, 3000000)
        XCTAssertEqual(decoded.resourceFee, 250000)
    }

    // MARK: - HostFunctionXDR - All Arms Byte-Level Round-Trip

    func testHostFunctionXDRInvokeContractByteLevel() throws {
        let contractAddr = testContractAddress()
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddr,
            functionName: "balance",
            args: [.u64(42)]
        )
        let original = HostFunctionXDR.invokeContract(invokeArgs)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testHostFunctionXDRCreateContractByteLevel() throws {
        let preimage = ContractIDPreimageXDR.fromAsset(.native)
        let executable = ContractExecutableXDR.token
        let args = CreateContractArgsXDR(
            contractIDPreimage: preimage,
            executable: executable
        )
        let original = HostFunctionXDR.createContract(args)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testHostFunctionXDRUploadWasmByteLevel() throws {
        let wasm = Data([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00])
        let original = HostFunctionXDR.uploadContractWasm(wasm)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HostFunctionXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    // MARK: - InvokeHostFunctionOpXDR with createContractV2 host function

    func testInvokeHostFunctionOpXDRWithCreateContractV2() throws {
        let address = try testAccountAddress()
        let salt = testSalt()
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(address: address, salt: salt)
        )
        let executable = ContractExecutableXDR.wasm(testWasmHash())
        let v2Args = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: [.u32(10)]
        )
        let hostFunction = HostFunctionXDR.createContractV2(v2Args)
        let invokeOp = InvokeHostFunctionOpXDR(
            hostFunction: hostFunction,
            auth: []
        )
        let encoded = try XDREncoder.encode(invokeOp)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionOpXDR.self, data: encoded)
        XCTAssertEqual(decoded.hostFunction.type(), HostFunctionType.createContractV2.rawValue)
        XCTAssertEqual(decoded.auth.count, 0)
    }

    // MARK: - ContractIDPreimageXDR fromAsset with credit asset

    func testContractIDPreimageXDRFromCreditAsset() throws {
        let issuerPk = try XDRTestHelpers.publicKey()
        let assetCodeData = Data("XLM2".utf8)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPk))
        let original = ContractIDPreimageXDR.fromAsset(asset)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractIDPreimageXDR.self, data: encoded)
        if case .fromAsset(let decodedAsset) = decoded {
            XCTAssertEqual(decodedAsset.assetCode, "XLM2")
        } else {
            XCTFail("Expected .fromAsset")
        }
    }

    // MARK: - ChangeTrustAssetXDR alphanum12 Arm

    func testChangeTrustAssetXDRAlphanum12RoundTrip() throws {
        let issuerPk = try XDRTestHelpers.publicKey()
        let assetCodeData = Data("LONGASSET123".utf8)
        let assetCodeWrapped = WrappedData12(assetCodeData)
        let alpha12 = Alpha12XDR(assetCode: assetCodeWrapped, issuer: issuerPk)
        let original = ChangeTrustAssetXDR.alphanum12(alpha12)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ChangeTrustAssetXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), AssetType.creditAlphanum12.rawValue)
        if case .alphanum12(let decodedAlpha) = decoded {
            XCTAssertEqual(decodedAlpha.issuer.accountId, issuerPk.accountId)
        } else {
            XCTFail("Expected .alphanum12")
        }
    }

    // MARK: - Byte-Level Round-Trip Verification for Structs

    func testLiquidityPoolDepositOpXDRByteLevel() throws {
        let poolId = testPoolId()
        let original = LiquidityPoolDepositOpXDR(
            liquidityPoolID: poolId,
            maxAmountA: 10000,
            maxAmountB: 20000,
            minPrice: PriceXDR(n: 1, d: 10),
            maxPrice: PriceXDR(n: 10, d: 1)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolDepositOpXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testLiquidityPoolWithdrawOpXDRByteLevel() throws {
        let poolId = testPoolId()
        let original = LiquidityPoolWithdrawOpXDR(
            liquidityPoolID: poolId,
            amount: 5000,
            minAmountA: 1000,
            minAmountB: 2000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolWithdrawOpXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testBeginSponsoringFutureReservesOpXDRByteLevel() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = BeginSponsoringFutureReservesOpXDR(sponsoredId: pk)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BeginSponsoringFutureReservesOpXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testBumpSequenceOperationXDRByteLevel() throws {
        let original = BumpSequenceOperationXDR(bumpTo: 123456)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BumpSequenceOperationXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testManageDataOperationXDRByteLevel() throws {
        let dataValue = Data([0xAA, 0xBB, 0xCC])
        let original = ManageDataOperationXDR(dataName: "key", dataValue: dataValue)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ManageDataOperationXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testSorobanAddressCredentialsXDRByteLevel() throws {
        let address = try testAccountAddress()
        let original = SorobanAddressCredentialsXDR(
            address: address,
            nonce: 999,
            signatureExpirationLedger: 200000,
            signature: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAddressCredentialsXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testSorobanTransactionDataXDRByteLevel() throws {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let resources = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 100,
            diskReadBytes: 200,
            writeBytes: 300
        )
        let original = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 50000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionDataXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
    }
}
