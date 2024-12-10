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
    
    let validSecondOperationClientPublicKey = "GDTQAJVJMEDWCSSSBZ54KFURMUJ4RKSCBBPGTNXVWOK6LZDN5TL6F3EA"
    let validSecondOperationClientPrivateKey = "SAYFONLAHNWZACB6QM2SUKTCVN3NAHGD74VZSBBUD3SWBFKXKDN7QN2R"
    
    let invalidSecondOperationClientPublicKey = "GA3BS4KS3XR4KEYG5QD6RSELGTCYQDETRISIVLWCMHI243NFYCLR7NSE"
    let invalidSecondOperationClientPrivateKey = "SBMU3KPO7J2JGMAQ5GIX4A7OAWKGWIY6XSLMVLUV2TAZOB5QE3EDLDAW"
    
    let invalidOperationCountClientPublicKey = "GDTJSQ4KGWKKYDIAR5WKMKDQVNKK2BUR6KY43VWZ464T6FWJHHIG7ZI4"
    let invalidOperationCountClientPrivateKey = "SATMX7DQZVWXB5RZMPYD7G2E3OBFWIDGUTAL5WWGS3AFILWFFLAOGVXH"
    
    let invalidHomeDomainClientPublicKey = "GCN2YSJLDRFN2VZKDVQU4ARHHTRS6X7QD4Q6IO4D3DIVVARVPRK5CPKU"
    let invalidHomeDomainClientPrivateKey = "SDAIVVH6QK47Z3EMMQEUQLVYRTJCJJ5IVQYFCOF2FXKM4EBOL7J4SPRI"
    
    let invalidWebAuthDomainClientPublicKey = "GBCWD4VLRY42JMWNPETGDPY6HSVHQ7YPOM73KALIWEJXIK4OIN5SSY3S"
    let invalidWebAuthDomainClientPrivateKey = "SDTBVY7LW6AJVEXOO3SEY3T7UN34KQYS7P5T4HIR6UXRGSZ6EVYYA4ND"
    
    let invalidTimeboundsClientPublicKey = "GBLIKSJM67PCYH7CNFLQETPPOWATL2PVH2SY7WGWDQEOK47FANF3PIIX"
    let invalidTimeboundsClientPrivateKey = "SDQXB7ELE6BHRUCLOTNPCGAJ6YSI3G5GPWTESG72QOQXHNUBRCPK7HMT"
    
    let invalidSignatureClientPublicKey = "GBPFFS63LXKHUL5SFJAI4737JJ2UHEQJXKJRQ3BFBN2PQC4RQ2OLMPSY"
    let invalidSignatureClientPrivateKey = "SCNNPRMRJSIEZ2M64YP5TKM3P2XPJJDEQ2YS33RA5Y4GS7AOJHKLXVP4"
    
    let notFoundSignatureClientPublicKey = "GBGWIAAKWQFGARYINLHSPFIQCHMMGNJICNRRO435L4AP7DNYYHYMNFFT"
    let notFoundSignatureClientPrivateKey = "SCQQ7D5THZ7PHFENLAHVXBD6BFSYGIISKCZBWZRRZAVZLQYLOPZMFZXF"
    
    let invalidClientSignatureClientPublicKey = "GA5YLRKU57II42AXED2LA3IO2AL4URSVO3WXI7CIE4KJDPJSSRUSDJU7"
    let invalidClientSignatureClientPrivateKey = "SDVWGHMSMSCGXYFQ5ROYPQLXC3ULIM6IDPS5ERSY4DELIXP3U7NWP36P"
    
    let invalidCliendDomainOpSourceAccountClientPublicKey = "GCK2PNGZBGBZCULG6QHYQUPIM2DXNXCJKLFMC2SPDX2B5A54IR4Q5KE3"
    let invalidCliendDomainOpSourceAccountClientPrivateKey = "SCNXWUEAO3RHFFERXGDYJLLJ6UPZZGIA6B3NJ32UNOYTI4KD7OXHXLMK"
    
    let validCliendDomainOpSourceAccountClientPublicKey = "GDBEDW4SYL3NJY2ILKUE2MX7CU6BQKSK6UXZUHVOLZL2R3BKRLBEJRXC"
    let validCliendDomainOpSourceAccountClientPrivateKey = "SCNIS3DPXJ4PN27YGG7OGFTKAM73KAGL6PT6QA4CDIIKDDDPMUHCGCS4"
    
    let challengeMuxedAccountIdM = "MC6PZZU7XEYLCV7XW5LZC3J72HKQ7CABZCLVGPXCPLLRPZ4SJHC2UAAAAAAACMICQPLEG"
    let challengeMuxedAccountIdG = "GC6PZZU7XEYLCV7XW5LZC3J72HKQ7CABZCLVGPXCPLLRPZ4SJHC2US3P"
    let challengeMuxedAccountIdGMemo:UInt64 = 19989123
    let challengeMuxedAccountSeed = "SB7BORUWGKD6QVQMMOB556OPCIU6PXC4KOJ7WNQJGYK724XZA6IFRJL3"
    
    let invalidMemoTypeClientPublicKey = "GB5PZY253VWYRF47YMNFIWO3U6BG2SD2457FNQVFO4CLOAIUEN5IG7P7"
    let invalidMemoTypeClientPrivateKey = "SCAJCHEEXKL6K4QGC4I7NGTTGS2KH7BTYKCF2DQRDQC5NCQKADJIQNHR"
    
    let invalidMemoValueClientPublicKey = "GCEQZYKOEJTZET2AKUY664EM44VFNRIAH7AXE4RIDWFV6UYGDTJWD2JJ"
    let invalidMemoValueClientPrivateKey = "SCB62HPSFTIEKNXQ7SRN4ZDUCVUZ6N25ZJZXWMSBHOBA4PPFDFWT5TUQ"
    
    let validClientDomainAccountSeed = "SBE64KCQLJXJPMYLF22YCUSTH7WXJ7VZSCTPHXY3VDSIF3QUHJDBE6R6"
    let invalidClientDomainAccountSeed = "SBPDX5WBTUMZC6WV57AVTLCROF4X6ETNSCCTFHWYI5QIQWAYYXWVVYWK"
    
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

    func testWebAuthenticatorFromDomainSuccess() async {
        let responseEnum = await WebAuthenticator.from(domain: domain, network: .testnet)
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }

    func testWebAuthenticatorFromDomainFailure() async {
        let responseEnum = await WebAuthenticator.from(domain: failureDomain, network: .testnet)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(_):
            return
        }
    }
    
    func testGetJWTSuccess() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: clientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    func testGetChallengeFailure() async {
        
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: challengeFailClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .requestError(_):
                return
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidSequenceNumber() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidSeqClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .sequenceNumberNot0 {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidSourceAccount() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidSourceAccClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidSourceAccount {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeValidSecondOperation() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: validSecondOperationClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    
    func testGetChallengeInvalidSecondSourceAccount() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidSecondOperationClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidSourceAccount {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidOperationType() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidOperationClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidOperationType {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidOperationCount() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidOperationCountClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidOperationCount {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidHomeDomain() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidHomeDomainClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidHomeDomain {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidWebAuthDomain() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidWebAuthDomainClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidWebAuthDomain {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidTimebounds() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidTimeboundsClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidTimeBounds {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidSignature() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidSignatureClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidSignature {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeSignatureNotFound() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: notFoundSignatureClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .signatureNotFound {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testSendChallengeInvalidSignature() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidClientSignatureClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .requestError(let error):
                switch error {
                case .requestFailed(let message, _):
                    XCTAssertEqual("The provided transaction is not valid", message)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidClientDomainOpSourceAccount() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidCliendDomainOpSourceAccountClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidSourceAccount {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeValidClientDomainOpSourceAccount() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: validCliendDomainOpSourceAccountClientPrivateKey)
        let userAccountId = keyPair.accountId
        let clientDomain = "domain.client.com"
        let clientDomainAccountKey = try! KeyPair(secretSeed:validClientDomainAccountSeed)
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair], clientDomain: clientDomain, clientDomainAccountKeyPair: clientDomainAccountKey)
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    func testValidClientDomainAccountSignature() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: validCliendDomainOpSourceAccountClientPrivateKey)
        let userAccountId = keyPair.accountId
        let clientDomain = "domain.client.com"

        // client domain signing via signing key pair (not recomended, because the app should not hold the client domain signing key)
        // this key pair contains the client domain signing private key
        let clientDomainAccountSigningKey = try! KeyPair(secretSeed:validClientDomainAccountSeed)
        var responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, signers: [keyPair], clientDomain: clientDomain, clientDomainAccountKeyPair: clientDomainAccountSigningKey)
        switch responseEnum {
        case .success(_):
            break
        case .failure(_):
            XCTFail()
        }
        
        // client domain signing via signing function (recommended, client domain signing shold be done on the client domain server)
        // this key pair does not contain the client domain signing private key
        let clientDomainAccountNotSigningKey = try! KeyPair(accountId: clientDomainAccountSigningKey.accountId)
        responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId,
                                                           signers: [keyPair],
                                                           clientDomain: clientDomain,
                                                           clientDomainAccountKeyPair: clientDomainAccountNotSigningKey,
                                                           clientDomainSigningFunction: validClientDomainAccountSigningFunction)
        switch responseEnum {
        case .success(_):
            break
        case .failure(_):
            XCTFail()
        }
    }

    func validClientDomainAccountSigningFunction(txEnvelopeXdr:String) async throws -> String {
        return try await clientDomainSigning (txEnvelopeXdr: txEnvelopeXdr, seed: validClientDomainAccountSeed)
    }
    
    func clientDomainSigning(txEnvelopeXdr:String, seed:String) async throws -> String {
        // normally this happens on the client domain server
        // this mocks the client domain server signing process:
        let envelopeXDR = try TransactionEnvelopeXDR(xdr: txEnvelopeXdr)
        let transactionHash = try [UInt8](envelopeXDR.txHash(network: .testnet))
        let clientDomainAccountKey = try! KeyPair(secretSeed:seed)
        let signature = clientDomainAccountKey.signDecorated(transactionHash)
        envelopeXDR.appendSignature(signature: signature)
        let encoded = try XDREncoder.encode(envelopeXDR)
        return Data(bytes: encoded, count: encoded.count).base64EncodedString()
    }
    
    func invalidClientDomainAccountSigningFunction(txEnvelopeXdr:String) async throws -> String {
        return try await clientDomainSigning (txEnvelopeXdr: txEnvelopeXdr, seed: invalidClientDomainAccountSeed)
    }
    
    func testInvalidClientDomainAccountSignature() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: validCliendDomainOpSourceAccountClientPrivateKey)
        let userAccountId = keyPair.accountId
        let clientDomain = "domain.client.com"
        
        // client domain signing via signing key pair (not recomended, because the app should not hold the client domain signing key)
        // this key pair contains the client domain signing private key
        let clientDomainAccountSigningKey = try! KeyPair(secretSeed:invalidClientDomainAccountSeed)
        var responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId,
                                                           signers: [keyPair],
                                                           clientDomain: clientDomain,
                                                           clientDomainAccountKeyPair: clientDomainAccountSigningKey)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(_):
            break
        }
        
        // client domain signing via signing key pair (not recomended, because the app should not hold the client domain signing key)
        // this key pair does not contain the client domain signing private key
        let clientDomainAccountNotSigningKey = try! KeyPair(accountId: clientDomainAccountSigningKey.accountId)
        responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId,
                                                       signers: [keyPair],
                                                       clientDomain: clientDomain,
                                                       clientDomainAccountKeyPair: clientDomainAccountNotSigningKey,
                                                       clientDomainSigningFunction: invalidClientDomainAccountSigningFunction)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(_):
            break
        }
    }
        
    func testGetJWTMemoSuccess() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: challengeMuxedAccountSeed)
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: challengeMuxedAccountIdG, memo: challengeMuxedAccountIdGMemo, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    func testGetJWTMuxedNoMemoSuccess() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: challengeMuxedAccountSeed)
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: challengeMuxedAccountIdM, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    func testGetJWTMuxedAndMemoFail() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: challengeMuxedAccountSeed)
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: challengeMuxedAccountIdM, memo:challengeMuxedAccountIdGMemo, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .requestError(_):
                return
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidMemoType() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidMemoTypeClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, memo: 12345, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidMemoType {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testGetChallengeInvalidMemoValue() async {
        let webAuthenticator = WebAuthenticator(authEndpoint: authServer, network: .testnet, serverSigningKey: serverPublicKey, serverHomeDomain: domain)
        let keyPair = try! KeyPair(secretSeed: invalidMemoValueClientPrivateKey)
        let userAccountId = keyPair.accountId
        let responseEnum = await webAuthenticator.jwtToken(forUserAccount: userAccountId, memo: 12345, signers: [keyPair])
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .validationErrorError(let error):
                if error != .invalidMemoValue {
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
}
