//
//  PaymentPathsTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/14/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PaymentPathsTestCase: XCTestCase {
    let sdk = StellarSDK()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFindPaymentPaths() {
        let expectation = XCTestExpectation(description: "Find payment paths")
        
        sdk.paymentPaths.findPaymentPaths(destinationAccount:"GAEDTJ4PPEFVW5XV2S7LUXBEHNQMX5Q2GM562RJGOQG7GVCE5H3HIB4V", destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer:"GDSBCQO34HWPGUGQSP3QBFEXVTSR2PW46UIGTHVWGWJGQKH3AFNHXHXN", destinationAmount:"20", sourceAccount:"GARSFJNXJIHO6ULUBK3DBYKVSIZE7SC72S5DYBCHU7DKL22UXKVD7MXP") { (response) -> (Void) in
            switch response {
            case .success(let findPaymentPathsResponse):
                
                for paymentPath in findPaymentPathsResponse.records {
                    print("FPP Test: \(paymentPath.destinationAmount) is the destination amount")
                    print("FPP Test: \(paymentPath.sourceAmount) is the source amount")
                }

                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"FPP Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStrictReceive() {
        let expectation = XCTestExpectation(description: "strict receive")
        
        sdk.paymentPaths.strictReceive(sourceAccount:"GDGNF4FLAPCTN2WQ4SM7RPB42QIEPM3FK5M4FAVREOBUALT7I6DVNHCX", sourceAssets: nil, destinationAccount: "GDVBXZRTW5DD7KZJQJ2MASO5DBERKBGLZJK6AMOD3PMD5KW6XKDUIWPQ", destinationAssetType: "credit_alphanum4", destinationAssetCode:"POC", destinationAssetIssuer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII", destinationAmount: "20") { (response) -> (Void) in
            switch response {
            case .success(let strictReceiveResponse):
                XCTAssert(strictReceiveResponse.records.count > 0)
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Strict receive Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStrictSend() {
        let expectation = XCTestExpectation(description: "strict send")
        
        sdk.paymentPaths.strictSend(sourceAmount:"10", sourceAssetType:"native", destinationAssets:"POC:GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII") { (response) -> (Void) in
            switch response {
            case .success(let strictSendResponse):
                XCTAssert(strictSendResponse.records.count > 0)
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Strict send Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
