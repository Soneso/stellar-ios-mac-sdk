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
    let accountID = "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"
    let secretSeed = "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF"
    
    let unsignedURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAACAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com"

    let signedURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAACAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAA%3D%3D&signature=ggKDaF580XxQB77YgEsyu2HvkX4gpUY3m0WPhsR6wATD5%2BTDiiHMMp%2FpsQP%2FBlNCAz8GAiXnTymKHmAKvS4HAw%3D%3D"

    let validURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAACAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com&signature=ggKDaF580XxQB77YgEsyu2HvkX4gpUY3m0WPhsR6wATD5%2BTDiiHMMp%2FpsQP%2FBlNCAz8GAiXnTymKHmAKvS4HAw%3D%3D"
    
    let validURLCallback = "web+stellar:tx?xdr=AAAAAM1C8kJqGxGKNEVcweDIZd1qv3lbJr040EWYUY5EFmRYAAAAZAAAfvoAAAAdAAAAAAAAAAAAAAABAAAAAAAAAAkAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com&signature=ca5NoydAhPz10%2BFTGLN4gThguXfB%2FL2xO31wlcNu87ypmM2deNFdyXFWkgxwIirGOvQOtgRZvW%2BkwC%2Bucu4MBA%3D%3D&callback=url:https://examplePost.com"
    
    let uriValidator = URISchemeValidator()
    
    var tomlResponseMock: TomlResponseMock!
    var tomlResponseSignatureMismatchMock: TomlResponseSignatureMismatchMock!
    var tomlResponseSignatureMissingMock: TomlResponseSignatureMissingMock!
    var postCallbackMock: PostCallbackMock!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        
        postCallbackMock = PostCallbackMock(address: "examplePost.com")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tomlResponseMock = nil
        tomlResponseSignatureMismatchMock = nil
        tomlResponseSignatureMissingMock = nil
        super.tearDown()
    }
    
    func testGetTransactionOperationURIScheme() {
        let expectation = XCTestExpectation(description: "URL Returned.")
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.inflation
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation])
                try! transaction.sign(keyPair: keyPair, network: .testnet)
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
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let uriSchemeBuilder = URIScheme()
        let uriScheme = uriSchemeBuilder.getPayOperationURI(accountID: keyPair.accountId, amount: 123.21,assetCode: "ANA", assetIssuer: "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV")
        print("PayOperationURI: \(uriScheme)")
        expectation.fulfill()
    }
    
    func testMissingSignatureFromURIScheme() {
        let expectation = XCTestExpectation(description: "Missing signature failure.")
        tomlResponseMock = TomlResponseMock(address: "place.domain.com")
        uriValidator.checkURISchemeIsValid(url: unsignedURL) { (response) -> (Void) in
            switch response {
            case .failure(let error):
                if error == URISchemeErrors.missingSignature {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testMissingDomainFromURIScheme() {
        let expectation = XCTestExpectation(description: "Missing origin domain failure.")
        
        uriValidator.checkURISchemeIsValid(url: signedURL) { (response) -> (Void) in
            switch response {
            case .failure(let error):
                if error == URISchemeErrors.missingOriginDomain{
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }

            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testSigningURI() {
        let expectation = XCTestExpectation(description: "Signed URL returned.")
        let keyPair = try! KeyPair(secretSeed: secretSeed)
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
        tomlResponseMock = TomlResponseMock(address: "place.domain.com")
        uriValidator.checkURISchemeIsValid(url: validURL) { (response) -> (Void) in
            switch response {
                case .success:
                    XCTAssert(true)
                case .failure(let error):
                    print("ValidURIScheme Error: \(error)")
                    XCTAssert(false)
            }

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTransactionSigning() {
        let expectation = XCTestExpectation(description: "The transaction is signed and sent to the stellar network")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .destinationRequiresMemo(let destinationAccountId):
                print("Destination requires memo \(destinationAccountId)")
                XCTAssert(false)
            case .failure(error: let error):
                XCTAssert(false)
                print("Transaction signing failed! Error: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testTransactionSigningCallback() {
        let expectation = XCTestExpectation(description: "The transaction is signed and sent to the callback")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        uriBuilder.signTransaction(forURL: validURLCallback, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .destinationRequiresMemo(let destinationAccountId):
                print("Destination requires memo \(destinationAccountId)")
                XCTAssert(false)
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
        let keyPair = try! KeyPair(secretSeed: secretSeed)
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
        let keyPair = try! KeyPair(secretSeed: secretSeed)
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
    
    
    func testTomlSignatureMismatch() {
        tomlResponseSignatureMismatchMock = TomlResponseSignatureMismatchMock(address: "place.domain.com")
        let expectation = XCTestExpectation(description: "The signature from the toml file is a mismatch with the one cached!")
        
        uriValidator.checkURISchemeIsValid(url: validURL, warningClosure: {
            XCTAssert(true)
            expectation.fulfill()
        }) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTomlSignatureMissing() {
        let expectation = XCTestExpectation(description: "The signature field is missing from the toml file!")
        tomlResponseSignatureMissingMock = TomlResponseSignatureMissingMock(address: "place.domain.com")
        
        uriValidator.checkURISchemeIsValid(url: validURL) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                print("ValidURIScheme Error: \(error)")
                if error == URISchemeErrors.tomlSignatureMissing {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)

    }
}

