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
    
    let originDomainParam = "&origin_domain=place.domain.com"
    let callbackParam = "&callback=url:https://examplePost.com"
    var unsignedTestUrl:String? = nil
    var signedTestUrl:String? = nil
    var validTestUrl:String? = nil
    var validCallbackTestUrl:String? = nil
    
    let uriValidator = URISchemeValidator()
    
    var tomlResponseMock: TomlResponseMock!
    var tomlResponseSignatureMismatchMock: TomlResponseSignatureMismatchMock!
    var tomlResponseSignatureMissingMock: TomlResponseSignatureMissingMock!
    var postCallbackMock: PostCallbackMock!
    
    override func setUp() {
        super.setUp()
        
        let expectation = XCTestExpectation(description: "account prepared for tests")
        
        URLProtocol.registerClass(ServerMock.self)
        postCallbackMock = PostCallbackMock(address: "examplePost.com")
        
        sdk.accounts.getAccountDetails(accountId: accountID) { (response) -> (Void) in
            switch response {
            case .success(_):
                expectation.fulfill()
                break
            case .failure(error: let error):
                switch error {
                case .notFound:
                    self.sdk.accounts.createTestAccount(accountId: self.accountID) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            expectation.fulfill()
                        case .failure(_):
                            XCTFail()
                        }
                    }
                default:
                    break
                }
            }
        }
        wait(for: [expectation], timeout: 25.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tomlResponseMock = nil
        tomlResponseSignatureMismatchMock = nil
        tomlResponseSignatureMissingMock = nil
        super.tearDown()
    }
    
    func testAll() {
        generateUnsignedTxTestUrl()
        generatePaymentOperationURIScheme()
        checkMissingSignatureFromURIScheme()
        checkMissingDomainFromURIScheme()
        generateSignedTxTestUrl()
        validateTestUrl()
        signAndSubmitTransaction()
        generateUnsignedTxTestUrl()
        generateSignedCallbackTxTestUrl()
        signAndSubmitCallbackTxUrl()
        checkTransactionXDRMissing()
        checkNotConfirmed()
        checkTomlSignatureMissing()
    }
    
    func generateUnsignedTxTestUrl() {
        XCTContext.runActivity(named: "generateUnsignedTxTestUrl") { activity in
            let expectation = XCTestExpectation(description: "unsigned test url created")
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let data):
                    let op = try! SetOptionsOperation(sourceAccountId: keyPair.accountId, homeDomain: "www.soneso.com")
                    let transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, cond: PreconditionsXDR.none, memo: .none, operations: [try! op.toXDR()])
                    let uriSchemeBuilder = URIScheme()
                    let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction)
                    XCTAssert(uriScheme.hasPrefix("web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9O"))
                    self.signedTestUrl = uriScheme
                    self.unsignedTestUrl = uriScheme + self.originDomainParam
                    XCTAssert(true)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createPoolShareTrustlineNotNative", horizonRequestError:error)
                    XCTAssert(false)
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func generatePaymentOperationURIScheme() {
        XCTContext.runActivity(named: "generatePaymentOperationURIScheme") { activity in
            let expectation = XCTestExpectation(description: "URL Returned.")
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            let uriSchemeBuilder = URIScheme()
            let uriScheme = uriSchemeBuilder.getPayOperationURI(destination: keyPair.accountId, amount: 123.21,assetCode: "ANA", assetIssuer: "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV")
            XCTAssertEqual("web+stellar:pay?destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV&amount=123.21&asset_code=ANA&asset_issuer=GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV", uriScheme)
            expectation.fulfill()
        }
    }
    
    func checkMissingSignatureFromURIScheme() {
        XCTContext.runActivity(named: "checkMissingSignatureFromURIScheme") { activity in
            let expectation = XCTestExpectation(description: "Missing signature failure.")
            tomlResponseMock = TomlResponseMock(address: "place.domain.com")
            uriValidator.checkURISchemeIsValid(url: self.unsignedTestUrl!) { (response) -> (Void) in
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
    }

    func checkMissingDomainFromURIScheme() {
        XCTContext.runActivity(named: "checkMissingSignatureFromURIScheme") { activity in
            let expectation = XCTestExpectation(description: "Missing origin domain failure.")
            
            uriValidator.checkURISchemeIsValid(url: self.signedTestUrl!) { (response) -> (Void) in
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
    }
    
    func generateSignedTxTestUrl() {
        XCTContext.runActivity(named: "generateSignedTxTestUrl") { activity in
            let expectation = XCTestExpectation(description: "Signed URL returned.")
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            let result = uriValidator.signURI(url: self.unsignedTestUrl!, signerKeyPair: keyPair)
            switch result {
                case .success(signedURL: let signedURL):
                    self.validTestUrl = signedURL
                    XCTAssert(true)
                case .failure:
                    XCTAssert(false)
            }
            expectation.fulfill()
        }
    }

    func validateTestUrl() {
        XCTContext.runActivity(named: "validateTestUrl") { activity in
            let expectation = XCTestExpectation(description: "URL is valid.")
            uriValidator.checkURISchemeIsValid(url: self.validTestUrl!) { (response) -> (Void) in
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
    }
    
    func signAndSubmitTransaction() {
        XCTContext.runActivity(named: "signTransaction") { activity in
            let expectation = XCTestExpectation(description: "The transaction is signed and sent to the stellar network")
            let uriBuilder = URIScheme()
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            uriBuilder.signAndSubmitTransaction(forURL: self.validTestUrl!, signerKeyPair: keyPair) { (response) -> (Void) in
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
    }
    
    func generateSignedCallbackTxTestUrl() {
        XCTContext.runActivity(named: "generateSignedTxTestUrl") { activity in
            let expectation = XCTestExpectation(description: "Signed URL returned.")
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            let result = uriValidator.signURI(url: self.unsignedTestUrl!, signerKeyPair: keyPair)
            switch result {
                case .success(signedURL: let signedURL):
                self.validCallbackTestUrl = signedURL + self.callbackParam
                    XCTAssert(true)
                case .failure:
                    XCTAssert(false)
            }
            expectation.fulfill()
        }
    }
    
    func signAndSubmitCallbackTxUrl() {
         XCTContext.runActivity(named: "signAndSubmitCallbackTxUrl") { activity in
             let expectation = XCTestExpectation(description: "The transaction is signed and sent to the callback")
             let uriBuilder = URIScheme()
             let keyPair = try! KeyPair(secretSeed: secretSeed)
             uriBuilder.signAndSubmitTransaction(forURL: self.validCallbackTestUrl!, signerKeyPair: keyPair) { (response) -> (Void) in
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
    }
    
    func checkTransactionXDRMissing() {
        XCTContext.runActivity(named: "checkTransactionXDRMissing") { activity in
            let expectation = XCTestExpectation(description: "The transaction is missing from the url!")
            let uriBuilder = URIScheme()
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            let url = "web+stellar:tx?xdr=asdasdsadsadsa"
            uriBuilder.signAndSubmitTransaction(forURL: url, signerKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .failure(error: let error):
                    switch error {
                    case .requestFailed(let message, _):
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
    }
    
    func checkNotConfirmed() {
        XCTContext.runActivity(named: "checkTransactionXDRMissing") { activity in
            let expectation = XCTestExpectation(description: "The transaction is going to be canceled by not confirming it!")
            let uriBuilder = URIScheme()
            let keyPair = try! KeyPair(secretSeed: secretSeed)
            uriBuilder.signAndSubmitTransaction(forURL: self.validTestUrl!, signerKeyPair: keyPair, transactionConfirmation: { (transaction) -> (Bool) in
                return false
            }) { (response) -> (Void) in
                switch response {
                case .failure(error: let error):
                    switch error {
                    case .requestFailed(let message, _):
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
    
    func checkTomlSignatureMissing() {
        XCTContext.runActivity(named: "checkTomlSignatureMissing") { activity in
            let expectation = XCTestExpectation(description: "The signature field is missing from the toml file!")
            tomlResponseMock = nil
            tomlResponseSignatureMissingMock = TomlResponseSignatureMissingMock(address: "place.domain.com")
            
            uriValidator.checkURISchemeIsValid(url: self.validTestUrl!) { (response) -> (Void) in
                switch response {
                case .success:
                    XCTAssert(false)
                case .failure(let error):
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
    
}

