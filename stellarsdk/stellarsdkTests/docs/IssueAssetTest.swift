//
//  IssueAssetTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.12.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class IssueAssetTest: XCTestCase {

    let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
    
    
    func testIssueAssetTutorial() async {
        
        let expectation = XCTestExpectation(description: "issue asset example from docs is executed successfully")
        
        //1. Create issuing account and an object to represent the new asset
        let issuerKeypair = try! KeyPair.generateRandomKeyPair()
        let astroDollar = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "AstroDollar", issuer: issuerKeypair)!;
        
        //2. Create distribution account
        let distributionKeypair = try! KeyPair.generateRandomKeyPair()
        
        // Alternative: This loads a keypair from a secret key you already have
        // let distributionKeypair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4");
        
        // we need to fund the 2 accounts first. In this example we use freinbot to do so
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: issuerKeypair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testIssueAssetTutorial()", horizonRequestError: error)
            XCTFail("could not create issuer account: \(issuerKeypair.accountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: distributionKeypair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testIssueAssetTutorial()", horizonRequestError: error)
            XCTFail("could not create distribution account: \(distributionKeypair.accountId)")
        }
        
        // 3. Establish trustline between the two
        // 4. Make a payment from issuing to distribution account, issuing the asset.
        var accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: distributionKeypair.accountId);
        switch accDetailsResEnum {
        case .success(let details):
            do {
                // build the change trust operation
                let changeTrustAsset = ChangeTrustAsset(type: astroDollar.type, code: astroDollar.code, issuer: astroDollar.issuer)!
                let changeTrustOperation = ChangeTrustOperation(sourceAccountId: distributionKeypair.accountId,
                                                                asset: changeTrustAsset,
                                                                limit: 1000)
                
                //build the payment operation
                let paymentOperation = try PaymentOperation(sourceAccountId: issuerKeypair.accountId,
                                                            destinationAccountId: distributionKeypair.accountId,
                                                            asset: astroDollar,
                                                            amount: 1000)
                
                // build the transaction
                let transaction = try Transaction(sourceAccount: details,
                                                  operations: [changeTrustOperation, paymentOperation],
                                                  memo: Memo.none)
                
                // sign the transaction for the change trust operation
                try transaction.sign(keyPair: distributionKeypair, network: Network.testnet)
                
                // sign the transaction for the payment trust operation
                try transaction.sign(keyPair: issuerKeypair, network: Network.testnet)
                
                let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
                switch submitTxResultEnum {
                case .success(let result):
                    XCTAssertTrue(result.operationCount > 0)
                case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                    XCTFail("destination account \(destinationAccountId) requires memo")
                case .failure(error: let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionMultiSigning()", horizonRequestError: error)
                    XCTFail("submit transaction error")
                }
                
            } catch {
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance()", horizonRequestError: error)
            XCTFail("could not load account details of distribution account \(distributionKeypair.accountId)")
            expectation.fulfill()
        }
        
        
        accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: distributionKeypair.accountId);
        switch accDetailsResEnum {
        case .success(let details):
            // You can check the `balance`, `sequence`, `flags`, `signers`, `data` etc.
            
            for balance in details.balances {
                switch balance.assetType {
                case AssetTypeAsString.NATIVE:
                    print("balance: \(balance.balance) XLM")
                default:
                    print("balance: \(balance.balance) \(balance.assetCode!) issuer: \(balance.assetIssuer!)")
                }
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance()", horizonRequestError: error)
            XCTFail("could not load account details of distribution account \(distributionKeypair.accountId)")
            expectation.fulfill()
        }
    }
}
