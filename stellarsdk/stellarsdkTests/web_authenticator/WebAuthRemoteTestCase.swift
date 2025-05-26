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

    func testWebAuthenticatorFromDomainSuccess() async {
        let responseEnum = await WebAuthenticator.from(domain: domain, network: .testnet)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("https://testanchor.stellar.org/auth", response.authEndpoint)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testGetJWTSuccess1() async {
        var webAuth:WebAuthenticator? = nil
        let responseEnum = await WebAuthenticator.from(domain: domain, network: .testnet)
        switch responseEnum {
        case .success(let response):
            webAuth = response
        case .failure(_):
            XCTFail()
        }
        
        let keyPair = try! KeyPair(secretSeed: self.userSeed)
        let userAccountId = keyPair.accountId
        let signers = [keyPair]
        let jwtResponseEnum = await webAuth!.jwtToken(forUserAccount: userAccountId, signers: signers)
        switch jwtResponseEnum {
        case .success(let jwtToken):
            print("JWT received: \(jwtToken)")
        case .failure(_):
            XCTFail()
        }
    }
    
    
    func testGetJWTSuccess2() async {
        let authEndpoint = "https://testanchor.stellar.org/auth"
        let serverSigningKey = "GCHLHDBOKG2JWMJQBTLSL5XG6NO7ESXI2TAQKZXCXWXB5WI2X6W233PR"
        let serverHomeDomain = "testanchor.stellar.org"
        
        let webAuth = WebAuthenticator(authEndpoint: authEndpoint, network: .testnet,
                                       serverSigningKey: serverSigningKey, serverHomeDomain: serverHomeDomain)
        
        let signers = [try! KeyPair(secretSeed: self.userSeed)]
        let jwtResponseEnum = await webAuth.jwtToken(forUserAccount: userAccountId, signers: signers)
        switch jwtResponseEnum {
        case .success(let jwtToken):
            print("JWT received: \(jwtToken)")
        case .failure(_):
            XCTFail()
        }
    }

}
