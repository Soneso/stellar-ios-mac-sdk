//
//  AmmTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AmmTestCase: XCTestCase {

    let sdk = StellarSDK(withHorizonUrl:"...")
    let network = Network.custom(networkId: "...")
    let seed = "SC3FVGWBQDEWH7XER6L23ZR7RRHOVMMVQVZ64RULNCK56SPZH4Q2LAKZ"
    let assetAIssuingAccount = "GBA26NHVZBTQZDMVTW6UGXI2SXUI6B4U5OIHJRQPEPXJCVR5O5EXTP3D"
    let assetBIssuingAccount = "GBA26NHVZBTQZDMVTW6UGXI2SXUI6B4U5OIHJRQPEPXJCVR5O5EXTP3D"
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreatePoolShareTrustline() {
        
        let expectation = XCTestExpectation(description: "pool share trustline created")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            
            let issuingAccountAKeyPair = try KeyPair(accountId: assetAIssuingAccount)
            let assetA = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "SONESO", issuer: issuingAccountAKeyPair)
            let issuingAccountBKeyPair = try KeyPair(accountId: assetBIssuingAccount)
            let assetB = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "COOL", issuer: issuingAccountBKeyPair)
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let changeTrustAsset = ChangeTrustAsset(assetA:assetA!, assetB:assetB!);
                        let changeTrustOperation = ChangeTrustOperation(sourceAccountId: muxSource.accountId, asset:changeTrustAsset!)
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [changeTrustOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("create poolshare test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("create poolshare test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"create poolshare test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"create poolshare test", horizonRequestError:error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
