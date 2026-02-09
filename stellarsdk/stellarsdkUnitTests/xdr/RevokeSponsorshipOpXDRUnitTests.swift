//
//  RevokeSponsorshipOpXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class RevokeSponsorshipOpXDRUnitTests: XCTestCase {

    // MARK: - Test Constants

    private let testAccountId1 = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    private let testAccountId2 = "GBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON"
    private let testBalanceIdHex = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
    private let testPoolIdHex = "abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234"

    // MARK: - LedgerKey Account Tests

    func testRevokeSponsorshipOpXDRLedgerKeyAccount() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let ledgerKeyAccount = LedgerKeyAccountXDR(accountID: publicKey)
        let ledgerKey = LedgerKeyXDR.account(ledgerKeyAccount)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            XCTAssertEqual(decodedLedgerKey.type(), LedgerEntryType.account.rawValue)
            switch decodedLedgerKey {
            case .account(let accountKey):
                XCTAssertEqual(accountKey.accountID.accountId, testAccountId1)
            default:
                XCTFail("Expected account ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry, got signer entry")
        }
    }

    // MARK: - LedgerKey Trustline Tests

    func testRevokeSponsorshipOpXDRLedgerKeyTrustline() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let issuerKeyPair = try KeyPair(accountId: testAccountId2)
        let asset = try TrustlineAssetXDR(assetCode: "USD", issuer: issuerKeyPair)
        let ledgerKeyTrustline = LedgerKeyTrustLineXDR(accountID: publicKey, asset: asset)
        let ledgerKey = LedgerKeyXDR.trustline(ledgerKeyTrustline)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            XCTAssertEqual(decodedLedgerKey.type(), LedgerEntryType.trustline.rawValue)
            switch decodedLedgerKey {
            case .trustline(let trustlineKey):
                XCTAssertEqual(trustlineKey.accountID.accountId, testAccountId1)
                XCTAssertEqual(trustlineKey.asset.assetCode, "USD")
                XCTAssertEqual(trustlineKey.asset.issuer?.accountId, testAccountId2)
            default:
                XCTFail("Expected trustline ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry, got signer entry")
        }
    }

    // MARK: - LedgerKey Offer Tests

    func testRevokeSponsorshipOpXDRLedgerKeyOffer() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let offerId: UInt64 = 123456789
        let ledgerKeyOffer = LedgerKeyOfferXDR(sellerId: publicKey, offerId: offerId)
        let ledgerKey = LedgerKeyXDR.offer(ledgerKeyOffer)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            XCTAssertEqual(decodedLedgerKey.type(), LedgerEntryType.offer.rawValue)
            switch decodedLedgerKey {
            case .offer(let offerKey):
                XCTAssertEqual(offerKey.sellerId.accountId, testAccountId1)
                XCTAssertEqual(offerKey.offerId, offerId)
            default:
                XCTFail("Expected offer ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry, got signer entry")
        }
    }

    // MARK: - LedgerKey Data Tests

    func testRevokeSponsorshipOpXDRLedgerKeyData() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let dataName = "testDataEntry"
        let ledgerKeyData = LedgerKeyDataXDR(accountId: publicKey, dataName: dataName)
        let ledgerKey = LedgerKeyXDR.data(ledgerKeyData)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            XCTAssertEqual(decodedLedgerKey.type(), LedgerEntryType.data.rawValue)
            switch decodedLedgerKey {
            case .data(let dataKey):
                XCTAssertEqual(dataKey.accountId.accountId, testAccountId1)
                XCTAssertEqual(dataKey.dataName, dataName)
            default:
                XCTFail("Expected data ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry, got signer entry")
        }
    }

    // MARK: - LedgerKey ClaimableBalance Tests

    func testRevokeSponsorshipOpXDRLedgerKeyClaimableBalance() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let ledgerKey = LedgerKeyXDR.claimableBalance(balanceId)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            XCTAssertEqual(decodedLedgerKey.type(), LedgerEntryType.claimableBalance.rawValue)
            switch decodedLedgerKey {
            case .claimableBalance(let claimableBalanceId):
                XCTAssertEqual(claimableBalanceId.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
            default:
                XCTFail("Expected claimableBalance ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry, got signer entry")
        }
    }

    // MARK: - LedgerKey LiquidityPool Tests

    func testRevokeSponsorshipOpXDRLedgerKeyLiquidityPool() throws {
        let poolIdData = testPoolIdHex.wrappedData32FromHex()
        let liquidityPoolId = LiquidityPoolIDXDR(id: poolIdData)
        let ledgerKey = LedgerKeyXDR.liquidityPool(liquidityPoolId)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            XCTAssertEqual(decodedLedgerKey.type(), LedgerEntryType.liquidityPool.rawValue)
            switch decodedLedgerKey {
            case .liquidityPool(let poolId):
                XCTAssertEqual(poolId.poolIDString.lowercased(), testPoolIdHex.lowercased())
            default:
                XCTFail("Expected liquidityPool ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry, got signer entry")
        }
    }

    // MARK: - Signer Ed25519 Tests

    func testRevokeSponsorshipOpXDRSignerEd25519() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountId1)
        let signerPublicKey = try PublicKey(accountId: testAccountId2)
        let signerKeyData = WrappedData32(Data(signerPublicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(signerKeyData)
        let signerEntry = RevokeSponsorshipSignerXDR(accountID: accountPublicKey, signerKey: signerKey)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(signerEntry)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry:
            XCTFail("Expected signer entry, got ledger entry")
        case .revokeSponsorshipSignerEntry(let decodedSigner):
            XCTAssertEqual(decodedSigner.accountID.accountId, testAccountId1)
            switch decodedSigner.signerKey {
            case .ed25519(let keyData):
                XCTAssertEqual(keyData.wrapped.count, 32)
            default:
                XCTFail("Expected ed25519 signer key")
            }
        }
    }

    // MARK: - Signer PreAuthTx Tests

    func testRevokeSponsorshipOpXDRSignerPreAuthTx() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountId1)
        let preAuthTxHash = testBalanceIdHex.wrappedData32FromHex()
        let signerKey = SignerKeyXDR.preAuthTx(preAuthTxHash)
        let signerEntry = RevokeSponsorshipSignerXDR(accountID: accountPublicKey, signerKey: signerKey)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(signerEntry)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry:
            XCTFail("Expected signer entry, got ledger entry")
        case .revokeSponsorshipSignerEntry(let decodedSigner):
            XCTAssertEqual(decodedSigner.accountID.accountId, testAccountId1)
            switch decodedSigner.signerKey {
            case .preAuthTx(let txHash):
                XCTAssertEqual(txHash.wrapped.count, 32)
                XCTAssertEqual(txHash.wrapped.base16EncodedString().lowercased(), testBalanceIdHex.lowercased())
            default:
                XCTFail("Expected preAuthTx signer key")
            }
        }
    }

    // MARK: - Signer Sha256Hash Tests

    func testRevokeSponsorshipOpXDRSignerSha256Hash() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountId1)
        let sha256Hash = testPoolIdHex.wrappedData32FromHex()
        let signerKey = SignerKeyXDR.hashX(sha256Hash)
        let signerEntry = RevokeSponsorshipSignerXDR(accountID: accountPublicKey, signerKey: signerKey)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(signerEntry)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry:
            XCTFail("Expected signer entry, got ledger entry")
        case .revokeSponsorshipSignerEntry(let decodedSigner):
            XCTAssertEqual(decodedSigner.accountID.accountId, testAccountId1)
            switch decodedSigner.signerKey {
            case .hashX(let hash):
                XCTAssertEqual(hash.wrapped.count, 32)
                XCTAssertEqual(hash.wrapped.base16EncodedString().lowercased(), testPoolIdHex.lowercased())
            default:
                XCTFail("Expected hashX signer key")
            }
        }
    }

    // MARK: - Round-Trip Tests

    func testRevokeSponsorshipOpXDRRoundTrip() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let ledgerKeyAccount = LedgerKeyAccountXDR(accountID: publicKey)
        let ledgerKey = LedgerKeyXDR.account(ledgerKeyAccount)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        // Encode to bytes
        let encoded = try XDREncoder.encode(op)
        XCTAssertFalse(encoded.isEmpty)

        // Convert to base64
        let base64 = Data(encoded).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            switch decodedLedgerKey {
            case .account(let accountKey):
                XCTAssertEqual(accountKey.accountID.accountId, testAccountId1)
            default:
                XCTFail("Expected account ledger key after round-trip")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry after round-trip")
        }
    }

    func testRevokeSponsorshipOpXDREncodeDecode() throws {
        // Test basic encode/decode for ledger entry
        let publicKey = try PublicKey(accountId: testAccountId1)
        let ledgerKeyAccount = LedgerKeyAccountXDR(accountID: publicKey)
        let ledgerKey = LedgerKeyXDR.account(ledgerKeyAccount)
        let ledgerEntryOp = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encodedLedgerEntry = try XDREncoder.encode(ledgerEntryOp)
        let decodedLedgerEntry = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encodedLedgerEntry)

        XCTAssertEqual(decodedLedgerEntry.type(), RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue)

        // Test basic encode/decode for signer entry
        let signerKeyData = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(signerKeyData)
        let signerEntry = RevokeSponsorshipSignerXDR(accountID: publicKey, signerKey: signerKey)
        let signerEntryOp = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(signerEntry)

        let encodedSignerEntry = try XDREncoder.encode(signerEntryOp)
        let decodedSignerEntry = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encodedSignerEntry)

        XCTAssertEqual(decodedSignerEntry.type(), RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue)
    }

    // MARK: - Type Discriminant Tests

    func testRevokeSponsorshipTypeDiscriminants() throws {
        // Verify the raw values of RevokeSponsorshipType
        XCTAssertEqual(RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue, 0)
        XCTAssertEqual(RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue, 1)

        // Verify the type() method returns correct discriminants
        let publicKey = try PublicKey(accountId: testAccountId1)
        let ledgerKeyAccount = LedgerKeyAccountXDR(accountID: publicKey)
        let ledgerKey = LedgerKeyXDR.account(ledgerKeyAccount)
        let ledgerEntryOp = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        XCTAssertEqual(ledgerEntryOp.type(), 0)

        let signerKeyData = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(signerKeyData)
        let signerEntry = RevokeSponsorshipSignerXDR(accountID: publicKey, signerKey: signerKey)
        let signerEntryOp = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(signerEntry)

        XCTAssertEqual(signerEntryOp.type(), 1)
    }

    // MARK: - Additional LedgerKey Variant Tests

    func testRevokeSponsorshipOpXDRLedgerKeyTrustlineWithAlphanum12() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let issuerKeyPair = try KeyPair(accountId: testAccountId2)
        let asset = try TrustlineAssetXDR(assetCode: "LONGASSET12", issuer: issuerKeyPair)
        let ledgerKeyTrustline = LedgerKeyTrustLineXDR(accountID: publicKey, asset: asset)
        let ledgerKey = LedgerKeyXDR.trustline(ledgerKeyTrustline)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(ledgerKey)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: encoded)

        switch decoded {
        case .revokeSponsorshipLedgerEntry(let decodedLedgerKey):
            switch decodedLedgerKey {
            case .trustline(let trustlineKey):
                XCTAssertEqual(trustlineKey.asset.assetCode, "LONGASSET12")
                XCTAssertEqual(trustlineKey.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
            default:
                XCTFail("Expected trustline ledger key")
            }
        case .revokeSponsorshipSignerEntry:
            XCTFail("Expected ledger entry")
        }
    }

    func testRevokeSponsorshipOpXDRSignerRoundTrip() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountId1)
        let preAuthTxHash = testBalanceIdHex.wrappedData32FromHex()
        let signerKey = SignerKeyXDR.preAuthTx(preAuthTxHash)
        let signerEntry = RevokeSponsorshipSignerXDR(accountID: accountPublicKey, signerKey: signerKey)
        let op = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(signerEntry)

        // Encode to bytes
        let encoded = try XDREncoder.encode(op)

        // Convert to base64 and back
        let base64 = Data(encoded).base64EncodedString()
        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(RevokeSponsorshipOpXDR.self, data: [UInt8](decodedData))

        switch decoded {
        case .revokeSponsorshipSignerEntry(let decodedSigner):
            XCTAssertEqual(decodedSigner.accountID.accountId, testAccountId1)
            switch decodedSigner.signerKey {
            case .preAuthTx(let txHash):
                XCTAssertEqual(txHash.wrapped.base16EncodedString().lowercased(), testBalanceIdHex.lowercased())
            default:
                XCTFail("Expected preAuthTx signer key after round-trip")
            }
        case .revokeSponsorshipLedgerEntry:
            XCTFail("Expected signer entry after round-trip")
        }
    }

    // MARK: - RevokeSponsorshipResultXDR Tests

    func testRevokeSponsorshipResultXDRSuccess() throws {
        let result = RevokeSponsorshipResultXDR.success(RevokeSponsorshipResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.success.rawValue)
            XCTAssertEqual(code, 0)
        case .empty:
            XCTFail("Expected success result, got empty")
        }
    }

    func testRevokeSponsorshipResultXDRDoesNotExist() throws {
        let result = RevokeSponsorshipResultXDR.empty(RevokeSponsorshipResultCode.doesNotExist.rawValue)

        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty result for doesNotExist error")
        case .empty(let code):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.doesNotExist.rawValue)
            XCTAssertEqual(code, -1)
        }
    }

    func testRevokeSponsorshipResultXDRNotSponsor() throws {
        let result = RevokeSponsorshipResultXDR.empty(RevokeSponsorshipResultCode.notSponsored.rawValue)

        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty result for notSponsored error")
        case .empty(let code):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.notSponsored.rawValue)
            XCTAssertEqual(code, -2)
        }
    }

    func testRevokeSponsorshipResultXDRLowReserve() throws {
        let result = RevokeSponsorshipResultXDR.empty(RevokeSponsorshipResultCode.lowReserve.rawValue)

        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty result for lowReserve error")
        case .empty(let code):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.lowReserve.rawValue)
            XCTAssertEqual(code, -3)
        }
    }

    func testRevokeSponsorshipResultXDROnlyTransferable() throws {
        let result = RevokeSponsorshipResultXDR.empty(RevokeSponsorshipResultCode.onlyTransferabel.rawValue)

        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty result for onlyTransferable error")
        case .empty(let code):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.onlyTransferabel.rawValue)
            XCTAssertEqual(code, -4)
        }
    }

    func testRevokeSponsorshipResultXDRMalformed() throws {
        let result = RevokeSponsorshipResultXDR.empty(RevokeSponsorshipResultCode.malformed.rawValue)

        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty result for malformed error")
        case .empty(let code):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.malformed.rawValue)
            XCTAssertEqual(code, -5)
        }
    }

    func testRevokeSponsorshipResultXDRRoundTrip() throws {
        // Test success round-trip via base64
        let successResult = RevokeSponsorshipResultXDR.success(RevokeSponsorshipResultCode.success.rawValue)
        let successEncoded = try XDREncoder.encode(successResult)
        let successBase64 = Data(successEncoded).base64EncodedString()
        XCTAssertFalse(successBase64.isEmpty)

        guard let successDecodedData = Data(base64Encoded: successBase64) else {
            XCTFail("Failed to decode success base64")
            return
        }
        let successDecoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: [UInt8](successDecodedData))

        switch successDecoded {
        case .success(let code):
            XCTAssertEqual(code, 0)
        case .empty:
            XCTFail("Expected success result after round-trip")
        }

        // Test error round-trip via base64
        let errorResult = RevokeSponsorshipResultXDR.empty(RevokeSponsorshipResultCode.notSponsored.rawValue)
        let errorEncoded = try XDREncoder.encode(errorResult)
        let errorBase64 = Data(errorEncoded).base64EncodedString()
        XCTAssertFalse(errorBase64.isEmpty)

        guard let errorDecodedData = Data(base64Encoded: errorBase64) else {
            XCTFail("Failed to decode error base64")
            return
        }
        let errorDecoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: [UInt8](errorDecodedData))

        switch errorDecoded {
        case .success:
            XCTFail("Expected empty result after round-trip")
        case .empty(let code):
            XCTAssertEqual(code, -2)
        }
    }
}
