//
//  TxRepOperationsTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TxRepOperationsTestCase: XCTestCase {

    func testCreateAccountOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 1000)

        let operation = try CreateAccountOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            startBalance: Decimal(100)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CREATE_ACCOUNT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.createAccountOp.destination: \(destination.accountId)"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.createAccountOp.startingBalance:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testPaymentOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 2000)

        let operation = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(50)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PAYMENT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.destination: \(destination.accountId)"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.asset: XLM"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.amount:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testPathPaymentStrictReceiveOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
        let account = Account(keyPair: source, sequenceNumber: 3000)

        let sendAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let destAsset = Asset(canonicalForm: "USD:\(issuer.accountId)")!

        let operation = try PathPaymentStrictReceiveOperation(
            sourceAccountId: nil,
            sendAsset: sendAsset,
            sendMax: Decimal(100),
            destinationAccountId: destination.accountId,
            destAsset: destAsset,
            destAmount: Decimal(50),
            path: []
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.pathPaymentStrictReceiveOp.destination: \(destination.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testPathPaymentStrictSendOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
        let account = Account(keyPair: source, sequenceNumber: 4000)

        let sendAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let destAsset = Asset(canonicalForm: "EUR:\(issuer.accountId)")!

        let operation = try PathPaymentStrictSendOperation(
            sourceAccountId: nil,
            sendAsset: sendAsset,
            sendMax: Decimal(75),
            destinationAccountId: destination.accountId,
            destAsset: destAsset,
            destAmount: Decimal(50),
            path: []
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.pathPaymentStrictSendOp.destination: \(destination.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testManageSellOfferOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
        let account = Account(keyPair: source, sequenceNumber: 5000)

        let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let buying = Asset(canonicalForm: "USD:\(issuer.accountId)")!

        let operation = ManageSellOfferOperation(
            sourceAccountId: nil,
            selling: selling,
            buying: buying,
            amount: Decimal(100),
            price: Price(numerator: 1, denominator: 2),
            offerId: 0
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: MANAGE_SELL_OFFER"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.manageSellOfferOp.selling: XLM"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testManageBuyOfferOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
        let account = Account(keyPair: source, sequenceNumber: 6000)

        let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let buying = Asset(canonicalForm: "EUR:\(issuer.accountId)")!

        let operation = ManageBuyOfferOperation(
            sourceAccountId: nil,
            selling: selling,
            buying: buying,
            amount: Decimal(50),
            price: Price(numerator: 2, denominator: 1),
            offerId: 0
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: MANAGE_BUY_OFFER"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.manageBuyOfferOp.selling: XLM"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testCreatePassiveSellOfferOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
        let account = Account(keyPair: source, sequenceNumber: 7000)

        let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let buying = Asset(canonicalForm: "BTC:\(issuer.accountId)")!

        let operation = CreatePassiveSellOfferOperation(
            sourceAccountId: nil,
            selling: selling,
            buying: buying,
            amount: Decimal(25),
            price: Price(numerator: 1, denominator: 1)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CREATE_PASSIVE_SELL_OFFER"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.createPassiveSellOfferOp.selling: XLM"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testSetOptionsOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 8000)

        let operation = try SetOptionsOperation(
            sourceAccountId: nil,
            inflationDestination: nil,
            clearFlags: nil,
            setFlags: 1,
            masterKeyWeight: 2,
            lowThreshold: nil,
            mediumThreshold: nil,
            highThreshold: nil,
            homeDomain: "example.com",
            signer: nil,
            signerWeight: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: SET_OPTIONS"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.setOptionsOp.homeDomain: \"example.com\""))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testChangeTrustOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
        let account = Account(keyPair: source, sequenceNumber: 9000)

        let asset = ChangeTrustAsset(canonicalForm: "USD:\(issuer.accountId)")!

        let operation = ChangeTrustOperation(
            sourceAccountId: nil,
            asset: asset,
            limit: Decimal(1000)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CHANGE_TRUST"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.changeTrustOp.line: USD:\(issuer.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testAllowTrustOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let trustor = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 10000)

        let operation = try AllowTrustOperation(
            sourceAccountId: nil,
            trustor: trustor,
            assetCode: "USD",
            authorize: 1
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: ALLOW_TRUST"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.allowTrustOp.trustor: \(trustor.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testAccountMergeOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 11000)

        let operation = try AccountMergeOperation(
            destinationAccountId: destination.accountId,
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: ACCOUNT_MERGE"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.destination: \(destination.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testManageDataOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 12000)

        let operation = ManageDataOperation(
            sourceAccountId: nil,
            name: "test-data",
            data: "test-value".data(using: .utf8)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: MANAGE_DATA"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.manageDataOp.dataName: \"test-data\""))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testBumpSequenceOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 13000)

        let operation = BumpSequenceOperation(
            bumpTo: 99999,
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: BUMP_SEQUENCE"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.bumpSequenceOp.bumpTo: 99999"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testCreateClaimableBalanceOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let claimant1 = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 14000)

        let claimant = Claimant(destination: claimant1.accountId)

        let operation = CreateClaimableBalanceOperation(
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100),
            claimants: [claimant],
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.createClaimableBalanceOp.asset: XLM"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testClaimClaimableBalanceOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 15000)

        let balanceId = "0101010101010101010101010101010101010101010101010101010101010101"

        let operation = ClaimClaimableBalanceOperation(
            balanceId: balanceId,
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.claimClaimableBalanceOp.balanceID.v0:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testBeginSponsoringFutureReservesOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let sponsored = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 16000)

        let operation = BeginSponsoringFutureReservesOperation(
            sponsoredAccountId: sponsored.accountId,
            sponsoringAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.beginSponsoringFutureReservesOp.sponsoredID: \(sponsored.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testEndSponsoringFutureReservesOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 17000)

        let operation = EndSponsoringFutureReservesOperation(sponsoredAccountId: source.accountId)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: END_SPONSORING_FUTURE_RESERVES"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testRevokeSponsorshipOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 18000)
        let accountToRevoke = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let ledgerKey = try RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(accountId: accountToRevoke.accountId)
        let operation = RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: nil)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: REVOKE_SPONSORSHIP"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testClawbackOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let from = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 19000)

        let asset = Asset(canonicalForm: "USD:\(source.accountId)")!

        let operation = ClawbackOperation(
            sourceAccountId: nil,
            asset: asset,
            fromAccountId: from.accountId,
            amount: Decimal(50)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CLAWBACK"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.clawbackOp.from: \(from.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testClawbackClaimableBalanceOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 20000)

        let balanceId = "0202020202020202020202020202020202020202020202020202020202020202"

        let operation = ClawbackClaimableBalanceOperation(
            claimableBalanceID: balanceId,
            sourceAccountId: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.v0:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testSetTrustLineFlagsOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let trustor = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 21000)

        let asset = Asset(canonicalForm: "USD:\(source.accountId)")!

        let operation = SetTrustlineFlagsOperation(
            sourceAccountId: nil,
            asset: asset,
            trustorAccountId: trustor.accountId,
            setFlags: 1,
            clearFlags: 0
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: SET_TRUST_LINE_FLAGS"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.setTrustLineFlagsOp.trustor: \(trustor.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testLiquidityPoolDepositOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 22000)

        let poolId = "0303030303030303030303030303030303030303030303030303030303030303"

        let operation = LiquidityPoolDepositOperation(
            sourceAccountId: nil,
            liquidityPoolId: poolId,
            maxAmountA: Decimal(100),
            maxAmountB: Decimal(200),
            minPrice: Price(numerator: 1, denominator: 2),
            maxPrice: Price(numerator: 2, denominator: 1)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: LIQUIDITY_POOL_DEPOSIT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.liquidityPoolDepositOp.liquidityPoolID:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testLiquidityPoolWithdrawOperationTxRep() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 23000)

        let poolId = "0404040404040404040404040404040404040404040404040404040404040404"

        let operation = LiquidityPoolWithdrawOperation(
            sourceAccountId: nil,
            liquidityPoolId: poolId,
            amount: Decimal(150),
            minAmountA: Decimal(50),
            minAmountB: Decimal(75)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: LIQUIDITY_POOL_WITHDRAW"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.liquidityPoolWithdrawOp.liquidityPoolID:"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }
}
