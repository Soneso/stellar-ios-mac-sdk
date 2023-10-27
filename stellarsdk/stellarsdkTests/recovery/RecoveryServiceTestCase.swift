//
//  RecoveryServiceTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//


import XCTest
import stellarsdk

class RecoveryServiceTestCase: XCTestCase {

    let recoveryServer = "127.0.0.1"
    let addressA = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let signingAddress = "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA"
    let after = "GA5TKKASNJZGZAP6FH65HO77CST7CJNYRTW4YPBNPXYMZAHHMTHDZKDQ"
    let jwtToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";
    
    let senderAddrAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
    let senderPhoneAuth = Sep30AuthMethod(type: "phone_number", value: "+10000000001")
    let senderEmailAuth = Sep30AuthMethod(type: "email", value: "person1@example.com")
    
    let receiverAddrAuth = Sep30AuthMethod(type: "stellar_address", value: "GDIL76BC2XGDWLDPXCZVYB3AIZX4MYBN6JUBQPAX5OHRWPSNX3XMLNCS")
    let receiverPhoneAuth = Sep30AuthMethod(type: "phone_number", value: "+10000000002")
    let receiverEmailAuth = Sep30AuthMethod(type: "email", value: "person2@example.com")
    
    var senderIdentity:Sep30RequestIdentity!
    var receiverIdentity:Sep30RequestIdentity!
    
    let transaction =
        "AAAAAgAAAABswQhbaeSlgckYVKxb8pH08s5tqVVpGXYw1kCpbqv6lQAAAGQAIa4PAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACWhlbGxvLmNvbQAAAAAAAAAAAAAAAAAAAA==";
    let signature = "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS";
    let networkPassphrase = "Test SDF Network ; September 2015";
    
    var recoveryService: RecoveryService!
    var sep30RegisterAccountMock: Sep30RegisterAccountResponseMock!
    var sep30UpdateIdentitiesMock: Sep30UpdateIdentitiesResponseMock!
    var sep30SignTransactionMock: Sep30SignTransactionResponseMock!
    var sep30AccountDetailsMock: Sep30AccountDetailsResponseMock!
    var sep30DeleteAccountMock: Sep30DeleteAccountResponseMock!
    var sep30ListAccountsMock: Sep30ListAccountsResponseMock!
    var sep30BadRequestErrMock: Sep30ErrResponseMock!
    var sep30UnauthRequestErrMock: Sep30ErrResponseMock!
    var sep30NotFoundRequestErrMock: Sep30ErrResponseMock!
    
    override func setUp() {
        super.setUp()
                
        URLProtocol.registerClass(ServerMock.self)
        sep30RegisterAccountMock = Sep30RegisterAccountResponseMock(host: recoveryServer, address: addressA)
        sep30UpdateIdentitiesMock = Sep30UpdateIdentitiesResponseMock(host: recoveryServer, address: addressA)
        sep30SignTransactionMock = Sep30SignTransactionResponseMock(host: recoveryServer, address: addressA, signingAddress: signingAddress)
        sep30AccountDetailsMock = Sep30AccountDetailsResponseMock(host: recoveryServer, address: addressA)
        sep30DeleteAccountMock = Sep30DeleteAccountResponseMock(host: recoveryServer, address: addressA)
        sep30ListAccountsMock = Sep30ListAccountsResponseMock(host: recoveryServer)
        sep30BadRequestErrMock = Sep30ErrResponseMock(host: recoveryServer, address: "BAD_REQ")
        sep30UnauthRequestErrMock = Sep30ErrResponseMock(host: recoveryServer, address: "UNAUTH")
        sep30NotFoundRequestErrMock = Sep30ErrResponseMock(host: recoveryServer, address: "NOT_FOUND")
        recoveryService = RecoveryService(serviceAddress: "http://\(recoveryServer)")
        senderIdentity = Sep30RequestIdentity(role: "sender", authMethods: [senderAddrAuth, senderPhoneAuth, senderEmailAuth])
        receiverIdentity = Sep30RequestIdentity(role: "receiver", authMethods: [receiverAddrAuth, receiverPhoneAuth, receiverEmailAuth])

    }
    
    
    func testRegisterAccount() {
        let expectation = XCTestExpectation(description: "Test sep30 register account")
        
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        recoveryService.registerAccount(address: addressA, request: request, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(self.addressA, response.address)
                XCTAssertEqual(2, response.identities.count)
                XCTAssertEqual(1, response.signers.count)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testUpdateIdentities() {
        let expectation = XCTestExpectation(description: "Test sep30 update identities")
        
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        recoveryService.updateIdentitiesForAccount(address: addressA, request: request, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(self.addressA, response.address)
                XCTAssertEqual(2, response.identities.count)
                XCTAssertEqual(1, response.signers.count)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSignTransaction() {
        let expectation = XCTestExpectation(description: "Test sep30 sign transaction")
        
        recoveryService.signTransaction(address: addressA, signingAddress: signingAddress, transaction:transaction, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(self.signature, response.signature)
                XCTAssertEqual(self.networkPassphrase, response.networkPassphrase)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAccountDetails() {
        let expectation = XCTestExpectation(description: "Test sep30 account details")
        
        recoveryService.accountDetails(address: addressA, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(self.addressA, response.address)
                XCTAssertEqual(2, response.identities.count)
                XCTAssertEqual(1, response.signers.count)
                XCTAssertTrue(response.identities[0].authenticated!)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteAccount() {
        let expectation = XCTestExpectation(description: "Test sep30 delete account")
        
        recoveryService.deleteAccount(address: addressA, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(self.addressA, response.address)
                XCTAssertEqual(2, response.identities.count)
                XCTAssertEqual(1, response.signers.count)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testListAccounts() {
        let expectation = XCTestExpectation(description: "Test sep30 list accounts")
        
        recoveryService.accounts(jwt: jwtToken, after: after) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(3, response.accounts.count)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testBadReqErr() {
        let expectation = XCTestExpectation(description: "Test sep30 bad request")
        
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        recoveryService.registerAccount(address: "BAD_REQ", request: request, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTFail("should not succeed")
            case .failure(let err):
                switch err{
                case .badRequest(let message):
                    XCTAssertEqual("bad request", message)
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testUnauthorizedErr() {
        let expectation = XCTestExpectation(description: "Test sep30 unauthorized")
        
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        recoveryService.registerAccount(address: "UNAUTH", request: request, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTFail("should not succeed")
            case .failure(let err):
                switch err{
                case .unauthorized(let message):
                    XCTAssertEqual("unauthorized", message)
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testNotFoundErr() {
        let expectation = XCTestExpectation(description: "Test sep30 not found")
        
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        recoveryService.registerAccount(address: "NOT_FOUND", request: request, jwt: jwtToken) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTFail("should not succeed")
            case .failure(let err):
                switch err{
                case .notFound(let message):
                    XCTAssertEqual("not found", message)
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
