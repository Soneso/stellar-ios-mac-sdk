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
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.englishWords))
    }
    
    func test24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic()
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.englishWords))
    }

    func testChineseSimplified12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .chineseSimplified)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.chineseSimplifiedWords))
    }
    
    func testChineseSimplified24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .chineseSimplified)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.chineseSimplifiedWords))
    }
    
    func testChineseTraditional12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .chineseTraditional)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.chineseTraditionalWords))
    }
    
    func testChineseTraditional24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .chineseTraditional)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.chineseTraditionalWords))
    }
    
    func testFrench12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .french)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.frenchWords))
    }
    
    func testFrench24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .french)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.frenchWords))
    }
    
    func testItalian12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .italian)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.italianWords))
    }
    
    func testItalian24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .italian)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.italianWords))
    }
    
    func testJapanese12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .japanese)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.japaneseWords))
    }
    
    func testJapanese24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .japanese)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.japaneseWords))
    }
    
    func testKorean12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .korean)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.koreanWords))
    }
    
    func testKorean24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .korean)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.koreanWords))
    }
    
    func testSpanish12WordMnemonicGeneration() {
        let mnemonic = Wallet.generate12WordMnemonic(language: .spanish)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 12)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.spanishWords))
    }
    
    func testSpanish24WordMnemonicGeneration() {
        let mnemonic = Wallet.generate24WordMnemonic(language: .spanish)
        let mnemonicSet = Set(mnemonic.components(separatedBy: " "))
        
        XCTAssertEqual(mnemonic.components(separatedBy: " ").count, 24)
        XCTAssertTrue(mnemonicSet.isSubset(of: WordList.english.spanishWords))
    }
}
