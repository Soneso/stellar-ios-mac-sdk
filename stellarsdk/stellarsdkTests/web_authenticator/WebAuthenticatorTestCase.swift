//
//  WebAuthenticatorTestCase.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 16/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class WebAuthenticatorTestCase: XCTestCase {

    let domain = "place.domain.com"
    let failureDomain = "place.domainfail.com"
    let authServer = "http://api.stellar.org/auth"
    
    let serverPublicKey = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverPrivateKey = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"
    
    let clientPublicKey = "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V"
    let clientPrivateKey = "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX"
    
    let challengeFailClientPublicKey = "GBCJQ6Q7PVSRZJA26A76AP4UJM4WORKUSMDEIAAZLYR4HHRG3GQI4GUZ"
    let challengeFailClientPrivateKey = "SAV2BMOC7IX476E7N77BNOU7JPGA4N7S2TDWC4XQT4P65LONR7K3JQ2N"
    
    let invalidSeqClientPublicKey = "GAUQO2IDU23EJGLTUTOLSL2VBSWCS3YCVUBP3FET6VQJAUULNZ5CCW3Y"
    let invalidSeqClientPrivateKey = "SD3AK7UCZVLNKP77ZFLR56ANIJMOKZNUYXYC5WRBVN64JLVHRNWAH3YH"
    
    let invalidSourceAccClientPublicKey = "GDWPRWTBZBVNUBRPHQXOKIJR4GRAALJ34HWHEWO7O3GGLJ5DA3XKSLMD"
    let invalidSourceAccClientPrivateKey = "SCVSDWZLT5GX226FLMASRDYG3YQHRKFT3NQ3VJGGIQZJVPU2TSOKJ5MY"
    
    let invalidOperationClientPublicKey = "GDRNSOWWZWLVFMBY4ZUUFVJXWYRVVGCC7ALXNEWZU7X2TODIRHAZANNA"
    let invalidOperationClientPrivateKey = "SBCUVXRTONIII2HOZLCXQUSNMBKFLZBSN3BEZKTP7ACPBG5DZQEV62F5"
    
    let invalidOperationCountClientPublicKey = "GDTJSQ4KGWKKYDIAR5WKMKDQVNKK2BUR6KY43VWZ464T6FWJHHIG7ZI4"
    let invalidOperationCountClientPrivateKey = "SATMX7DQZVWXB5RZMPYD7G2E3OBFWIDGUTAL5WWGS3AFILWFFLAOGVXH"
    
    let invalidTimeboundsClientPublicKey = "GBLIKSJM67PCYH7CNFLQETPPOWATL2PVH2SY7WGWDQEOK47FANF3PIIX"
    let invalidTimeboundsClientPrivateKey = "SDQXB7ELE6BHRUCLOTNPCGAJ6YSI3G5GPWTESG72QOQXHNUBRCPK7HMT"
    
    let invalidSignatureClientPublicKey = "GBPFFS63LXKHUL5SFJAI4737JJ2UHEQJXKJRQ3BFBN2PQC4RQ2OLMPSY"
    let invalidSignatureClientPrivateKey = "SCNNPRMRJSIEZ2M64YP5TKM3P2XPJJDEQ2YS33RA5Y4GS7AOJHKLXVP4"
    
    let notFoundSignatureClientPublicKey = "GBGWIAAKWQFGARYINLHSPFIQCHMMGNJICNRRO435L4AP7DNYYHYMNFFT"
    let notFoundSignatureClientPrivateKey = "SCQQ7D5THZ7PHFENLAHVXBD6BFSYGIISKCZBWZRRZAVZLQYLOPZMFZXF"
    
    let invalidClientSignatureClientPublicKey = "GA5YLRKU57II42AXED2LA3IO2AL4URSVO3WXI7CIE4KJDPJSSRUSDJU7"
    let invalidClientSignatureClientPrivateKey = "SDVWGHMSMSCGXYFQ5ROYPQLXC3ULIM6IDPS5ERSY4DELIXP3U7NWP36P"
    
    var tomlServerMock: WebAuthenticatorTomlResponseMock!
    var tomlFailServerMock: WebAuthenticatorTomlFailResponseMock!
    var challengeServerMock: WebAuthenticatorChallengeResponseMock!
    var sendChallengeServerMock: WebAuthenticatorSendChallengeResponseMock!
    
    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)
        
        tomlServerMock = WebAuthenticatorTomlResponseMock(address: domain, serverSigningKey: serverPublicKey, authServer: authServer)
        tomlFailServerMock = WebAuthenticatorTomlFailResponseMock(address: failureDomain, serverSigningKey: serverPublicKey, authServer: authServer)
        challengeServerMock = WebAuthenticatorChallengeResponseMock(address: "api.stellar.org", serverKeyPair: try! KeyPair(secretSeed: serverPrivateKey))
        sendChallengeServerMock = WebAuthenticatorSendChallengeResponseMock(address: "api.stellar.org")
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

    func testWebAuthenticatorFromDomainFailure() {
        let expectation = XCTestExpectation(description: "WebAuthenticator call fails.")
        try? WebAuthenticator.from(domain: failureDomain, network: .testnet) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(_):
                XCTAssert(true)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetJWTSuccess() {
        let expectation = XCTestExpectation(description: "JWT is received with success.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: clientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(_):
                    XCTAssert(false)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeFailure() {
        let expectation = XCTestExpectation(description: "A request error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: challengeFailClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .requestError(_):
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeInvalidSequenceNumber() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidSeqClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .sequenceNumberNot0 {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeInvalidSourceAccount() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidSourceAccClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .invalidSourceAccount {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeInvalidOperationType() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidOperationClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .invalidOperationType {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeInvalidOperationCount() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidOperationCountClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .invalidOperationCount {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeInvalidTimebounds() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidTimeboundsClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .invalidTimeBounds {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeInvalidSignature() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidSignatureClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .invalidSignature {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetChallengeSignatureNotFound() {
        let expectation = XCTestExpectation(description: "A validation error is received.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: notFoundSignatureClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .validationErrorError(let error):
                        if error == .signatureNotFound {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSendChallengeInvalidSignature() {
        let expectation = XCTestExpectation(description: "A server error for invalid signature.")
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey)
        if let keyPair = try? KeyPair(secretSeed: invalidClientSignatureClientPrivateKey) {
            webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(false)
                case .failure(let error):
                    switch error {
                    case .requestError(let error):
                        switch error {
                        case .requestFailed(let message):
                            XCTAssert(message == "The provided transaction is not valid")
                        default:
                            XCTAssert(false)
                        }
                    default:
                        XCTAssert(false)
                    }
                    
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
}
