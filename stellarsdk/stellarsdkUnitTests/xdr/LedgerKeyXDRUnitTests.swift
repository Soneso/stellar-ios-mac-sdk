//
//  LedgerKeyXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class LedgerKeyXDRUnitTests: XCTestCase {

    // MARK: - Basic Key Type Tests

    func testLedgerKeyXDRAccount() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let accountKey = LedgerKeyAccountXDR(accountID: publicKey)
        let ledgerKey = LedgerKeyXDR.account(accountKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.account.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.account.rawValue)

        switch decoded {
        case .account(let decodedAccountKey):
            XCTAssertEqual(decodedAccountKey.accountID.accountId, accountIdString)
        default:
            XCTFail("Expected account ledger key")
        }
    }

    func testLedgerKeyXDRTrustline() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let issuerString = "GA2C5RFPE6GCKMY3US5PAB6UZLKIGSPIUKSLRB6Q723BM2OEZ4KM5GAA"
        let accountPublicKey = try PublicKey(accountId: accountIdString)
        let issuerKeyPair = try KeyPair(accountId: issuerString)

        let asset = try TrustlineAssetXDR(assetCode: "USD", issuer: issuerKeyPair)
        let trustlineKey = LedgerKeyTrustLineXDR(accountID: accountPublicKey, asset: asset)
        let ledgerKey = LedgerKeyXDR.trustline(trustlineKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.trustline.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.trustline.rawValue)

        switch decoded {
        case .trustline(let decodedTrustlineKey):
            XCTAssertEqual(decodedTrustlineKey.accountID.accountId, accountIdString)
            XCTAssertEqual(decodedTrustlineKey.asset.assetCode, "USD")
        default:
            XCTFail("Expected trustline ledger key")
        }
    }

    func testLedgerKeyXDROffer() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let sellerPublicKey = try PublicKey(accountId: sellerString)
        let offerId: UInt64 = 123456789

        let offerKey = LedgerKeyOfferXDR(sellerId: sellerPublicKey, offerId: offerId)
        let ledgerKey = LedgerKeyXDR.offer(offerKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.offer.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.offer.rawValue)

        switch decoded {
        case .offer(let decodedOfferKey):
            XCTAssertEqual(decodedOfferKey.sellerId.accountId, sellerString)
            XCTAssertEqual(decodedOfferKey.offerId, offerId)
        default:
            XCTFail("Expected offer ledger key")
        }
    }

    func testLedgerKeyXDRData() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let dataName = "test_data_entry"

        let dataKey = LedgerKeyDataXDR(accountId: publicKey, dataName: dataName)
        let ledgerKey = LedgerKeyXDR.data(dataKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.data.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.data.rawValue)

        switch decoded {
        case .data(let decodedDataKey):
            XCTAssertEqual(decodedDataKey.accountId.accountId, accountIdString)
            XCTAssertEqual(decodedDataKey.dataName, dataName)
        default:
            XCTFail("Expected data ledger key")
        }
    }

    func testLedgerKeyXDRClaimableBalance() throws {
        let balanceIdHex = "00000000c582697b67cbec7f9ce64f4dc67bfb2bfd26318bb9f964f4d70e3f41f650b1e6"
        let claimableBalanceId = try ClaimableBalanceIDXDR(claimableBalanceId: balanceIdHex)
        let ledgerKey = LedgerKeyXDR.claimableBalance(claimableBalanceId)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.claimableBalance.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.claimableBalance.rawValue)

        switch decoded {
        case .claimableBalance(let decodedBalanceId):
            XCTAssertEqual(decodedBalanceId.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
            XCTAssertNotNil(decodedBalanceId.claimableBalanceIdString)
        default:
            XCTFail("Expected claimable balance ledger key")
        }
    }

    func testLedgerKeyXDRLiquidityPool() throws {
        let poolIdHex = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let poolIdData = WrappedData32(poolIdHex.wrappedData32FromHex().wrapped)
        let liquidityPoolId = LiquidityPoolIDXDR(id: poolIdData)
        let ledgerKey = LedgerKeyXDR.liquidityPool(liquidityPoolId)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.liquidityPool.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.liquidityPool.rawValue)

        switch decoded {
        case .liquidityPool(let decodedPoolId):
            XCTAssertEqual(decodedPoolId.poolIDString.lowercased(), poolIdHex.lowercased())
        default:
            XCTFail("Expected liquidity pool ledger key")
        }
    }

    // MARK: - Encode/Decode Tests

    func testLedgerKeyXDREncodeDecode() throws {
        // Test multiple key types in a single test
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        // Account key
        let accountKey = LedgerKeyAccountXDR(accountID: publicKey)
        let accountLedgerKey = LedgerKeyXDR.account(accountKey)
        let accountEncoded = try XDREncoder.encode(accountLedgerKey)
        let accountDecoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: accountEncoded)
        XCTAssertEqual(accountDecoded.type(), LedgerEntryType.account.rawValue)

        // Data key
        let dataKey = LedgerKeyDataXDR(accountId: publicKey, dataName: "mydata")
        let dataLedgerKey = LedgerKeyXDR.data(dataKey)
        let dataEncoded = try XDREncoder.encode(dataLedgerKey)
        let dataDecoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: dataEncoded)
        XCTAssertEqual(dataDecoded.type(), LedgerEntryType.data.rawValue)

        // Offer key
        let offerKey = LedgerKeyOfferXDR(sellerId: publicKey, offerId: 999)
        let offerLedgerKey = LedgerKeyXDR.offer(offerKey)
        let offerEncoded = try XDREncoder.encode(offerLedgerKey)
        let offerDecoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: offerEncoded)
        XCTAssertEqual(offerDecoded.type(), LedgerEntryType.offer.rawValue)
    }

    func testLedgerKeyXDRRoundTrip() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let accountKey = LedgerKeyAccountXDR(accountID: publicKey)
        let ledgerKey = LedgerKeyXDR.account(accountKey)

        // Encode to bytes
        let encoded = try XDREncoder.encode(ledgerKey)

        // Convert to base64
        let base64 = Data(encoded).base64EncodedString()
        XCTAssertNotNil(base64)
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        let decoded = try LedgerKeyXDR(fromBase64: base64)

        XCTAssertEqual(decoded.type(), LedgerEntryType.account.rawValue)

        switch decoded {
        case .account(let decodedAccountKey):
            XCTAssertEqual(decodedAccountKey.accountID.accountId, accountIdString)
        default:
            XCTFail("Expected account ledger key after round-trip")
        }
    }

    func testLedgerKeyXDRFromBase64() throws {
        // Create an offer key and encode it to base64
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let sellerPublicKey = try PublicKey(accountId: sellerString)
        let offerId: UInt64 = 12345678901234

        let offerKey = LedgerKeyOfferXDR(sellerId: sellerPublicKey, offerId: offerId)
        let ledgerKey = LedgerKeyXDR.offer(offerKey)

        let encoded = try XDREncoder.encode(ledgerKey)
        let base64 = Data(encoded).base64EncodedString()

        // Decode from base64 using the convenience initializer
        let decoded = try LedgerKeyXDR(fromBase64: base64)

        XCTAssertEqual(decoded.type(), LedgerEntryType.offer.rawValue)

        switch decoded {
        case .offer(let decodedOfferKey):
            XCTAssertEqual(decodedOfferKey.offerId, offerId)
            XCTAssertEqual(decodedOfferKey.sellerId.accountId, sellerString)
        default:
            XCTFail("Expected offer ledger key from base64")
        }
    }

    // MARK: - Discriminant Tests

    func testLedgerKeyXDRDiscriminants() throws {
        // Verify all LedgerEntryType values match expected raw values
        XCTAssertEqual(LedgerEntryType.account.rawValue, 0)
        XCTAssertEqual(LedgerEntryType.trustline.rawValue, 1)
        XCTAssertEqual(LedgerEntryType.offer.rawValue, 2)
        XCTAssertEqual(LedgerEntryType.data.rawValue, 3)
        XCTAssertEqual(LedgerEntryType.claimableBalance.rawValue, 4)
        XCTAssertEqual(LedgerEntryType.liquidityPool.rawValue, 5)
        XCTAssertEqual(LedgerEntryType.contractData.rawValue, 6)
        XCTAssertEqual(LedgerEntryType.contractCode.rawValue, 7)
        XCTAssertEqual(LedgerEntryType.configSetting.rawValue, 8)
        XCTAssertEqual(LedgerEntryType.ttl.rawValue, 9)
    }

    // MARK: - Soroban Ledger Key Tests

    func testLedgerKeyXDRContractData() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let contractAddress = SCAddressXDR.account(try PublicKey(accountId: accountIdString))
        let key = SCValXDR.symbol("counter")

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: key,
            durability: .persistent
        )
        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.contractData.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractData.rawValue)

        switch decoded {
        case .contractData(let decodedContractDataKey):
            XCTAssertEqual(decodedContractDataKey.durability, .persistent)
            switch decodedContractDataKey.key {
            case .symbol(let symbolVal):
                XCTAssertEqual(symbolVal, "counter")
            default:
                XCTFail("Expected symbol key")
            }
        default:
            XCTFail("Expected contract data ledger key")
        }
    }

    func testLedgerKeyXDRContractCode() throws {
        let wasmHash = WrappedData32(Data(repeating: 0xAB, count: 32))
        let contractCodeKey = LedgerKeyContractCodeXDR(hash: wasmHash)
        let ledgerKey = LedgerKeyXDR.contractCode(contractCodeKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.contractCode.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractCode.rawValue)

        switch decoded {
        case .contractCode(let decodedContractCodeKey):
            XCTAssertEqual(decodedContractCodeKey.hash.wrapped, wasmHash.wrapped)
        default:
            XCTFail("Expected contract code ledger key")
        }
    }

    func testLedgerKeyXDRConfigSetting() throws {
        let configSettingId = ConfigSettingID.contractMaxSizeBytes.rawValue
        let ledgerKey = LedgerKeyXDR.configSetting(configSettingId)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.configSetting.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)

        switch decoded {
        case .configSetting(let decodedConfigSettingId):
            XCTAssertEqual(decodedConfigSettingId, ConfigSettingID.contractMaxSizeBytes.rawValue)
        default:
            XCTFail("Expected config setting ledger key")
        }
    }

    func testLedgerKeyXDRTTL() throws {
        let keyHash = WrappedData32(Data(repeating: 0xCC, count: 32))
        let ttlKey = LedgerKeyTTLXDR(keyHash: keyHash)
        let ledgerKey = LedgerKeyXDR.ttl(ttlKey)

        XCTAssertEqual(ledgerKey.type(), LedgerEntryType.ttl.rawValue)

        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.ttl.rawValue)

        switch decoded {
        case .ttl(let decodedTTLKey):
            XCTAssertEqual(decodedTTLKey.keyHash.wrapped, keyHash.wrapped)
        default:
            XCTFail("Expected ttl ledger key")
        }
    }

    // MARK: - Supporting Type Tests

    func testLiquidityPoolIDXDRPoolIdString() throws {
        let poolIdHex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let poolIdData = WrappedData32(poolIdHex.wrappedData32FromHex().wrapped)
        let liquidityPoolId = LiquidityPoolIDXDR(id: poolIdData)

        XCTAssertEqual(liquidityPoolId.poolIDString.lowercased(), poolIdHex.lowercased())

        let encoded = try XDREncoder.encode(liquidityPoolId)
        let decoded = try XDRDecoder.decode(LiquidityPoolIDXDR.self, data: encoded)

        XCTAssertEqual(decoded.poolIDString.lowercased(), poolIdHex.lowercased())
    }

    func testContractDataDurabilityValues() throws {
        XCTAssertEqual(ContractDataDurability.temporary.rawValue, 0)
        XCTAssertEqual(ContractDataDurability.persistent.rawValue, 1)
    }

    func testLedgerKeyContractCodeXDRFromWasmId() throws {
        let wasmIdHex = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
        let contractCodeKey = LedgerKeyContractCodeXDR(wasmId: wasmIdHex)

        let encoded = try XDREncoder.encode(contractCodeKey)
        let decoded = try XDRDecoder.decode(LedgerKeyContractCodeXDR.self, data: encoded)

        XCTAssertEqual(decoded.hash.wrapped.base16EncodedString().lowercased(), wasmIdHex.lowercased())
    }

    func testConfigSettingIDValues() throws {
        XCTAssertEqual(ConfigSettingID.contractMaxSizeBytes.rawValue, 0)
        XCTAssertEqual(ConfigSettingID.contractComputeV0.rawValue, 1)
        XCTAssertEqual(ConfigSettingID.contractLedgerCostV0.rawValue, 2)
        XCTAssertEqual(ConfigSettingID.contractHistoricalDataV0.rawValue, 3)
        XCTAssertEqual(ConfigSettingID.contractEventsV0.rawValue, 4)
        XCTAssertEqual(ConfigSettingID.contractBandwidthV0.rawValue, 5)
        XCTAssertEqual(ConfigSettingID.contractCostParamsCpuInstructions.rawValue, 6)
        XCTAssertEqual(ConfigSettingID.contractCostParamsMemoryBytes.rawValue, 7)
        XCTAssertEqual(ConfigSettingID.contractDataKeySizeBytes.rawValue, 8)
        XCTAssertEqual(ConfigSettingID.contractDataEntrySizeBytes.rawValue, 9)
        XCTAssertEqual(ConfigSettingID.stateArchival.rawValue, 10)
        XCTAssertEqual(ConfigSettingID.contractExecutionLanes.rawValue, 11)
        XCTAssertEqual(ConfigSettingID.liveSorobanStateSizeWindow.rawValue, 12)
        XCTAssertEqual(ConfigSettingID.evictionIterator.rawValue, 13)
        XCTAssertEqual(ConfigSettingID.contractParallelComputeV0.rawValue, 14)
        XCTAssertEqual(ConfigSettingID.contractLedgerCostExtV0.rawValue, 15)
        XCTAssertEqual(ConfigSettingID.scpTiming.rawValue, 16)
    }

    // MARK: - LedgerKey Field Verification Tests

    func testLedgerKeyAccountXDRFields() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let accountKey = LedgerKeyAccountXDR(accountID: publicKey)

        // Verify the accountID field is correctly set
        XCTAssertEqual(accountKey.accountID.accountId, accountIdString)

        // Encode and decode to verify field preservation
        let ledgerKey = LedgerKeyXDR.account(accountKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .account(let decodedKey):
            XCTAssertEqual(decodedKey.accountID.accountId, accountIdString)
            // Verify the public key type
            XCTAssertNotNil(decodedKey.accountID.accountId)
        default:
            XCTFail("Expected account ledger key")
        }
    }

    func testLedgerKeyTrustlineXDRFields() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let issuerString = "GA2C5RFPE6GCKMY3US5PAB6UZLKIGSPIUKSLRB6Q723BM2OEZ4KM5GAA"
        let accountPublicKey = try PublicKey(accountId: accountIdString)
        let issuerKeyPair = try KeyPair(accountId: issuerString)

        let asset = try TrustlineAssetXDR(assetCode: "USD", issuer: issuerKeyPair)
        let trustlineKey = LedgerKeyTrustLineXDR(accountID: accountPublicKey, asset: asset)

        // Verify accountID field
        XCTAssertEqual(trustlineKey.accountID.accountId, accountIdString)

        // Verify asset field properties
        XCTAssertEqual(trustlineKey.asset.assetCode, "USD")
        XCTAssertNotNil(trustlineKey.asset.issuer)
        XCTAssertEqual(trustlineKey.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)

        // Capture the actual issuer account ID from the constructed asset
        let actualIssuerAccountId = trustlineKey.asset.issuer?.accountId

        // Encode and decode to verify field preservation
        let ledgerKey = LedgerKeyXDR.trustline(trustlineKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .trustline(let decodedKey):
            XCTAssertEqual(decodedKey.accountID.accountId, accountIdString)
            XCTAssertEqual(decodedKey.asset.assetCode, "USD")
            // Verify issuer is preserved through encode/decode
            XCTAssertEqual(decodedKey.asset.issuer?.accountId, actualIssuerAccountId)
        default:
            XCTFail("Expected trustline ledger key")
        }
    }

    func testLedgerKeyTrustlineXDRWithAlphanum12() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let issuerString = "GA2C5RFPE6GCKMY3US5PAB6UZLKIGSPIUKSLRB6Q723BM2OEZ4KM5GAA"
        let accountPublicKey = try PublicKey(accountId: accountIdString)
        let issuerKeyPair = try KeyPair(accountId: issuerString)

        // Use a 12-character asset code
        let assetCode = "LONGASSET123"
        let asset = try TrustlineAssetXDR(assetCode: assetCode, issuer: issuerKeyPair)
        let trustlineKey = LedgerKeyTrustLineXDR(accountID: accountPublicKey, asset: asset)

        // Verify asset is alphanum12
        XCTAssertEqual(trustlineKey.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertEqual(trustlineKey.asset.assetCode, assetCode)

        // Capture the actual issuer account ID
        let actualIssuerAccountId = trustlineKey.asset.issuer?.accountId
        XCTAssertNotNil(actualIssuerAccountId)

        // Encode and decode
        let ledgerKey = LedgerKeyXDR.trustline(trustlineKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .trustline(let decodedKey):
            XCTAssertEqual(decodedKey.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
            XCTAssertEqual(decodedKey.asset.assetCode, assetCode)
            // Verify issuer is preserved through encode/decode
            XCTAssertEqual(decodedKey.asset.issuer?.accountId, actualIssuerAccountId)
        default:
            XCTFail("Expected trustline ledger key")
        }
    }

    func testLedgerKeyOfferXDRFields() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let sellerPublicKey = try PublicKey(accountId: sellerString)
        let offerId: UInt64 = 9876543210

        let offerKey = LedgerKeyOfferXDR(sellerId: sellerPublicKey, offerId: offerId)

        // Verify sellerID field
        XCTAssertEqual(offerKey.sellerId.accountId, sellerString)

        // Verify offerID field
        XCTAssertEqual(offerKey.offerId, offerId)

        // Encode and decode to verify field preservation
        let ledgerKey = LedgerKeyXDR.offer(offerKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .offer(let decodedKey):
            XCTAssertEqual(decodedKey.sellerId.accountId, sellerString)
            XCTAssertEqual(decodedKey.offerId, offerId)
        default:
            XCTFail("Expected offer ledger key")
        }
    }

    func testLedgerKeyDataXDRFields() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let dataName = "user_preference_setting"

        let dataKey = LedgerKeyDataXDR(accountId: publicKey, dataName: dataName)

        // Verify accountId field
        XCTAssertEqual(dataKey.accountId.accountId, accountIdString)

        // Verify dataName field
        XCTAssertEqual(dataKey.dataName, dataName)

        // Encode and decode to verify field preservation
        let ledgerKey = LedgerKeyXDR.data(dataKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .data(let decodedKey):
            XCTAssertEqual(decodedKey.accountId.accountId, accountIdString)
            XCTAssertEqual(decodedKey.dataName, dataName)
        default:
            XCTFail("Expected data ledger key")
        }
    }

    func testLedgerKeyContractDataXDRFields() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let contractAddress = SCAddressXDR.account(try PublicKey(accountId: accountIdString))
        let key = SCValXDR.symbol("storage_key")
        let durability = ContractDataDurability.persistent

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: key,
            durability: durability
        )

        // Verify contract field
        switch contractDataKey.contract {
        case .account(let pk):
            XCTAssertEqual(pk.accountId, accountIdString)
        default:
            XCTFail("Expected account address")
        }

        // Verify key field
        switch contractDataKey.key {
        case .symbol(let symbolVal):
            XCTAssertEqual(symbolVal, "storage_key")
        default:
            XCTFail("Expected symbol key")
        }

        // Verify durability field
        XCTAssertEqual(contractDataKey.durability, .persistent)
        XCTAssertEqual(contractDataKey.durability.rawValue, 1)

        // Encode and decode to verify field preservation
        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .contractData(let decodedKey):
            XCTAssertEqual(decodedKey.durability, .persistent)
            switch decodedKey.key {
            case .symbol(let symbolVal):
                XCTAssertEqual(symbolVal, "storage_key")
            default:
                XCTFail("Expected symbol key after decode")
            }
        default:
            XCTFail("Expected contract data ledger key")
        }
    }

    func testLedgerKeyContractCodeXDRFields() throws {
        let wasmHashHex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let wasmHash = wasmHashHex.wrappedData32FromHex()

        let contractCodeKey = LedgerKeyContractCodeXDR(hash: wasmHash)

        // Verify hash field
        XCTAssertEqual(contractCodeKey.hash.wrapped.base16EncodedString().lowercased(), wasmHashHex.lowercased())

        // Encode and decode to verify field preservation
        let ledgerKey = LedgerKeyXDR.contractCode(contractCodeKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .contractCode(let decodedKey):
            XCTAssertEqual(decodedKey.hash.wrapped.base16EncodedString().lowercased(), wasmHashHex.lowercased())
            XCTAssertEqual(decodedKey.hash.wrapped.count, 32)
        default:
            XCTFail("Expected contract code ledger key")
        }
    }

    func testLedgerKeyXDRWithContractAddress() throws {
        // Test with contract address (not account address) for contract data
        let contractIdHex = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
        let contractId = contractIdHex.wrappedData32FromHex()
        let contractAddress = SCAddressXDR.contract(contractId)
        let key = SCValXDR.u32(42)
        let durability = ContractDataDurability.temporary

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: key,
            durability: durability
        )

        // Verify contract field is a contract address
        switch contractDataKey.contract {
        case .contract(let cid):
            XCTAssertEqual(cid.wrapped.base16EncodedString().lowercased(), contractIdHex.lowercased())
        default:
            XCTFail("Expected contract address")
        }

        // Verify durability is temporary
        XCTAssertEqual(contractDataKey.durability, .temporary)
        XCTAssertEqual(contractDataKey.durability.rawValue, 0)

        // Encode and decode
        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .contractData(let decodedKey):
            XCTAssertEqual(decodedKey.durability, .temporary)
            switch decodedKey.contract {
            case .contract(let cid):
                XCTAssertEqual(cid.wrapped.base16EncodedString().lowercased(), contractIdHex.lowercased())
            default:
                XCTFail("Expected contract address after decode")
            }
        default:
            XCTFail("Expected contract data ledger key")
        }
    }

    func testLedgerKeyXDREmptyDataName() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let emptyDataName = ""

        let dataKey = LedgerKeyDataXDR(accountId: publicKey, dataName: emptyDataName)

        // Verify empty data name is preserved
        XCTAssertEqual(dataKey.dataName, "")
        XCTAssertEqual(dataKey.dataName.count, 0)

        // Encode and decode to verify empty string preservation
        let ledgerKey = LedgerKeyXDR.data(dataKey)
        let encoded = try XDREncoder.encode(ledgerKey)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)

        switch decoded {
        case .data(let decodedKey):
            XCTAssertEqual(decodedKey.dataName, "")
            XCTAssertEqual(decodedKey.accountId.accountId, accountIdString)
        default:
            XCTFail("Expected data ledger key")
        }
    }
}
