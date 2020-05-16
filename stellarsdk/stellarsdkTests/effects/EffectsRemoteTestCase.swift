//
//  EffectsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 05/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class EffectsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetEffects() {
        let expectation = XCTestExpectation(description: "Get effects and parse their details successfully")
        
        sdk.effects.getEffects { (response) -> (Void) in
            switch response {
            case .success(let effectsResponse):
                // load next page
                effectsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextEffectsResponse):
                        // load previous page, should contain the same effects as the first page
                        nextEffectsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevEffectsResponse):
                                let effect1 = effectsResponse.records.first
                                let effect2 = prevEffectsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(effect1?.id == effect2?.id)
                                XCTAssertTrue(effect1?.account == effect2?.account)
                                XCTAssertTrue(effect1?.effectType == effect2?.effectType)
                                XCTAssertTrue(effect1?.effectTypeString == effect2?.effectTypeString)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetEffectsForAccount() {
        let expectation = XCTestExpectation(description: "Get effects for account and parse their details successfuly")
        
        sdk.effects.getEffects(forAccount: "GAHVPXP7RPX5EGT6WFDS26AOM3SBZW2RKEDBZ5VO45J7NYDGJYKYE6UW") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GEFA Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetEffectsForOperation() {
        let expectation = XCTestExpectation(description: "Get effects for operation")
        
        sdk.effects.getEffects(forOperation: "10157597659137") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GEFO Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetEffectsForLedger() {
        let expectation = XCTestExpectation(description: "Get effects for ledger")
        
        sdk.effects.getEffects(forLedger: "1") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GEFL Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetEffectsForTransaction() {
        let expectation = XCTestExpectation(description: "Get effects for transaction")
        
        sdk.effects.getEffects(forTransaction: "5e639a21dfeb6995d2137787ebae8998d50c24ef6eb3682c61e11a55b702af91") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GEFT Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    /*func testEffectsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
    
        sdk.effects.stream(for: .allEffects(cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testEffectsForAccountStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.effects.stream(for: .effectsForAccount(account: "GDQZ4N3CMM3FL2HLYKZPF3JPZX3IRHI3SQKNSTEG6GMEA3OAW337EBA6", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testEffectsForLedgerStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.effects.stream(for: .effectsForLedger(ledger: "2365", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testEffectsForOperationStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.effects.stream(for: .effectsForOperation(operation: "10157597659137", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testEffectsForTransactionsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.effects.stream(for: .effectsForTransaction(transaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }*/
    
}
