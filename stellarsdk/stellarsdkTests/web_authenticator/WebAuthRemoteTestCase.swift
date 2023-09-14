//
//  WebAuthRemoteTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.09.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class WebAuthRemoteTestCase: XCTestCase {

    let domain = "testanchor.stellar.org"
    let userAccountId = "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V"
    let userSeed = "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX"
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testWebAuthenticatorFromDomainSuccess() {
        let expectation = XCTestExpectation(description: "WebAuthenticator is created with success.")
        try? WebAuthenticator.from(domain: domain, network: .testnet) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetJWTSuccess1() {
        let expectation = XCTestExpectation(description: "JWT is received with success.")
        
        try? WebAuthenticator.from(domain: domain, network: .testnet) { (response) -> (Void) in
            switch response {
            case .success(let webAuth):
                if let keyPair = try? KeyPair(secretSeed: self.userSeed) {
                    let userAccountId = keyPair.accountId
                    let signers = [keyPair]
                    webAuth.jwtToken(forUserAccount: userAccountId, signers: signers) { (response) -> (Void) in
                        switch response {
                        case .success(let jwt):
                            print("JWT received: \(jwt)")
                            XCTAssert(true)
                        case .failure(_):
                            XCTAssert(false)
                        }
                        expectation.fulfill()
                    }
                }
            case .failure(_):
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    
    func testGetJWTSuccess2() {
        let expectation = XCTestExpectation(description: "JWT is received with success.")
        
        let authEndpoint = "https://testanchor.stellar.org/auth"
        let serverSigningKey = "GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS"
        let serverHomeDomain = "testanchor.stellar.org"
        
        let webAuth = WebAuthenticator(authEndpoint: authEndpoint, network: .testnet,
                                       serverSigningKey: serverSigningKey, serverHomeDomain: serverHomeDomain)
        
        let signers = [try! KeyPair(secretSeed: self.userSeed)]
        webAuth.jwtToken(forUserAccount: userAccountId, signers: signers) { (response) -> (Void) in
            switch response {
            case .success(let jwtToken):
                print("JWT received: \(jwtToken)")
                XCTAssert(true)
            case .failure(let error):
                print("Error: \(error)")
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }

}
