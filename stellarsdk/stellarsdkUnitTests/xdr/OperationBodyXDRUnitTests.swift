//
//  OperationBodyXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationBodyXDRUnitTests: XCTestCase {

    // MARK: - Test Constants

    private let testAccountId1 = "GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF"
    private let testAccountId2 = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"
    private let testSecretSeed1 = "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK"
    private let testSecretSeed2 = "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII"
    private let issuerSecretSeed = "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ"

    // MARK: - CreateAccount Operation Tests

    func testOperationBodyXDRCreateAccount() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let destination = try KeyPair(secretSeed: testSecretSeed2)
        let startAmount = Decimal(1000)

        let operation = try CreateAccountOperation(
            sourceAccountId: source.accountId,
            destinationAccountId: destination.accountId,
            startBalance: startAmount
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.accountCreated.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.accountCreated.rawValue)

        // Verify decoded values
        if case .createAccount(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.startingBalance, 10000000000) // 1000 XLM in stroops
            XCTAssertEqual(decodedOp.destination.accountId, destination.accountId)
        } else {
            XCTFail("Expected createAccount operation body")
        }
    }

    // MARK: - Payment Operation Tests

    func testOperationBodyXDRPayment() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let destination = try KeyPair(secretSeed: testSecretSeed2)
        let amount = Decimal(1000)
        let asset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!

        let operation = try PaymentOperation(
            sourceAccountId: source.accountId,
            destinationAccountId: destination.accountId,
            asset: asset,
            amount: amount
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.payment.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.payment.rawValue)

        // Verify decoded values
        if case .payment(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.amount, 10000000000) // 1000 in stroops
            XCTAssertEqual(decodedOp.destination.ed25519AccountId, destination.accountId)
            XCTAssertEqual(decodedOp.asset.type(), AssetType.ASSET_TYPE_NATIVE)
        } else {
            XCTFail("Expected payment operation body")
        }
    }

    // MARK: - PathPaymentStrictReceive Operation Tests

    func testOperationBodyXDRPathPaymentStrictReceive() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let destination = try KeyPair(secretSeed: testSecretSeed2)
        let issuer = try KeyPair(secretSeed: issuerSecretSeed)

        let sendAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let sendMax = Decimal(0.0001)
        let destAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
        let destAmount = Decimal(0.0001)

        let operation = try PathPaymentOperation(
            sourceAccountId: source.accountId,
            sendAsset: sendAsset,
            sendMax: sendMax,
            destinationAccountId: destination.accountId,
            destAsset: destAsset,
            destAmount: destAmount,
            path: []
        )
        let operationXdr = try operation.toXDR()

        // Verify type - pathPayment is strict receive
        XCTAssertEqual(operationXdr.body.type(), OperationType.pathPayment.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.pathPayment.rawValue)

        // Verify decoded values
        if case .pathPayment(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.sendMax, 1000) // 0.0001 in stroops
            XCTAssertEqual(decodedOp.destinationAmount, 1000)
            XCTAssertEqual(decodedOp.destination.ed25519AccountId, destination.accountId)
            XCTAssertEqual(decodedOp.destinationAsset.assetCode, "USD")
        } else {
            XCTFail("Expected pathPayment operation body")
        }
    }

    // MARK: - PathPaymentStrictSend Operation Tests

    func testOperationBodyXDRPathPaymentStrictSend() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let destination = try KeyPair(secretSeed: testSecretSeed2)
        let issuer = try KeyPair(secretSeed: issuerSecretSeed)

        let sendAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let sendAmount = Decimal(0.0001) // For strict send, this is the exact amount sent
        let destAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: issuer)!
        let destMin = Decimal(0.00005) // For strict send, this is the minimum destination amount

        // Note: PathPaymentStrictSendOperation uses the same parameter names as its parent
        // sendMax = sendAmount (the exact amount to send)
        // destAmount = destMin (the minimum amount to receive)
        let operation = try PathPaymentStrictSendOperation(
            sourceAccountId: source.accountId,
            sendAsset: sendAsset,
            sendMax: sendAmount,
            destinationAccountId: destination.accountId,
            destAsset: destAsset,
            destAmount: destMin,
            path: []
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.pathPaymentStrictSend.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.pathPaymentStrictSend.rawValue)

        // Verify decoded values
        if case .pathPaymentStrictSend(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.sendMax, 1000) // sendAmount in stroops
            XCTAssertEqual(decodedOp.destinationAmount, 500) // destMin in stroops
            XCTAssertEqual(decodedOp.destination.ed25519AccountId, destination.accountId)
            XCTAssertEqual(decodedOp.destinationAsset.assetCode, "EUR")
        } else {
            XCTFail("Expected pathPaymentStrictSend operation body")
        }
    }

    // MARK: - ManageSellOffer Operation Tests

    func testOperationBodyXDRManageSellOffer() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let issuer = try KeyPair(secretSeed: issuerSecretSeed)

        let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let buying = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
        let amount = Decimal(0.00001)
        let price = Price.fromString(price: "0.85334384")
        let offerId: Int64 = 1

        let operation = ManageSellOfferOperation(
            sourceAccountId: source.accountId,
            selling: selling,
            buying: buying,
            amount: amount,
            price: price,
            offerId: offerId
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.manageSellOffer.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.manageSellOffer.rawValue)

        // Verify decoded values
        if case .manageSellOffer(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.amount, 100) // 0.00001 in stroops
            XCTAssertEqual(decodedOp.offerID, offerId)
            XCTAssertEqual(decodedOp.price.n, 5333399)
            XCTAssertEqual(decodedOp.price.d, 6250000)
            XCTAssertEqual(decodedOp.selling.type(), AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(decodedOp.buying.assetCode, "USD")
        } else {
            XCTFail("Expected manageSellOffer operation body")
        }
    }

    // MARK: - ManageBuyOffer Operation Tests

    func testOperationBodyXDRManageBuyOffer() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let issuer = try KeyPair(secretSeed: issuerSecretSeed)

        let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let buying = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: issuer)!
        let buyAmount = Decimal(0.00002)
        let price = Price.fromString(price: "1.5")
        let offerId: Int64 = 12345

        let operation = ManageBuyOfferOperation(
            sourceAccountId: source.accountId,
            selling: selling,
            buying: buying,
            amount: buyAmount,
            price: price,
            offerId: offerId
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.manageBuyOffer.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.manageBuyOffer.rawValue)

        // Verify decoded values
        if case .manageBuyOffer(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.amount, 200) // 0.00002 in stroops
            XCTAssertEqual(decodedOp.offerID, offerId)
            XCTAssertEqual(decodedOp.price.n, 3)
            XCTAssertEqual(decodedOp.price.d, 2)
            XCTAssertEqual(decodedOp.selling.type(), AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(decodedOp.buying.assetCode, "EUR")
        } else {
            XCTFail("Expected manageBuyOffer operation body")
        }
    }

    // MARK: - CreatePassiveSellOffer Operation Tests

    func testOperationBodyXDRCreatePassiveSellOffer() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let issuer = try KeyPair(secretSeed: issuerSecretSeed)

        let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let buying = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
        let amount = Decimal(0.00001)
        let price = Price.fromString(price: "2.93850088")

        let operation = CreatePassiveSellOfferOperation(
            sourceAccountId: source.accountId,
            selling: selling,
            buying: buying,
            amount: amount,
            price: price
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.createPassiveSellOffer.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.createPassiveSellOffer.rawValue)

        // Verify decoded values
        if case .createPassiveSellOffer(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.amount, 100) // 0.00001 in stroops
            XCTAssertEqual(decodedOp.price.n, 36731261)
            XCTAssertEqual(decodedOp.price.d, 12500000)
            XCTAssertEqual(decodedOp.selling.type(), AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(decodedOp.buying.assetCode, "USD")
        } else {
            XCTFail("Expected createPassiveSellOffer operation body")
        }
    }

    // MARK: - SetOptions Operation Tests

    func testOperationBodyXDRSetOptions() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let inflationDestination = try KeyPair(secretSeed: testSecretSeed2)
        let homeDomain = "stellar.org"

        let operation = try SetOptionsOperation(
            sourceAccountId: source.accountId,
            inflationDestination: inflationDestination,
            clearFlags: 1,
            setFlags: 1,
            masterKeyWeight: 1,
            lowThreshold: 2,
            mediumThreshold: 3,
            highThreshold: 4,
            homeDomain: homeDomain
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.setOptions.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.setOptions.rawValue)

        // Verify decoded values
        if case .setOptions(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.inflationDestination?.accountId, inflationDestination.accountId)
            XCTAssertEqual(decodedOp.homeDomain, homeDomain)
            XCTAssertEqual(decodedOp.masterWeight, 1)
            XCTAssertEqual(decodedOp.lowThreshold, 2)
            XCTAssertEqual(decodedOp.medThreshold, 3)
            XCTAssertEqual(decodedOp.highThreshold, 4)
            XCTAssertEqual(decodedOp.clearFlags, 1)
            XCTAssertEqual(decodedOp.setFlags, 1)
        } else {
            XCTFail("Expected setOptions operation body")
        }
    }

    // MARK: - ChangeTrust Operation Tests

    func testOperationBodyXDRChangeTrust() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let issuer = try KeyPair(accountId: "GCXIZK3YMSKES64ATQWMQN5CX73EWHRHUSEZXIMHP5GYHXL5LNGCOGXU")
        let asset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
        let limit = Decimal(100000.55)

        let operation = ChangeTrustOperation(
            sourceAccountId: source.accountId,
            asset: asset,
            limit: limit
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.changeTrust.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.changeTrust.rawValue)

        // Verify decoded values
        if case .changeTrust(let decodedOp) = decoded {
            var decimalXDRLimit = Decimal(decodedOp.limit)
            decimalXDRLimit = decimalXDRLimit / 10000000
            XCTAssertEqual(decimalXDRLimit, limit)
            XCTAssertEqual(decodedOp.asset.assetCode, "USD")
            XCTAssertEqual(decodedOp.asset.issuer?.accountId, issuer.accountId)
        } else {
            XCTFail("Expected changeTrust operation body")
        }
    }

    // MARK: - AllowTrust Operation Tests

    func testOperationBodyXDRAllowTrust() throws {
        let source = try KeyPair(secretSeed: testSecretSeed1)
        let trustor = try KeyPair(secretSeed: testSecretSeed2)
        let assetCode = "USDA"
        let authorize = true

        let operation = try AllowTrustOperation(
            sourceAccountId: source.accountId,
            trustor: trustor,
            assetCode: assetCode,
            authorize: authorize
        )
        let operationXdr = try operation.toXDR()

        // Verify type
        XCTAssertEqual(operationXdr.body.type(), OperationType.allowTrust.rawValue)

        // Encode and decode
        let encoded = try XDREncoder.encode(operationXdr.body)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), OperationType.allowTrust.rawValue)

        // Verify decoded values
        if case .allowTrust(let decodedOp) = decoded {
            XCTAssertEqual(decodedOp.trustor.accountId, trustor.accountId)
            XCTAssertEqual(decodedOp.authorize, TrustLineFlags.AUTHORIZED_FLAG)
            XCTAssertEqual(decodedOp.asset.assetCode, assetCode)
        } else {
            XCTFail("Expected allowTrust operation body")
        }
    }

    // MARK: - OperationType Raw Value Tests

    func testOperationTypeRawValues() throws {
        // Verify all OperationType discriminant values match Stellar protocol
        XCTAssertEqual(OperationType.accountCreated.rawValue, 0)
        XCTAssertEqual(OperationType.payment.rawValue, 1)
        XCTAssertEqual(OperationType.pathPayment.rawValue, 2)
        XCTAssertEqual(OperationType.manageSellOffer.rawValue, 3)
        XCTAssertEqual(OperationType.createPassiveSellOffer.rawValue, 4)
        XCTAssertEqual(OperationType.setOptions.rawValue, 5)
        XCTAssertEqual(OperationType.changeTrust.rawValue, 6)
        XCTAssertEqual(OperationType.allowTrust.rawValue, 7)
        XCTAssertEqual(OperationType.accountMerge.rawValue, 8)
        XCTAssertEqual(OperationType.inflation.rawValue, 9)
        XCTAssertEqual(OperationType.manageData.rawValue, 10)
        XCTAssertEqual(OperationType.bumpSequence.rawValue, 11)
        XCTAssertEqual(OperationType.manageBuyOffer.rawValue, 12)
        XCTAssertEqual(OperationType.pathPaymentStrictSend.rawValue, 13)
        XCTAssertEqual(OperationType.createClaimableBalance.rawValue, 14)
        XCTAssertEqual(OperationType.claimClaimableBalance.rawValue, 15)
        XCTAssertEqual(OperationType.beginSponsoringFutureReserves.rawValue, 16)
        XCTAssertEqual(OperationType.endSponsoringFutureReserves.rawValue, 17)
        XCTAssertEqual(OperationType.revokeSponsorship.rawValue, 18)
        XCTAssertEqual(OperationType.clawback.rawValue, 19)
        XCTAssertEqual(OperationType.clawbackClaimableBalance.rawValue, 20)
        XCTAssertEqual(OperationType.setTrustLineFlags.rawValue, 21)
        XCTAssertEqual(OperationType.liquidityPoolDeposit.rawValue, 22)
        XCTAssertEqual(OperationType.liquidityPoolWithdraw.rawValue, 23)
        XCTAssertEqual(OperationType.invokeHostFunction.rawValue, 24)
        XCTAssertEqual(OperationType.extendFootprintTTL.rawValue, 25)
        XCTAssertEqual(OperationType.restoreFootprint.rawValue, 26)
    }
}
