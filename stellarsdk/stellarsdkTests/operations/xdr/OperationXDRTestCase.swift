//
//  OperationXDRTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/23/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationXDRTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetTransactionXdr() {
        let expectation = XCTestExpectation(description: "Get transaction xdr")
        
        sdk.transactions.getTransactions(limit:1) { (response) -> (Void) in
            switch response {
            case .success(let transactionsResponse):
                if let response = transactionsResponse.records.first {
                    if let resultBody = response.transactionResult.resultBody {
                        switch resultBody {
                        case .success(let operations):
                            self.validateOperation(operationXDR: operations.first!)
                            expectation.fulfill()
                        case .failed:
                            XCTAssert(false)
                        }
                    }
                }
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func validateOperation(operationXDR: OperationResultXDR) {
        switch operationXDR {
        case .createAccount(let code, _):
            XCTAssertEqual(code, CreateAccountResultCode.success.rawValue)
        case .payment(let code, _):
            XCTAssertEqual(code, PaymentResultCode.success.rawValue)
        case .pathPayment(let code, _):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
        case .manageSellOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .manageBuyOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .createPassiveSellOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .setOptions(let code, _):
            XCTAssertEqual(code, SetOptionsResultCode.success.rawValue)
        case .changeTrust(let code, _):
            XCTAssertEqual(code, ChangeTrustResultCode.success.rawValue)
        case .allowTrust(let code, _):
            XCTAssertEqual(code, AllowTrustResultCode.success.rawValue)
        case .accountMerge(let code, _):
            XCTAssertEqual(code, AccountMergeResultCode.success.rawValue)
        case .inflation(let code, _):
            XCTAssertEqual(code, InflationResultCode.success.rawValue)
        case .manageData(let code, _):
            XCTAssertEqual(code, ManageDataResultCode.success.rawValue)
        case .bumpSequence(let code, _):
            XCTAssertEqual(code, BumpSequenceResultCode.success.rawValue)
        case .pathPaymentStrictSend(let code, _):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
        case .empty(let code):
            XCTAssertEqual(code, OperationResultCode.badAuth.rawValue)
        }
        
    }
    
    func testCreateAccountOperation() {
        let expectation = XCTestExpectation(description: "Create account operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            let startAmount = Decimal(1000)
            
            let operation = CreateAccountOperation(sourceAccount: source, destination: destination, startBalance: startAmount)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! CreateAccountOperation
            
            switch operationXdr.body {
            case .createAccount(let createAccountXdr):
                XCTAssertEqual(10000000000, createAccountXdr.startingBalance)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            XCTAssertEqual(startAmount, parsedOperation.startBalance)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAAAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAACVAvkAA==", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPaymentOperation() {
        let expectation = XCTestExpectation(description: "Payment operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            let amount = Decimal(1000)
            let asset = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            
            let operation = PaymentOperation(sourceAccount: source, destination: destination, asset: asset!, amount: amount)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! PaymentOperation
            
            switch operationXdr.body {
            case .payment(let paymentXdr):
                XCTAssertEqual(10000000000, paymentXdr.amount)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_NATIVE)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAEAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAAAAAAAAlQL5AA=", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPathPaymentOperation() {
        let expectation = XCTestExpectation(description: "Path Payment operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            // GCGZLB3X2B3UFOFSHHQ6ZGEPEX7XYPEH6SBFMIV74EUDOFZJA3VNL6X4
            let issuer = try KeyPair(secretSeed: "SBOBVZUN6WKVMI6KIL2GHBBEETEV6XKQGILITNH6LO6ZA22DBMSDCPAG")
            // GAVAQKT2M7B4V3NN7RNNXPU5CWNDKC27MYHKLF5UNYXH4FNLFVDXKRSV
            let pathIssuer1 = try KeyPair(secretSeed: "SALDLG5XU5AEJWUOHAJPSC4HJ2IK3Z6BXXP4GWRHFT7P7ILSCFFQ7TC5")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let pathIssuer2 = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")
            
            let sendAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            let sendMax = Decimal(0.0001)
            let destAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)
            let destAmount = Decimal(0.0001)
            let path:[Asset] = [Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: pathIssuer1)!,
                        Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "TESTTEST", issuer: pathIssuer2)!]
            
            let operation = try PathPaymentOperation(sourceAccount: source, sendAsset: sendAsset!, sendMax: sendMax, destination: destination, destAsset: destAsset!, destAmount: destAmount, path: path)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! PathPaymentOperation
            
            switch operationXdr.body {
            case .pathPayment(let pathPaymentXdr):
                XCTAssertEqual(1000, pathPaymentXdr.sendMax)
                XCTAssertEqual(1000, pathPaymentXdr.destinationAmount)
            default:
                break
            }
            XCTAssertTrue(parsedOperation.sendAsset.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            XCTAssertEqual(sendMax, parsedOperation.sendMax)
            XCTAssertTrue(parsedOperation.destAsset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(destAmount, parsedOperation.destAmount)
            XCTAssertEqual(path.count, parsedOperation.path.count)
            
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAIAAAAAAAAAAAAAA+gAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAABVVNEAAAAAACNlYd30HdCuLI54eyYjyX/fDyH9IJWIr/hKDcXKQbq1QAAAAAAAAPoAAAAAgAAAAFVU0QAAAAAACoIKnpnw8rtrfxa276dFZo1C19mDqWXtG4ufhWrLUd1AAAAAlRFU1RURVNUAAAAAAAAAABE/ttVl8BLV0csW/xgXtbXOVf1lMyDluMiafl0IDVFIg==", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPathPaymentEmptyPathOperation() {
        let expectation = XCTestExpectation(description: "Path Payment empty path operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            // GCGZLB3X2B3UFOFSHHQ6ZGEPEX7XYPEH6SBFMIV74EUDOFZJA3VNL6X4
            let issuer = try KeyPair(secretSeed: "SBOBVZUN6WKVMI6KIL2GHBBEETEV6XKQGILITNH6LO6ZA22DBMSDCPAG")
            
            let sendAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            let sendMax = Decimal(0.0001)
            let destAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)
            let destAmount = Decimal(0.0001)
            
            let operation = try PathPaymentOperation(sourceAccount: source, sendAsset: sendAsset!, sendMax: sendMax, destination: destination, destAsset: destAsset!, destAmount: destAmount, path:[])
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! PathPaymentOperation
            
            switch operationXdr.body {
            case .pathPayment(let pathPaymentXdr):
                XCTAssertEqual(1000, pathPaymentXdr.sendMax)
                XCTAssertEqual(1000, pathPaymentXdr.destinationAmount)
            default:
                break
            }
            XCTAssertTrue(parsedOperation.sendAsset.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            XCTAssertEqual(sendMax, parsedOperation.sendMax)
            XCTAssertTrue(parsedOperation.destAsset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(destAmount, parsedOperation.destAmount)
            XCTAssertEqual(0, parsedOperation.path.count)
            
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAIAAAAAAAAAAAAAA+gAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAABVVNEAAAAAACNlYd30HdCuLI54eyYjyX/fDyH9IJWIr/hKDcXKQbq1QAAAAAAAAPoAAAAAA==", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testChangeTrustOperation() {
        let expectation = XCTestExpectation(description: "Change trust operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            let issuingAccountKeyPair = try KeyPair(accountId: "GCXIZK3YMSKES64ATQWMQN5CX73EWHRHUSEZXIMHP5GYHXL5LNGCOGXU")
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let limit = Decimal(100000.55)
            
            var changeTrustOperation = ChangeTrustOperation(sourceAccount: source, asset: IOM!, limit: limit)
            var operationXdr = try changeTrustOperation.toXDR()
            var parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ChangeTrustOperation
       

            switch operationXdr.body {
            case .changeTrust(let changeTrustXdr):
                var decimalXDRLimit = Decimal(changeTrustXdr.limit)
                decimalXDRLimit = decimalXDRLimit / 10000000
                XCTAssertEqual(limit, decimalXDRLimit)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(limit, parsedOperation.limit)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertTrue(parsedOperation.asset.code == "IOM")
            XCTAssertTrue(parsedOperation.asset.issuer?.accountId == issuingAccountKeyPair.accountId)
            
            let IOMIOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "IOMIOM", issuer: issuingAccountKeyPair)
            
            changeTrustOperation = ChangeTrustOperation(sourceAccount: source, asset: IOMIOM!, limit: limit)
            operationXdr = try changeTrustOperation.toXDR()
            parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ChangeTrustOperation
            
            
            switch operationXdr.body {
            case .changeTrust(let changeTrustXdr):
                var decimalXDRLimit = Decimal(changeTrustXdr.limit)
                decimalXDRLimit = decimalXDRLimit / 10000000
                XCTAssertEqual(limit, decimalXDRLimit)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(limit, parsedOperation.limit)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
            XCTAssertTrue(parsedOperation.asset.code == "IOMIOM")
            XCTAssertTrue(parsedOperation.asset.issuer?.accountId == issuingAccountKeyPair.accountId)
        
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAllowTrustOperation() {
        let expectation = XCTestExpectation(description: "Allow trust operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let trustor = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            let assetCode = "USDA"
            let authorize = true
            //let authorize = TrustLineFlags.AUTHORIZED_FLAG
            
            let operation = try AllowTrustOperation(sourceAccount: source, trustor: trustor, assetCode: assetCode, authorize: authorize)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AllowTrustOperation
            
            switch operationXdr.body {
            case .allowTrust(let allowTrustXdr):
                XCTAssertEqual(allowTrustXdr.authorize, TrustLineFlags.AUTHORIZED_FLAG)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(trustor.accountId, parsedOperation.trustor.accountId)
            XCTAssertEqual(assetCode, parsedOperation.assetCode)
            XCTAssertEqual(TrustLineFlags.AUTHORIZED_FLAG, parsedOperation.authorize)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAcAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAABVVNEQQAAAAE=", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAllowTrustOperationAssetCodeBuffer() {
        let expectation = XCTestExpectation(description: "Allow trust operation code buffer")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let trustor = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            let assetCode = "USDABC"
            let authorize = true
            
            let operation = try AllowTrustOperation(sourceAccount: source, trustor: trustor, assetCode: assetCode, authorize: authorize)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AllowTrustOperation
            
            let parsedAssetCode = parsedOperation.assetCode
            XCTAssertEqual(assetCode, parsedAssetCode)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSetOptionsOperation() {
        let expectation = XCTestExpectation(description: "Set options operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let inflationDestination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let signerKey = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")
            let signer = Signer.ed25519PublicKey(keyPair: signerKey)
            
            let clearFlags = 1 as UInt32
            let setFlags = 1 as UInt32
            let masterKeyWeight = 1 as UInt32
            let lowThreshold = 2 as UInt32
            let mediumThreshold = 3 as UInt32
            let highThreshold = 4 as UInt32
            let homeDomain = "stellar.org"
            let signerWeight = 1 as UInt32
            
            let operation = try SetOptionsOperation(sourceAccount: source, inflationDestination: inflationDestination, clearFlags: clearFlags, setFlags: setFlags, masterKeyWeight: masterKeyWeight, lowThreshold: lowThreshold, mediumThreshold: mediumThreshold, highThreshold: highThreshold, homeDomain: homeDomain, signer: signer, signerWeight: signerWeight)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(inflationDestination.accountId, parsedOperation.inflationDestination?.accountId)
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(clearFlags, parsedOperation.clearFlags)
            XCTAssertEqual(setFlags, parsedOperation.setFlags)
            XCTAssertEqual(masterKeyWeight, parsedOperation.masterKeyWeight)
            XCTAssertEqual(lowThreshold, parsedOperation.lowThreshold)
            XCTAssertEqual(mediumThreshold, parsedOperation.mediumThreshold)
            XCTAssertEqual(highThreshold, parsedOperation.highThreshold)
            XCTAssertEqual(homeDomain, parsedOperation.homeDomain)
            XCTAssertEqual(signer, parsedOperation.signer)
            XCTAssertEqual(signerWeight, parsedOperation.signerWeight)
            
            //let base64 = try operation.toXDRBase64()
            //XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAUAAAABAAAAAO3gUmG83C+VCqO6FztuMtXJF/l7grZA7MjRzqdZ9W8QAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAIAAAABAAAAAwAAAAEAAAAEAAAAAQAAAAtzdGVsbGFyLm9yZwAAAAABAAAAAET+21WXwEtXRyxb/GBe1tc5V/WUzIOW4yJp+XQgNUUiAAAAAQ==", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSetOptionsOperationSingleField() {
        let expectation = XCTestExpectation(description: "Set options operation single field")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            let homeDomain = "stellar.org"
            
            let operation = try SetOptionsOperation(sourceAccount: source, homeDomain: homeDomain)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertNil(parsedOperation.inflationDestination?.accountId)
            XCTAssertNil(parsedOperation.clearFlags)
            XCTAssertNil(parsedOperation.setFlags)
            XCTAssertNil(parsedOperation.masterKeyWeight)
            XCTAssertNil(parsedOperation.lowThreshold)
            XCTAssertNil(parsedOperation.mediumThreshold)
            XCTAssertNil(parsedOperation.highThreshold)
            XCTAssertEqual(homeDomain, parsedOperation.homeDomain)
            XCTAssertNil(parsedOperation.signer)
            XCTAssertNil(parsedOperation.signerWeight)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAtzdGVsbGFyLm9yZwAAAAAA", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSetOptionsOperationSignerSha256() {
        let expectation = XCTestExpectation(description: "Set options operation signer sha256")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let signer = Signer.sha256Hash(hash: "stellar.org".sha256Hash)
            
            let operation = try SetOptionsOperation(sourceAccount: source, signer: signer, signerWeight:10)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertNil(parsedOperation.inflationDestination?.accountId)
            XCTAssertNil(parsedOperation.clearFlags)
            XCTAssertNil(parsedOperation.setFlags)
            XCTAssertNil(parsedOperation.masterKeyWeight)
            XCTAssertNil(parsedOperation.lowThreshold)
            XCTAssertNil(parsedOperation.mediumThreshold)
            XCTAssertNil(parsedOperation.highThreshold)
            XCTAssertNil(parsedOperation.homeDomain)
            XCTAssertEqual(signer, parsedOperation.signer)
            XCTAssertEqual(10, parsedOperation.signerWeight)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAACbpRqMkaQAfCYSk/n3xIl4fCoHfKqxF34ht2iuvSYEJQAAAAK", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSetOptionsOperationPreAuthTxSigner() {
        let expectation = XCTestExpectation(description: "Set options operation pre auth tx")
        
        do {
            // GBPMKIRA2OQW2XZZQUCQILI5TMVZ6JNRKM423BSAISDM7ZFWQ6KWEBC4
            let source = try KeyPair(secretSeed: "SCH27VUZZ6UAKB67BDNF6FA42YMBMQCBKXWGMFD5TZ6S5ZZCZFLRXKHS")
            let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
            
            let sequenceNumber = Int64(2908908335136768)
            let account = Account(keyPair: source, sequenceNumber: sequenceNumber)
            let createAccountOperation = CreateAccountOperation(destination: destination, startBalance: 2000)
            let transaction = try Transaction(sourceAccount: account,
                                              operations: [createAccountOperation],
                                              memo: Memo.none,
                                              timeBounds:nil)
            
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let operationSource = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            let signer = try Signer.preAuthTx(transaction: transaction, network: .testnet)
            
            let operation = try SetOptionsOperation(sourceAccount: operationSource, signer: signer, signerWeight:10)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(operationSource.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertNil(parsedOperation.inflationDestination?.accountId)
            XCTAssertNil(parsedOperation.clearFlags)
            XCTAssertNil(parsedOperation.setFlags)
            XCTAssertNil(parsedOperation.masterKeyWeight)
            XCTAssertNil(parsedOperation.lowThreshold)
            XCTAssertNil(parsedOperation.mediumThreshold)
            XCTAssertNil(parsedOperation.highThreshold)
            XCTAssertNil(parsedOperation.homeDomain)
            XCTAssertEqual(signer, parsedOperation.signer)
            XCTAssertEqual(10, parsedOperation.signerWeight)
            
//            let base64 = try operation.toXDRBase64()
//            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAB1vRBIRC3w7ZH5rQa17hIBKUwZTvBP4kNmSP7jVyw1fQAAAAK", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testManageOfferOperation() {
        let expectation = XCTestExpectation(description: "Manage offer operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let issuer = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")
            
            let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            let buying = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)
            let amount = Decimal(0.00001)
            let priceStr = "0.85334384" // n=5333399 d=6250000
            let price = Price.fromString(price: priceStr)
            let offerId = Int64(1)
            
            let operation = ManageSellOfferOperation(sourceAccount: source, selling: selling!, buying: buying!, amount: amount, price: price, offerId: offerId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ManageSellOfferOperation
            
            switch operationXdr.body {
            case .manageSellOffer(let manageOfferXdr):
                XCTAssertEqual(100, manageOfferXdr.amount)
            default:
                break
            }
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertTrue(parsedOperation.selling.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertTrue(parsedOperation.buying.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
//            XCTAssertEqual(parsedOperation.buying, buying)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertEqual(price, parsedOperation.price)
            XCTAssertEqual(offerId, parsedOperation.offerId)
            XCTAssertEqual(price.n, 5333399)
            XCTAssertEqual(price.d, 6250000)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAMAAAAAAAAAAVVTRAAAAAAARP7bVZfAS1dHLFv8YF7W1zlX9ZTMg5bjImn5dCA1RSIAAAAAAAAAZABRYZcAX14QAAAAAAAAAAE=", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testCreatePassiveOfferOperation() {
        let expectation = XCTestExpectation(description: "Create passive offer operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let issuer = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")
            
            let selling = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            let buying = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)
            let amount = Decimal(0.00001)
            let priceStr = "2.93850088" // n=36731261 d=12500000
            let price = Price.fromString(price: priceStr)
            
            let operation = CreatePassiveSellOfferOperation(sourceAccount: source, selling: selling!, buying: buying!, amount: amount, price: price)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! CreatePassiveSellOfferOperation
            
            switch operationXdr.body {
            case .createPassiveSellOffer(let offerXdr):
                XCTAssertEqual(100, offerXdr.amount)
            default:
                break
            }
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertTrue(parsedOperation.selling.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertTrue(parsedOperation.buying.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            //            XCTAssertEqual(parsedOperation.buying, buying)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertEqual(price, parsedOperation.price)
            XCTAssertEqual(price.n, 36731261)
            XCTAssertEqual(price.d, 12500000)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAQAAAAAAAAAAVVTRAAAAAAARP7bVZfAS1dHLFv8YF7W1zlX9ZTMg5bjImn5dCA1RSIAAAAAAAAAZAIweX0Avrwg", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAccountMergeOperation() {
        let expectation = XCTestExpectation(description: "Account merge operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            let operation = AccountMergeOperation(sourceAccount: source, destination: destination)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AccountMergeOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAgAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxA=", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testManageDataOperation() {
        let expectation = XCTestExpectation(description: "Manage data operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let name = "test"
            let data = Data(bytes: [0,1,2,3,4])
            
            let operation = ManageDataOperation(sourceAccount: source, name: name, data: data)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ManageDataOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(name, parsedOperation.name)
            XCTAssertEqual(data, parsedOperation.data)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAoAAAAEdGVzdAAAAAEAAAAFAAECAwQ=", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testManageDataOperationEmptyValue() {
        let expectation = XCTestExpectation(description: "Manage data operation empty value")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let name = "test"
            
            let operation = ManageDataOperation(sourceAccount: source, name: name)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ManageDataOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(name, parsedOperation.name)
            XCTAssertNil(parsedOperation.data)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAoAAAAEdGVzdAAAAAA=", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testBumpSequenceOperation() {
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let bumpTo:Int64 = 9999999
            
            let operation = BumpSequenceOperation(bumpTo: bumpTo, sourceAccount: source)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! BumpSequenceOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(bumpTo, parsedOperation.bumpTo)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAsAAAAAAJiWfw==", base64)
        } catch {
            XCTAssert(false)
        }
    }
}

