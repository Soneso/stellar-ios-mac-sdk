//
//  URISchemeTestCase.swift
//  stellarsdkTests
//
//  Created by Soneso on 11/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class URISchemeTestCase: XCTestCase {
    let sdk = StellarSDK()
    let publicKey = Data(base64Encoded:"uHFsF4DaBlIsPUzFlMuBFkgEROGR9DlEBYCg3x+V72A=")!
    let privateKey = Data(base64Encoded: "KJJ6vrrDOe9XIDAj6iSftUzux0qWwSwf3er27YKUOU2ZbT/G/wqFm/tDeez3REW5YlD5mrf3iidmGjREBzOEjQ==")!
    let unsignedURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAByE3sAAAAKAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAR%2BV72AAAABAGPf5AsmVy3q7o8mFkWjm4a3QsSoz%2FCzOK%2BduPy5AYlB7RG6hWNNjQPTohEZsPvIj1VBvaTsXGfSQ4oOSukarAA%3D%3D"
    
    let signedURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAByE3sAAAAKAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAR%2BV72AAAABAGPf5AsmVy3q7o8mFkWjm4a3QsSoz%2FCzOK%2BduPy5AYlB7RG6hWNNjQPTohEZsPvIj1VBvaTsXGfSQ4oOSukarAA%3D%3D&signature=tSZqF%2FlrhGvuK3%2B65XQQ9qlSHz%2BeLT8SIQgg12nLtyPLB%2F2y%2B94l%2FUigBD9z3p3ZylihHcLDRfIdOGXB6fS8DA%3D%3D"
    
    let validURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAABAAAAAAAAAAAAAAABAAAAAAAAAAEAAAAAiTqBtoWdmQGM4NgT/lTVswTMv7HPmP3lmt3CXnqXsoIAAAAAAAAAAAX14QAAAAAAAAAAAA==&origin_domain=place.domain.com&signature=Axh8nQLXounJt1NfdLvjTinVMK8EVpMcNc50BxlbNcBVGoiSlHL2Ee%2Bc95gbDUnMvWPRkBa6awCFQ1ILs5LcAQ%3D%3D"
    
    let uriValidator = URISchemeValidator()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetTransactionOperationURIScheme() {
        let expectation = XCTestExpectation(description: "URL Returned.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.inflation
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation])
                let uriSchemeBuilder = URIScheme()
                let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction)
                print("URIScheme: \(uriScheme)")
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"TS Test", horizonRequestError:error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetPaymentOperationURIScheme() {
        let expectation = XCTestExpectation(description: "URL Returned.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let uriSchemeBuilder = URIScheme()
        let uriScheme = uriSchemeBuilder.getPayOperationURI(accountID: keyPair.accountId)
        print("PayOperationURI: \(uriScheme)")
        expectation.fulfill()
    }
    
    func testMissingSignatureFromURIScheme() {
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let expectation = XCTestExpectation(description: "Missing signature failure.")
        let isValid = uriValidator.checkURISchemeIsValid(url: unsignedURL, signerKeyPair: keyPair)
        
        switch isValid {
        case .failure(let error):
            if error == URISchemeErrors.missingSignature {
                XCTAssert(true)
            }
        default:
            XCTAssert(false)
        }
        
        expectation.fulfill()
    }
    
    func testMissingDomainFromURIScheme() {
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let expectation = XCTestExpectation(description: "Missing origin domain failure.")
        let isValid = uriValidator.checkURISchemeIsValid(url: signedURL, signerKeyPair: keyPair)
        switch isValid {
        case .failure(let error):
            if error == URISchemeErrors.missingOriginDomain{
                XCTAssert(true)
            }
        default:
            XCTAssert(false)
        }
        
        expectation.fulfill()
    }
    
    func testSigningURI() {
        let expectation = XCTestExpectation(description: "Signed URL returned.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let result = uriValidator.signURI(url: unsignedURL, signerKeyPair: keyPair)
        switch result {
            case .success(signedURL: let signedURL):
                print("Singing complete: \(signedURL)")
                XCTAssert(true)
            case .failure:
                XCTAssert(false)
        }
        
        expectation.fulfill()
    }
    
    func testValidURIScheme() {
        let expectation = XCTestExpectation(description: "URL is valid.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let isValid = uriValidator.checkURISchemeIsValid(url: validURL, signerKeyPair: keyPair)
        switch isValid {
        case .success():
            XCTAssert(true)
        case .failure(let error):
            print("ValidURIScheme Error: \(error)")
            XCTAssert(false)
        }
        
        expectation.fulfill()
    }
    
    func testTransactionSigning() {
        let expectation = XCTestExpectation(description: "The transaction is signed and sent to the stellar network")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(error: let error):
                XCTAssert(false)
                print("Transaction signing failed! Error: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testSourceAccountAndSignerAccountMismatch() {
        let expectation = XCTestExpectation(description: "The transaction's source account is different than the sginer's public key")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .failure(error: let error):
                print("Transaction signing failed! Error: |\(error)|")
               
                switch error {
                case .requestFailed(let message):
                    XCTAssertEqual("\(message)", "Transaction\'s source account is no match for signer\'s public key!")
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testTransactionXDRMissing() {
        let expectation = XCTestExpectation(description: "The transaction is missing from the url!")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let url = "web+stellar:tx?xdr=asdasdsadsadsa"
        uriBuilder.signTransaction(forURL: url, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .failure(error: let error):
                print("Transaction missing from url! Error: \(error)")
                
                switch error {
                case .requestFailed(let message):
                    XCTAssertEqual("\(message)", "TransactionXDR missing from url!")
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testConfirmationTransaction() {
        let expectation = XCTestExpectation(description: "The transaction is going to be canceled by not confirming it!")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair, transactionConfirmation: { (transaction) -> (Bool) in
            return false
        }) { (response) -> (Void) in
            switch response {
            case .failure(error: let error):
                print("Transaction was not confirmed! Error: \(error)")
            
                switch error {
                case .requestFailed(let message):
                    XCTAssertEqual("\(message)", "Transaction was not confirmed!")
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15)
    }
    
}

