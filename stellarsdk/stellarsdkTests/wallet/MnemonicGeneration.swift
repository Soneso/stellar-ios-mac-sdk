//
//  MnemonicGeneration.swift
//  stellarsdkTests
//
//  Created by Satraj Bambra on 2018-03-07.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MnemonicGeneration: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic()
        let mnemonicArray = mnemonic.components(separatedBy: " ")
        
        XCTAssertEqual(mnemonicArray.count, 12)
    }
    
    func test24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic()
        let mnemonicArray = mnemonic.components(separatedBy: " ")
        
        XCTAssertEqual(mnemonicArray.count, 24)
    }
}
