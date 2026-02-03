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
    
    override func setUp() async throws {
        try await super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        postCallbackMock = PostCallbackMock(address: "examplePost.com")
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: accountID);
        switch accDetailsResEnum {
        case .success(_):
            return
        case .failure(_):
            let responseEnum = await sdk.accounts.createTestAccount(accountId: accountID)
            switch responseEnum {
            case .success(_):
                return
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
                XCTFail("could not create test account: \(accountID)")
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tomlResponseMock = nil
        tomlResponseSignatureMismatchMock = nil
        tomlResponseSignatureMissingMock = nil
        super.tearDown()
    }
    
    func testAll() async {
        await generateUnsignedTxTestUrl()
        generatePaymentOperationURIScheme()
        await checkMissingSignatureFromURIScheme()
        await checkMissingDomainFromURIScheme()
        generateSignedTxTestUrl()
        await validateTestUrl()
        await signAndSubmitTransaction()
        
        await generateUnsignedTxTestUrl()
        generateSignedCallbackTxTestUrl()
        await signAndSubmitCallbackTxUrl()
        await checkTransactionXDRMissing()
        await checkNotConfirmed()
        await checkTomlSignatureMissing()
    }
    
    func generateUnsignedTxTestUrl() async {
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId);
        switch accDetailsResEnum {
        case .success(let data):
            let op = try! SetOptionsOperation(sourceAccountId: keyPair.accountId, homeDomain: "www.soneso.com")
            let transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, cond: PreconditionsXDR.none, memo: .none, operations: [try! op.toXDR()])
            let uriSchemeBuilder = URIScheme()
            let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction)
            XCTAssert(uriScheme.hasPrefix("web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9O"))
            self.signedTestUrl = uriScheme
            self.unsignedTestUrl = uriScheme + self.originDomainParam
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"generateUnsignedTxTestUrl()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func generatePaymentOperationURIScheme() {
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let uriSchemeBuilder = URIScheme()
        let uriScheme = uriSchemeBuilder.getPayOperationURI(destination: keyPair.accountId, amount: 123.21,assetCode: "ANA", assetIssuer: "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV")
        XCTAssertEqual("web+stellar:pay?destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV&amount=123.21&asset_code=ANA&asset_issuer=GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV", uriScheme)
    }
    
    func checkMissingSignatureFromURIScheme() async {
        tomlResponseMock = TomlResponseMock(address: "place.domain.com")
        let responseEnum = await uriValidator.checkURISchemeIsValid(url: self.unsignedTestUrl!)
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            XCTAssertEqual(URISchemeErrors.missingSignature, error)
        }
    }

    func checkMissingDomainFromURIScheme() async {
        let responseEnum = await uriValidator.checkURISchemeIsValid(url: self.signedTestUrl!)
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            XCTAssertEqual(URISchemeErrors.missingOriginDomain, error)
        }
    }
    
    func generateSignedTxTestUrl() {
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let responseEnum = uriValidator.signURI(url: self.unsignedTestUrl!, signerKeyPair: keyPair)
        switch responseEnum {
        case .success(let signedURL):
            self.validTestUrl = signedURL
        case .failure(_):
            XCTFail()
        }
    }

    func validateTestUrl() async {
        let responseEnum = await uriValidator.checkURISchemeIsValid(url: self.validTestUrl!)
        switch responseEnum {
        case .success:
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    func signAndSubmitTransaction() async {
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let responseEnum = await uriBuilder.signAndSubmitTransaction(forURL: self.validTestUrl!, signerKeyPair: keyPair)
        switch responseEnum {
        case .success:
            return
        case .destinationRequiresMemo(let destinationAccountId):
            print("Destination requires memo \(destinationAccountId)")
            XCTFail()
        case .failure(let error):
            print("Transaction signing failed! Error: \(error)")
            XCTFail()
        }
    }
    
    func generateSignedCallbackTxTestUrl() {
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let result = uriValidator.signURI(url: self.unsignedTestUrl!, signerKeyPair: keyPair)
        switch result {
            case .success(signedURL: let signedURL):
                self.validCallbackTestUrl = signedURL + self.callbackParam
            case .failure:
                XCTFail()
        }
    }
    
    func signAndSubmitCallbackTxUrl() async {
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let responseEnum = await uriBuilder.signAndSubmitTransaction(forURL: self.validCallbackTestUrl!, signerKeyPair: keyPair)
        switch responseEnum {
        case .success:
            return
        case .destinationRequiresMemo(let destinationAccountId):
            print("Destination requires memo \(destinationAccountId)")
            XCTFail()
        case .failure(let error):
            print("Transaction signing failed! Error: \(error)")
            XCTFail()
        }
    }
    
    func checkTransactionXDRMissing() async {
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let url = "web+stellar:tx?xdr=asdasdsadsadsa"
        let responseEnum = await uriBuilder.signAndSubmitTransaction(forURL: url, signerKeyPair: keyPair)
        switch responseEnum {
        case .failure(let error):
            switch error {
            case .requestFailed(let message, _):
                XCTAssertEqual("TransactionXDR missing from url!", message)
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }
    
    func checkNotConfirmed() async {
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: secretSeed)
        let responseEnum = await uriBuilder.signAndSubmitTransaction(forURL: self.validTestUrl!, signerKeyPair: keyPair, transactionConfirmation: { (transaction) -> (Bool) in
            return false
        })
        switch responseEnum {
        case .failure(let error):
            switch error {
            case .requestFailed(let message, _):
                XCTAssertEqual("Transaction was not confirmed!", message)
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }
    
    func checkTomlSignatureMissing() async {
        tomlResponseMock = nil
        tomlResponseSignatureMissingMock = TomlResponseSignatureMissingMock(address: "place.domain.com")
        
        let responseEnum = await uriValidator.checkURISchemeIsValid(url: self.validTestUrl!)
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            XCTAssertEqual(URISchemeErrors.tomlSignatureMissing, error)
        }
    }
    
}

