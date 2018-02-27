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
    
    func testSubmitTransactionResultXdr() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        let xdrEnvelope = "AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAByE3sAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAR+V72AAAABAAuiJ2+1FGpG7D+sS9qqZlk2/dsu8mdECuR1jiX9PaawJaJMETUP6u06cZgzrqopzmypJMOS/ob7BRvCQ3JkwDg=="
        
        sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
            switch response {
            case .success(let response):
                if let resultBody = response.transactionResult.resultBody {
                    switch resultBody {
                    case .success(let operations):
                        self.validateOperation(operationXDR: operations.first!)
                        expectation.fulfill()
                    case .failed:
                        XCTAssert(false)
                    }
                }
            case .failure(_):
                XCTAssert(false)
            }
        })
        
        wait(for: [expectation], timeout: 25.0)
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
        case .manageOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .createPassiveOffer(let code, _):
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
            
            let asset = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            let limit = Decimal(922337203685.4775807)
            
            let operation = ChangeTrustOperation(sourceAccount: source, asset: asset!, limit: limit)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ChangeTrustOperation
            
            switch operationXdr.body {
            case .changeTrust(let changeTrustXdr):
                XCTAssertEqual(9223372036854775807, changeTrustXdr.limit)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(limit, parsedOperation.limit)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_NATIVE)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAYAAAAAf/////////8=", base64)
            
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
            
            let operation = try AllowTrustOperation(sourceAccount: source, trustor: trustor, assetCode: assetCode, authorize: authorize)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AllowTrustOperation
            
            switch operationXdr.body {
            case .allowTrust(let allowTrustXdr):
                XCTAssertTrue(allowTrustXdr.authorize)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(trustor.accountId, parsedOperation.trustor.accountId)
            XCTAssertEqual(assetCode, parsedOperation.assetCode)
            XCTAssertEqual(authorize, parsedOperation.authorize)
            
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
            
            XCTAssertEqual(assetCode, parsedOperation.assetCode)
            
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
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAUAAAABAAAAAO3gUmG83C+VCqO6FztuMtXJF/l7grZA7MjRzqdZ9W8QAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAIAAAABAAAAAwAAAAEAAAAEAAAAAQAAAAtzdGVsbGFyLm9yZwAAAAABAAAAAET+21WXwEtXRyxb/GBe1tc5V/WUzIOW4yJp+XQgNUUiAAAAAQ==", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

