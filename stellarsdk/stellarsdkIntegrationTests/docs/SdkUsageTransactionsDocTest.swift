//
//  SdkUsageTransactionsDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SdkUsageTransactionsDocTest: XCTestCase {
    let sdk = StellarSDK.testNet()

    // MARK: - Helper

    private func fundAccount(_ keyPair: KeyPair) async {
        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            XCTFail("Failed to fund \(keyPair.accountId): \(error)")
        }
    }

    // MARK: - Simple Payments

    func testSimplePayment() async {
        // Snippet: Simple Payments
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let accResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        switch accResponse {
        case .success(let sender):
            let paymentOp = try! PaymentOperation(
                sourceAccountId: nil,
                destinationAccountId: receiverKeyPair.accountId,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: 100.50
            )

            let transaction = try! Transaction(
                sourceAccount: sender,
                operations: [paymentOp],
                memo: Memo.none
            )

            try! transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(let details):
                XCTAssertFalse(details.transactionHash.isEmpty)
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
            case .failure(let error):
                XCTFail("Submit error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
        }
    }

    // MARK: - Multi-Operation Transactions

    func testMultiOperationTransaction() async {
        // Snippet: Multi-Operation Transactions
        let funderKeyPair = try! KeyPair.generateRandomKeyPair()
        let newAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let newAccountId = newAccountKeyPair.accountId

        await fundAccount(funderKeyPair)

        let accResponse = await sdk.accounts.getAccountDetails(accountId: funderKeyPair.accountId)
        switch accResponse {
        case .success(let funder):
            // 1. Create the new account
            let createAccountOp = try! CreateAccountOperation(
                sourceAccountId: nil,
                destinationAccountId: newAccountId,
                startBalance: 5
            )

            let transaction = try! Transaction(
                sourceAccount: funder,
                operations: [createAccountOp],
                memo: Memo.none
            )

            try! transaction.sign(keyPair: funderKeyPair, network: Network.testnet)

            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
            case .failure(let error):
                XCTFail("Submit error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
        }
    }

    // MARK: - Memos, Time Bounds, and Fees

    func testMemosTimeBoundsFees() async {
        // Snippet: Memos, Time Bounds, and Fees
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let accResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            let paymentOp = try! PaymentOperation(
                sourceAccountId: nil,
                destinationAccountId: receiverKeyPair.accountId,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: 10
            )

            // Transaction with text memo
            let transaction = try! Transaction(
                sourceAccount: account,
                operations: [paymentOp],
                memo: Memo.text("Payment for invoice #1234")
            )

            try! transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
            case .failure(let error):
                XCTFail("Submit error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
        }
    }

    func testTimeBounds() async {
        // Snippet: Time Bounds
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let accResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            let paymentOp = try! PaymentOperation(
                sourceAccountId: nil,
                destinationAccountId: receiverKeyPair.accountId,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: 5
            )

            // Time bounds (valid for next 5 minutes)
            let now = UInt64(Date().timeIntervalSince1970)
            let timeBounds = TimeBounds(minTime: 0, maxTime: now + 300)
            let preconditions = TransactionPreconditions(timeBounds: timeBounds)
            let transaction = try! Transaction(
                sourceAccount: account,
                operations: [paymentOp],
                memo: Memo.none,
                preconditions: preconditions
            )

            try! transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
            case .failure(let error):
                XCTFail("Submit error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
        }
    }

    // MARK: - Payment Operations

    func testPaymentOperations() {
        // Snippet: Payment Operations
        let paymentOp = try! PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100
        )
        XCTAssertEqual(paymentOp.amount, 100)

        // Custom asset payment
        let issuerKeyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
        let usdPaymentOp = try! PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            asset: usdAsset,
            amount: 50.25
        )
        XCTAssertEqual(usdPaymentOp.amount, 50.25)
    }

    // MARK: - Account Operations

    func testCreateAccountOperation() {
        // Snippet: Create Account
        let createOp = try! CreateAccountOperation(
            sourceAccountId: nil,
            destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            startBalance: 10
        )
        XCTAssertEqual(createOp.startBalance, 10)
    }

    func testAccountMergeOperation() {
        // Snippet: Merge Account
        let mergeOp = try! AccountMergeOperation(
            destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            sourceAccountId: nil
        )
        XCTAssertEqual(mergeOp.destinationAccountId, "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
    }

    func testManageDataOperation() {
        // Snippet: Manage Data
        let setDataOp = ManageDataOperation(
            sourceAccountId: nil,
            name: "config",
            data: "production".data(using: .utf8)
        )
        XCTAssertEqual(setDataOp.name, "config")
        XCTAssertNotNil(setDataOp.data)

        // Delete
        let deleteDataOp = ManageDataOperation(
            sourceAccountId: nil,
            name: "temp_key",
            data: nil
        )
        XCTAssertNil(deleteDataOp.data)
    }

    // MARK: - Set Options

    func testSetOptionsOperation() {
        // Snippet: Set Options
        let setDomainOp = try! SetOptionsOperation(
            sourceAccountId: nil,
            homeDomain: "example.com"
        )
        XCTAssertEqual(setDomainOp.homeDomain, "example.com")

        let setThresholdsOp = try! SetOptionsOperation(
            sourceAccountId: nil,
            masterKeyWeight: 10,
            lowThreshold: 10,
            mediumThreshold: 20,
            highThreshold: 30
        )
        XCTAssertEqual(setThresholdsOp.masterKeyWeight, 10)
        XCTAssertEqual(setThresholdsOp.lowThreshold, 10)
        XCTAssertEqual(setThresholdsOp.mediumThreshold, 20)
        XCTAssertEqual(setThresholdsOp.highThreshold, 30)
    }

    func testSetFlagsOperation() {
        // Snippet: Set Account Flags
        let setFlagsOp = try! SetOptionsOperation(
            sourceAccountId: nil,
            setFlags: 1 | 2  // AUTH_REQUIRED | AUTH_REVOCABLE
        )
        XCTAssertEqual(setFlagsOp.setFlags, 3)

        let clearFlagsOp = try! SetOptionsOperation(
            sourceAccountId: nil,
            clearFlags: 2
        )
        XCTAssertEqual(clearFlagsOp.clearFlags, 2)
    }

    // MARK: - Bump Sequence

    func testBumpSequence() async {
        // Snippet: Bump Sequence
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let accResponse = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch accResponse {
        case .success(let account):
            let currentSequence = account.sequenceNumber

            let bumpOp = BumpSequenceOperation(
                bumpTo: currentSequence + 100,
                sourceAccountId: nil
            )

            let transaction = try! Transaction(
                sourceAccount: account,
                operations: [bumpOp],
                memo: Memo.none
            )

            try! transaction.sign(keyPair: keyPair, network: Network.testnet)

            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
            case .failure(let error):
                XCTFail("Submit error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Trustline Operations

    func testChangeTrustOperation() {
        // Snippet: Create Trustline
        let issuerKeyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
        let usdAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        let trustOp = ChangeTrustOperation(
            sourceAccountId: nil,
            asset: usdAsset,
            limit: 10000
        )
        XCTAssertEqual(trustOp.limit, 10000)

        // Unlimited
        let trustOpUnlimited = ChangeTrustOperation(
            sourceAccountId: nil,
            asset: usdAsset
        )
        XCTAssertNil(trustOpUnlimited.limit)

        // Remove (limit = 0)
        let removeTrustOp = ChangeTrustOperation(
            sourceAccountId: nil,
            asset: usdAsset,
            limit: 0
        )
        XCTAssertEqual(removeTrustOp.limit, 0)
    }

    // MARK: - Set Trustline Flags

    func testSetTrustlineFlagsOperation() {
        // Snippet: Authorize Trustline
        let issuerKeyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        let authorizeOp = SetTrustlineFlagsOperation(
            sourceAccountId: nil,
            asset: usdAsset,
            trustorAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            setFlags: 1,
            clearFlags: 0
        )
        XCTAssertEqual(authorizeOp.setFlags, 1)
        XCTAssertEqual(authorizeOp.clearFlags, 0)
    }

    // MARK: - Claimable Balance Operations

    func testClaimableBalanceOperations() {
        // Snippet: Create Claimable Balance
        let claimant1 = Claimant(
            destination: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            predicate: Claimant.predicateUnconditional()
        )

        let thirtyDaysFromNow = Int64(Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970)
        let claimant2 = Claimant(
            destination: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            predicate: Claimant.predicateBeforeAbsoluteTime(unixEpoch: thirtyDaysFromNow)
        )

        let createOp = CreateClaimableBalanceOperation(
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100,
            claimants: [claimant1, claimant2]
        )
        XCTAssertEqual(createOp.claimants.count, 2)
        XCTAssertEqual(createOp.amount, 100)
    }

    func testPredicates() {
        // Snippet: Predicates
        let anytime = Claimant.predicateUnconditional()
        XCTAssertNotNil(anytime)

        let withinOneHour = Claimant.predicateBeforeRelativeTime(seconds: 3600)
        XCTAssertNotNil(withinOneHour)

        let afterOneDay = Claimant.predicateNot(
            predicate: Claimant.predicateBeforeRelativeTime(seconds: 86400)
        )
        XCTAssertNotNil(afterOneDay)

        let timeWindow = Claimant.predicateAnd(
            left: Claimant.predicateNot(predicate: Claimant.predicateBeforeRelativeTime(seconds: 86400)),
            right: Claimant.predicateBeforeRelativeTime(seconds: 86400 * 30)
        )
        XCTAssertNotNil(timeWindow)

        let eitherCondition = Claimant.predicateOr(left: anytime, right: withinOneHour)
        XCTAssertNotNil(eitherCondition)
    }

    // MARK: - Sponsorship Operations

    func testSponsorAccountCreation() async {
        // Snippet: Sponsor Account Creation
        let sponsorKeyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(sponsorKeyPair)

        let newAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let newAccountId = newAccountKeyPair.accountId

        let accResponse = await sdk.accounts.getAccountDetails(accountId: sponsorKeyPair.accountId)
        switch accResponse {
        case .success(let sponsorAccount):
            let transaction = try! Transaction(
                sourceAccount: sponsorAccount,
                operations: [
                    BeginSponsoringFutureReservesOperation(sponsoredAccountId: newAccountId),
                    CreateAccountOperation(sourceAccountId: nil, destination: newAccountKeyPair, startBalance: 0),
                    EndSponsoringFutureReservesOperation(sponsoredAccountId: newAccountId)
                ],
                memo: Memo.none
            )

            try! transaction.sign(keyPair: sponsorKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: newAccountKeyPair, network: Network.testnet)

            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
            case .failure(let error):
                XCTFail("Submit error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Assets

    func testAssets() {
        // Snippet: Assets
        let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        XCTAssertNotNil(xlm)

        let issuerKeyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
        let usd = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
        XCTAssertEqual(usd.code, "USD")

        let myToken = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "MYTOKEN", issuer: issuerKeyPair)!
        XCTAssertEqual(myToken.code, "MYTOKEN")

        // Canonical form
        let canonical = usd.toCanonicalForm()
        XCTAssertTrue(canonical.hasPrefix("USD:"))

        let xlmCanonical = xlm.toCanonicalForm()
        XCTAssertEqual(xlmCanonical, "native")

        // Parse from canonical
        let parsed = Asset(canonicalForm: canonical)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.code, "USD")
    }

    func testPoolShareAssets() {
        // Snippet: Pool Share Assets
        let issuerKeyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        let poolShareAsset = try! ChangeTrustAsset(assetA: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, assetB: usdAsset)!
        XCTAssertEqual(poolShareAsset.type, AssetType.ASSET_TYPE_POOL_SHARE)
    }

    // MARK: - Liquidity Pool Operations

    func testLiquidityPoolOperations() {
        // Snippet: Liquidity Pool Deposit/Withdraw
        let depositOp = LiquidityPoolDepositOperation(
            sourceAccountId: nil,
            liquidityPoolId: "abc123",
            maxAmountA: 1000,
            maxAmountB: 500,
            minPrice: Price(numerator: 19, denominator: 10),
            maxPrice: Price(numerator: 21, denominator: 10)
        )
        XCTAssertEqual(depositOp.maxAmountA, 1000)

        let withdrawOp = LiquidityPoolWithdrawOperation(
            sourceAccountId: nil,
            liquidityPoolId: "abc123",
            amount: 100,
            minAmountA: 180,
            minAmountB: 90
        )
        XCTAssertEqual(withdrawOp.amount, 100)
    }

    // MARK: - Revoke Sponsorship

    func testRevokeSponsorshipLedgerKeys() {
        // Snippet: Revoke Sponsorship
        let revokeAccountKey = try! RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(
            accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D"
        )
        let revokeAccountOp = RevokeSponsorshipOperation(ledgerKey: revokeAccountKey)
        XCTAssertNotNil(revokeAccountOp.ledgerKey)

        let issuerKeyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
        let revokeTrustlineKey = try! RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(
            accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            asset: usdAsset
        )
        let revokeTrustlineOp = RevokeSponsorshipOperation(ledgerKey: revokeTrustlineKey)
        XCTAssertNotNil(revokeTrustlineOp.ledgerKey)

        let revokeDataKey = try! RevokeSponsorshipOperation.revokeDataSponsorshipLedgerKey(
            accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            dataName: "data_key"
        )
        let revokeDataOp = RevokeSponsorshipOperation(ledgerKey: revokeDataKey)
        XCTAssertNotNil(revokeDataOp.ledgerKey)
    }
}
