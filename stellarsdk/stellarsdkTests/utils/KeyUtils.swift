//
//  KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class KeyUtils: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testKeyUtilsPublicKey() {
        let publicKey = "GAYYAL2XJKSQHQ7RJG7MXHTXPZFPUWPCV46UZLBEEF7FAHIQ36FT7ATA"
   
        do {
            let data = try publicKey.decodeEd25519PublicKey()
            let encodedKey = try data.encodeEd25519PublicKey()
            
            XCTAssertTrue(publicKey == encodedKey)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsMuxedAccountP() {
        let accountId = "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N"
        
        do {
            let mux = try accountId.decodeMuxedAccount()
            let muxId = mux.accountId
            
            XCTAssertTrue(accountId == muxId)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsPrivateKey() {
        let publicKey = "SBXLH5ZCTJR2VKCDFKUQWP2WI4B5HKWDRQQ4TUZLFE47MQ4LZEAHCBLU"
        
        do {
            let data = try publicKey.decodeEd25519SecretSeed()
            let encodedKey = try data.encodeEd25519SecretSeed()
            
            XCTAssertTrue(publicKey == encodedKey)
        } catch {
            XCTAssertTrue(false)
        }
    }


}
