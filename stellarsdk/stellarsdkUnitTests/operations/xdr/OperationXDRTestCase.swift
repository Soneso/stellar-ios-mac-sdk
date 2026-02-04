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

    func testCreateAccountOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            let startAmount = Decimal(1000)
            
            let operation = try! CreateAccountOperation(sourceAccountId: source.accountId, destinationAccountId: destination.accountId, startBalance: startAmount)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! CreateAccountOperation
            
            switch operationXdr.body {
            case .createAccount(let createAccountXdr):
                XCTAssertEqual(10000000000, createAccountXdr.startingBalance)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            XCTAssertEqual(startAmount, parsedOperation.startBalance)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAAAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAACVAvkAA==", base64)
            
        } catch {
            XCTFail()
        }
    }
    
    func testPaymentOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            let amount = Decimal(1000)
            let asset = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            
            let operation = try! PaymentOperation(sourceAccountId: source.accountId, destinationAccountId: destination.accountId, asset: asset!, amount: amount)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! PaymentOperation
            
            switch operationXdr.body {
            case .payment(let paymentXdr):
                XCTAssertEqual(10000000000, paymentXdr.amount)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destinationAccountId)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_NATIVE)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAEAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAAAAAAAAlQL5AA=", base64)
        } catch {
            XCTFail()
        }
    }
    
    func testPathPaymentOperation() {
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
            
            let operation = try PathPaymentOperation(sourceAccountId: source.accountId, sendAsset: sendAsset!, sendMax: sendMax, destinationAccountId: destination.accountId, destAsset: destAsset!, destAmount: destAmount, path: path)
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
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destinationAccountId)
            XCTAssertEqual(sendMax, parsedOperation.sendMax)
            XCTAssertTrue(parsedOperation.destAsset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(destAmount, parsedOperation.destAmount)
            XCTAssertEqual(path.count, parsedOperation.path.count)
            
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAIAAAAAAAAAAAAAA+gAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAABVVNEAAAAAACNlYd30HdCuLI54eyYjyX/fDyH9IJWIr/hKDcXKQbq1QAAAAAAAAPoAAAAAgAAAAFVU0QAAAAAACoIKnpnw8rtrfxa276dFZo1C19mDqWXtG4ufhWrLUd1AAAAAlRFU1RURVNUAAAAAAAAAABE/ttVl8BLV0csW/xgXtbXOVf1lMyDluMiafl0IDVFIg==", base64)
        } catch {
            XCTFail()
        }
    }
    
    func testPathPaymentEmptyPathOperation() {
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
            
            let operation = try PathPaymentOperation(sourceAccountId: source.accountId, sendAsset: sendAsset!, sendMax: sendMax, destinationAccountId: destination.accountId, destAsset: destAsset!, destAmount: destAmount, path:[])
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
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destinationAccountId)
            XCTAssertEqual(sendMax, parsedOperation.sendMax)
            XCTAssertTrue(parsedOperation.destAsset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(destAmount, parsedOperation.destAmount)
            XCTAssertEqual(0, parsedOperation.path.count)
            
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAIAAAAAAAAAAAAAA+gAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAABVVNEAAAAAACNlYd30HdCuLI54eyYjyX/fDyH9IJWIr/hKDcXKQbq1QAAAAAAAAPoAAAAAA==", base64)
            
        } catch {
            XCTFail()
        }
    }
    
    func testChangeTrustOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            let issuingAccountKeyPair = try KeyPair(accountId: "GCXIZK3YMSKES64ATQWMQN5CX73EWHRHUSEZXIMHP5GYHXL5LNGCOGXU")
            let IOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let limit = Decimal(100000.55)
            
            var changeTrustOperation = ChangeTrustOperation(sourceAccountId: source.accountId, asset: IOM!, limit: limit)
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
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(limit, parsedOperation.limit)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertTrue(parsedOperation.asset.code == "IOM")
            XCTAssertTrue(parsedOperation.asset.issuer?.accountId == issuingAccountKeyPair.accountId)
            
            let IOMIOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "IOMIOM", issuer: issuingAccountKeyPair)
            
            changeTrustOperation = ChangeTrustOperation(sourceAccountId: source.accountId, asset: IOMIOM!, limit: limit)
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
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(limit, parsedOperation.limit)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
            XCTAssertTrue(parsedOperation.asset.code == "IOMIOM")
            XCTAssertTrue(parsedOperation.asset.issuer?.accountId == issuingAccountKeyPair.accountId)

        } catch {
            XCTFail()
        }
    }
    
    func testAllowTrustOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let trustor = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            let assetCode = "USDA"
            let authorize = true
            //let authorize = TrustLineFlags.AUTHORIZED_FLAG
            
            let operation = try AllowTrustOperation(sourceAccountId: source.accountId, trustor: trustor, assetCode: assetCode, authorize: authorize)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AllowTrustOperation
            
            switch operationXdr.body {
            case .allowTrust(let allowTrustXdr):
                XCTAssertEqual(allowTrustXdr.authorize, TrustLineFlags.AUTHORIZED_FLAG)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(trustor.accountId, parsedOperation.trustor.accountId)
            XCTAssertEqual(assetCode, parsedOperation.assetCode)
            XCTAssertEqual(TrustLineFlags.AUTHORIZED_FLAG, parsedOperation.authorize)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAcAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAABVVNEQQAAAAE=", base64)
        } catch {
            XCTFail()
        }
    }
    
    func testAllowTrustOperationAssetCodeBuffer() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let trustor = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            let assetCode = "USDABC"
            let authorize = true
            
            let operation = try AllowTrustOperation(sourceAccountId: source.accountId, trustor: trustor, assetCode: assetCode, authorize: authorize)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AllowTrustOperation
            
            let parsedAssetCode = parsedOperation.assetCode
            XCTAssertEqual(assetCode, parsedAssetCode)
        } catch {
            XCTFail()
        }
    }
    
    func testSetOptionsOperation() {
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
            
            let operation = try SetOptionsOperation(sourceAccountId: source.accountId, inflationDestination: inflationDestination, clearFlags: clearFlags, setFlags: setFlags, masterKeyWeight: masterKeyWeight, lowThreshold: lowThreshold, mediumThreshold: mediumThreshold, highThreshold: highThreshold, homeDomain: homeDomain, signer: signer, signerWeight: signerWeight)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(inflationDestination.accountId, parsedOperation.inflationDestination?.accountId)
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(clearFlags, parsedOperation.clearFlags)
            XCTAssertEqual(setFlags, parsedOperation.setFlags)
            XCTAssertEqual(masterKeyWeight, parsedOperation.masterKeyWeight)
            XCTAssertEqual(lowThreshold, parsedOperation.lowThreshold)
            XCTAssertEqual(mediumThreshold, parsedOperation.mediumThreshold)
            XCTAssertEqual(highThreshold, parsedOperation.highThreshold)
            XCTAssertEqual(homeDomain, parsedOperation.homeDomain)
            XCTAssertEqual(signer, parsedOperation.signer)
            XCTAssertEqual(signerWeight, parsedOperation.signerWeight)
        } catch {
            XCTFail()
        }
    }
    
    func testSetOptionsOperationSingleField() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            let homeDomain = "stellar.org"
            
            let operation = try SetOptionsOperation(sourceAccountId: source.accountId, homeDomain: homeDomain)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
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
        } catch {
            XCTFail()
        }
    }
    
    func testSetOptionsOperationSignerSha256() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let signer = Signer.sha256Hash(hash: "stellar.org".sha256Hash)
            
            let operation = try SetOptionsOperation(sourceAccountId: source.accountId, signer: signer, signerWeight:10)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
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
        } catch {
            XCTFail()
        }
    }
    
    func testSetOptionsOperationPreAuthTxSigner() {
        do {
            // GBPMKIRA2OQW2XZZQUCQILI5TMVZ6JNRKM423BSAISDM7ZFWQ6KWEBC4
            let source = try KeyPair(secretSeed: "SCH27VUZZ6UAKB67BDNF6FA42YMBMQCBKXWGMFD5TZ6S5ZZCZFLRXKHS")
            let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
            
            let sequenceNumber = Int64(2908908335136768)
            let account = Account(keyPair: source, sequenceNumber: sequenceNumber)
            let createAccountOperation = try! CreateAccountOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, startBalance: 2000)
            let transaction = try Transaction(sourceAccount: account,
                                              operations: [createAccountOperation],
                                              memo: Memo.none)
            
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let operationSource = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            let signer = try Signer.preAuthTx(transaction: transaction, network: .testnet)
            
            let operation = try SetOptionsOperation(sourceAccountId: operationSource.accountId, signer: signer, signerWeight:10)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetOptionsOperation
            
            XCTAssertEqual(operationSource.accountId, parsedOperation.sourceAccountId)
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
        } catch {
            XCTFail()
        }
    }
    
    func testManageOfferOperation() {
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
            
            let operation = ManageSellOfferOperation(sourceAccountId: source.accountId, selling: selling!, buying: buying!, amount: amount, price: price, offerId: offerId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ManageSellOfferOperation
            
            switch operationXdr.body {
            case .manageSellOffer(let manageOfferXdr):
                XCTAssertEqual(100, manageOfferXdr.amount)
            default:
                break
            }
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertTrue(parsedOperation.selling.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertTrue(parsedOperation.buying.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertEqual(price, parsedOperation.price)
            XCTAssertEqual(offerId, parsedOperation.offerId)
            XCTAssertEqual(price.n, 5333399)
            XCTAssertEqual(price.d, 6250000)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAMAAAAAAAAAAVVTRAAAAAAARP7bVZfAS1dHLFv8YF7W1zlX9ZTMg5bjImn5dCA1RSIAAAAAAAAAZABRYZcAX14QAAAAAAAAAAE=", base64)

        } catch {
            XCTFail()
        }
    }
    
    func testCreatePassiveOfferOperation() {
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
            
            let operation = CreatePassiveSellOfferOperation(sourceAccountId: source.accountId, selling: selling!, buying: buying!, amount: amount, price: price)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! CreatePassiveSellOfferOperation
            
            switch operationXdr.body {
            case .createPassiveSellOffer(let offerXdr):
                XCTAssertEqual(100, offerXdr.amount)
            default:
                break
            }
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertTrue(parsedOperation.selling.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertTrue(parsedOperation.buying.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            //            XCTAssertEqual(parsedOperation.buying, buying)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertEqual(price, parsedOperation.price)
            XCTAssertEqual(price.n, 36731261)
            XCTAssertEqual(price.d, 12500000)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAQAAAAAAAAAAVVTRAAAAAAARP7bVZfAS1dHLFv8YF7W1zlX9ZTMg5bjImn5dCA1RSIAAAAAAAAAZAIweX0Avrwg", base64)

        } catch {
            XCTFail()
        }
    }
    
    func testAccountMergeOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            
            let operation = try! AccountMergeOperation(destinationAccountId: destination.accountId, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! AccountMergeOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destinationAccountId)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAgAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxA=", base64)
            
        } catch {
            XCTFail()
        }
    }
    
    func testManageDataOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let name = "test"
            let data = Data([0,1,2,3,4])
            
            let operation = ManageDataOperation(sourceAccountId: source.accountId, name: name, data: data)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ManageDataOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(name, parsedOperation.name)
            XCTAssertEqual(data, parsedOperation.data)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAoAAAAEdGVzdAAAAAEAAAAFAAECAwQAAAA=", base64)
        } catch {
            XCTFail()
        }
    }
    
    func testManageDataOperationEmptyValue() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let name = "test"
            
            let operation = ManageDataOperation(sourceAccountId: source.accountId, name: name)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ManageDataOperation
            
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(name, parsedOperation.name)
            XCTAssertNil(parsedOperation.data)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAoAAAAEdGVzdAAAAAA=", base64)
        } catch {
            XCTFail()
        }
    }
    
    func testBumpSequenceOperation() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let bumpTo:Int64 = 9999999

            let operation = BumpSequenceOperation(bumpTo: bumpTo, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! BumpSequenceOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(bumpTo, parsedOperation.bumpTo)

            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAsAAAAAAJiWfw==", base64)
        } catch {
            XCTFail()
        }
    }

    func testCreateClaimableBalanceOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let issuer = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")

            let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
            let amount = Decimal(100.50)
            let claimant = Claimant(destination: destination.accountId)

            let operation = CreateClaimableBalanceOperation(asset: asset, amount: amount, claimants: [claimant], sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! CreateClaimableBalanceOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(asset.code, parsedOperation.asset.code)
            XCTAssertEqual(1, parsedOperation.claimants.count)
            XCTAssertEqual(destination.accountId, parsedOperation.claimants[0].destination)
        } catch {
            XCTFail()
        }
    }

    func testClaimClaimableBalanceOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let balanceId = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"

            let operation = ClaimClaimableBalanceOperation(balanceId: balanceId, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ClaimClaimableBalanceOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(balanceId, parsedOperation.balanceId)
        } catch {
            XCTFail()
        }
    }

    func testBeginSponsoringFutureReservesOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let sponsor = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let sponsored = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")

            let operation = BeginSponsoringFutureReservesOperation(sponsoredAccountId: sponsored.accountId, sponsoringAccountId: sponsor.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! BeginSponsoringFutureReservesOperation

            XCTAssertEqual(sponsor.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(sponsored.accountId, parsedOperation.sponsoredId)
        } catch {
            XCTFail()
        }
    }

    func testEndSponsoringFutureReservesOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let sponsored = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")

            let operation = EndSponsoringFutureReservesOperation(sponsoredAccountId: sponsored.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! EndSponsoringFutureReservesOperation

            XCTAssertEqual(sponsored.accountId, parsedOperation.sourceAccountId)
        } catch {
            XCTFail()
        }
    }

    func testRevokeSponsorshipAccountOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let accountId = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII").accountId

            let ledgerKey = try RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(accountId: accountId)
            let operation = RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RevokeSponsorshipOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertNotNil(parsedOperation.ledgerKey)
            XCTAssertNil(parsedOperation.signerAccountId)
            XCTAssertNil(parsedOperation.signerKey)
        } catch {
            XCTFail()
        }
    }

    func testRevokeSponsorshipTrustlineOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let accountId = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII").accountId
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let issuer = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")
            let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!

            let ledgerKey = try RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(accountId: accountId, asset: asset)
            let operation = RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RevokeSponsorshipOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertNotNil(parsedOperation.ledgerKey)
            XCTAssertNil(parsedOperation.signerAccountId)
            XCTAssertNil(parsedOperation.signerKey)
        } catch {
            XCTFail()
        }
    }

    func testRevokeSponsorshipOfferOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let sellerId = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII").accountId
            let offerId: UInt64 = 12345

            let ledgerKey = try RevokeSponsorshipOperation.revokeOfferSponsorshipLedgerKey(sellerAccountId: sellerId, offerId: offerId)
            let operation = RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RevokeSponsorshipOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertNotNil(parsedOperation.ledgerKey)
            XCTAssertNil(parsedOperation.signerAccountId)
            XCTAssertNil(parsedOperation.signerKey)
        } catch {
            XCTFail()
        }
    }

    func testRevokeSponsorshipDataOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let accountId = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII").accountId
            let dataName = "testdata"

            let ledgerKey = try RevokeSponsorshipOperation.revokeDataSponsorshipLedgerKey(accountId: accountId, dataName: dataName)
            let operation = RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RevokeSponsorshipOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertNotNil(parsedOperation.ledgerKey)
            XCTAssertNil(parsedOperation.signerAccountId)
            XCTAssertNil(parsedOperation.signerKey)
        } catch {
            XCTFail()
        }
    }

    func testRevokeSponsorshipClaimableBalanceOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let balanceId = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"

            let ledgerKey = try RevokeSponsorshipOperation.revokeClaimableBalanceSponsorshipLedgerKey(balanceId: balanceId)
            let operation = RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RevokeSponsorshipOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertNotNil(parsedOperation.ledgerKey)
            XCTAssertNil(parsedOperation.signerAccountId)
            XCTAssertNil(parsedOperation.signerKey)
        } catch {
            XCTFail()
        }
    }

    func testRevokeSponsorshipSignerOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let accountId = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII").accountId
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let signerKeyPair = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")
            let signerKey = try Signer.ed25519PublicKey(accountId: signerKeyPair.accountId)

            let operation = RevokeSponsorshipOperation(signerAccountId: accountId, signerKey: signerKey, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RevokeSponsorshipOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertNil(parsedOperation.ledgerKey)
            XCTAssertEqual(accountId, parsedOperation.signerAccountId)
            XCTAssertNotNil(parsedOperation.signerKey)
        } catch {
            XCTFail()
        }
    }

    func testClawbackOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let fromAccount = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let issuer = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")

            let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
            let amount = Decimal(50.25)

            let operation = ClawbackOperation(sourceAccountId: source.accountId, asset: asset, fromAccountId: fromAccount.accountId, amount: amount)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ClawbackOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertEqual(fromAccount.accountId, parsedOperation.fromAccountId)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(asset.code, parsedOperation.asset.code)
        } catch {
            XCTFail()
        }
    }

    func testClawbackClaimableBalanceOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let balanceId = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"

            let operation = ClawbackClaimableBalanceOperation(claimableBalanceID: balanceId, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ClawbackClaimableBalanceOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(balanceId, parsedOperation.claimableBalanceID)
        } catch {
            XCTFail()
        }
    }

    func testSetTrustLineFlagsOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let trustor = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            // GBCP5W2VS7AEWV2HFRN7YYC623LTSV7VSTGIHFXDEJU7S5BAGVCSETRR
            let issuer = try KeyPair(secretSeed: "SA64U7C5C7BS5IHWEPA7YWFN3Z6FE5L6KAMYUIT4AQ7KVTVLD23C6HEZ")

            let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer)!
            let setFlags: UInt32 = 1
            let clearFlags: UInt32 = 2

            let operation = SetTrustlineFlagsOperation(sourceAccountId: source.accountId, asset: asset, trustorAccountId: trustor.accountId, setFlags: setFlags, clearFlags: clearFlags)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! SetTrustlineFlagsOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(trustor.accountId, parsedOperation.trustorAccountId)
            XCTAssertTrue(parsedOperation.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(asset.code, parsedOperation.asset.code)
            XCTAssertEqual(setFlags, parsedOperation.setFlags)
            XCTAssertEqual(clearFlags, parsedOperation.clearFlags)
        } catch {
            XCTFail()
        }
    }

    func testLiquidityPoolDepositOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let liquidityPoolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
            let maxAmountA = Decimal(100.00)
            let maxAmountB = Decimal(200.00)
            let minPrice = Price(numerator: 1, denominator: 2)
            let maxPrice = Price(numerator: 2, denominator: 1)

            let operation = LiquidityPoolDepositOperation(sourceAccountId: source.accountId, liquidityPoolId: liquidityPoolId, maxAmountA: maxAmountA, maxAmountB: maxAmountB, minPrice: minPrice, maxPrice: maxPrice)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! LiquidityPoolDepositOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(liquidityPoolId, parsedOperation.liquidityPoolId)
            XCTAssertEqual(maxAmountA, parsedOperation.maxAmountA)
            XCTAssertEqual(maxAmountB, parsedOperation.maxAmountB)
            XCTAssertEqual(minPrice.n, parsedOperation.minPrice.n)
            XCTAssertEqual(minPrice.d, parsedOperation.minPrice.d)
            XCTAssertEqual(maxPrice.n, parsedOperation.maxPrice.n)
            XCTAssertEqual(maxPrice.d, parsedOperation.maxPrice.d)
        } catch {
            XCTFail()
        }
    }

    func testLiquidityPoolWithdrawOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let liquidityPoolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
            let amount = Decimal(50.00)
            let minAmountA = Decimal(10.00)
            let minAmountB = Decimal(20.00)

            let operation = LiquidityPoolWithdrawOperation(sourceAccountId: source.accountId, liquidityPoolId: liquidityPoolId, amount: amount, minAmountA: minAmountA, minAmountB: minAmountB)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! LiquidityPoolWithdrawOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(liquidityPoolId, parsedOperation.liquidityPoolId)
            XCTAssertEqual(amount, parsedOperation.amount)
            XCTAssertEqual(minAmountA, parsedOperation.minAmountA)
            XCTAssertEqual(minAmountB, parsedOperation.minAmountB)
        } catch {
            XCTFail()
        }
    }

    func testInvokeHostFunctionOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let contractId = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
            let functionName = "test_function"
            let arg1 = SCValXDR.u32(100)
            let arg2 = SCValXDR.string("test")

            let operation = try InvokeHostFunctionOperation.forInvokingContract(
                contractId: contractId,
                functionName: functionName,
                functionArguments: [arg1, arg2],
                sourceAccountId: source.accountId
            )
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! InvokeHostFunctionOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertTrue(parsedOperation.auth.isEmpty)

            switch parsedOperation.hostFunction {
            case .invokeContract(let invokeArgs):
                XCTAssertEqual(functionName, invokeArgs.functionName)
                XCTAssertEqual(2, invokeArgs.args.count)
                if case .u32(let value) = invokeArgs.args[0] {
                    XCTAssertEqual(100, value)
                } else {
                    XCTFail("Expected u32 argument")
                }
                if case .string(let value) = invokeArgs.args[1] {
                    XCTAssertEqual("test", value)
                } else {
                    XCTFail("Expected string argument")
                }
            default:
                XCTFail("Expected invokeContract host function")
            }
        } catch {
            XCTFail()
        }
    }

    func testExtendFootprintTTLOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            let extendTo: UInt32 = 100000

            let operation = ExtendFootprintTTLOperation(ledgersToExpire: extendTo, sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! ExtendFootprintTTLOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
            XCTAssertEqual(extendTo, parsedOperation.extendTo)
        } catch {
            XCTFail()
        }
    }

    func testRestoreFootprintOperationXDR() {
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")

            let operation = RestoreFootprintOperation(sourceAccountId: source.accountId)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! RestoreFootprintOperation

            XCTAssertEqual(source.accountId, parsedOperation.sourceAccountId)
        } catch {
            XCTFail()
        }
    }
}

