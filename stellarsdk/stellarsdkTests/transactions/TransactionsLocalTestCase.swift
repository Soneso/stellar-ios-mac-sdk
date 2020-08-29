//
//  TransactionsLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 21.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionsLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var transactionsResponsesMock: TransactionsResponsesMock? = nil
    var mockRegistered = false
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        transactionsResponsesMock = TransactionsResponsesMock()
        let oneTransactionResponse = successResponse(limit: 1)
        let twoTransactionsResponse = successResponse(limit: 2)
        
        transactionsResponsesMock?.addTransactionsResponse(key: "1", response: oneTransactionResponse)
        transactionsResponsesMock?.addTransactionsResponse(key: "2", response: twoTransactionsResponse)
        
    }
    
    override func tearDown() {
        transactionsResponsesMock = nil
        super.tearDown()
    }
    
    func testTransactionToTxRep1() {
        let sourceAccountKeyPair = try! KeyPair(secretSeed: "SC6VJARW2SO3WQ4EQKPYWZ3CVIWKQCDAVTTQH7QUDRIPVBKVNYYRLCC4")
        let accountBId = "GAQC6DUD2OVIYV3DTBPOSLSSOJGE4YJZHEGQXOU4GV6T7RABWZXELCUT"
        let accountASeqNr = Int64(379748123410432)
        let accountA = Account(keyPair:sourceAccountKeyPair, sequenceNumber: accountASeqNr)
        
        do {
            
            let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                destinationAccountId: accountBId,
                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                amount: 1.5)
            
            let iomAsset:Asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: sourceAccountKeyPair)!
            let ecoAsset:Asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "ECO", issuer: sourceAccountKeyPair)!
            let astroAsset:Asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ASTRO", issuer: sourceAccountKeyPair)!
            let moonAsset:Asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "MOON", issuer: sourceAccountKeyPair)!
            let nativeAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
            let path:[Asset] = [ecoAsset, astroAsset]
            
            let pathPaymentStrictReceiveOperation = try PathPaymentStrictReceiveOperation(sourceAccountId: sourceAccountKeyPair.accountId, sendAsset: iomAsset, sendMax: 2, destinationAccountId: accountBId, destAsset:moonAsset, destAmount: 8, path:path)
            
            let pathPaymentStrictSendOperation = try PathPaymentStrictSendOperation(sourceAccountId: sourceAccountKeyPair.accountId, sendAsset: iomAsset, sendMax: 400, destinationAccountId: accountBId, destAsset:moonAsset, destAmount: 1200, path:path)
            
            let manageSellOfferOperation = ManageSellOfferOperation(sourceAccountId: sourceAccountKeyPair.accountId, selling:ecoAsset, buying:nativeAsset, amount:8282.0, price:Price(numerator:7, denominator:10), offerId:9298298398333)
            
            let manageBuyOfferOperation = ManageBuyOfferOperation(sourceAccountId: sourceAccountKeyPair.accountId, selling:moonAsset, buying:ecoAsset, amount:12, price:Price(numerator:1, denominator:5), offerId:9298298398334)
            
            let createPassiveSellOfferOperation = CreatePassiveOfferOperation(sourceAccountId: sourceAccountKeyPair.accountId, selling:astroAsset, buying:moonAsset, amount:2828, price:Price(numerator:1, denominator:2))
            
            let changeTrustOperation = ChangeTrustOperation(sourceAccountId: sourceAccountKeyPair.accountId, asset: astroAsset, limit: 10000)
            
            let allowTrustOperation = try AllowTrustOperation(sourceAccountId: sourceAccountKeyPair.accountId, trustor: KeyPair(accountId: accountBId), assetCode: "MOON", authorize: 1)
            
            let signer = SignerKeyXDR.ed25519(WrappedData32(try accountBId.decodeEd25519PublicKey()))
            let setOptionsOperation = try SetOptionsOperation(sourceAccountId: sourceAccountKeyPair.accountId, inflationDestination: KeyPair(accountId: accountBId), clearFlags: 2, setFlags: 4, masterKeyWeight: 122, lowThreshold: 10, mediumThreshold: 50, highThreshold: 122, homeDomain: "https://www.soneso.com/blubber", signer: signer, signerWeight: 50)
            
            let timeBounds = try TimeBounds(minTime: 1597351082, maxTime: 1597388888);
            
            let accountMergeOperation = try AccountMergeOperation(destinationAccountId: accountBId, sourceAccountId: sourceAccountKeyPair.accountId)
            
            let manageDataOperation = ManageDataOperation(sourceAccountId: sourceAccountKeyPair.accountId, name: "Sommer", data: "Die Möbel sind heiß!".data(using: .utf8))
            
            let bumpSequenceOperation = BumpSequenceOperation(bumpTo: accountA.sequenceNumber + 10, sourceAccountId: nil)
            
            let createAccountOperation = CreateAccountOperation(sourceAccountId: sourceAccountKeyPair.accountId, destination: try KeyPair(accountId: accountBId), startBalance: 10)
            
            let operations = [paymentOperation, pathPaymentStrictReceiveOperation, pathPaymentStrictSendOperation, manageSellOfferOperation, manageBuyOfferOperation, createPassiveSellOfferOperation, changeTrustOperation, allowTrustOperation, setOptionsOperation, accountMergeOperation, manageDataOperation, bumpSequenceOperation, createAccountOperation]
        
        
            let transaction = try Transaction(sourceAccount: accountA,
                                              operations: operations,
                                              memo: Memo.text("Enjoy this transaction!"),
                                              timeBounds:timeBounds)
            
            try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            print(try! TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope()));
            
            let keyPairC = try! KeyPair.generateRandomKeyPair()
            let feeBump = try FeeBumpTransaction(sourceAccount: MuxedAccount(accountId: keyPairC.accountId), fee: 101, innerTransaction: transaction)
            try feeBump.sign(keyPair: keyPairC, network: Network.testnet)
            print(try! TxRep.toTxRep(transactionEnvelope: feeBump.encodedEnvelope()));
            XCTAssert(true)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testTransactionToTxRepExample() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.timeBounds._present: true
        tx.timeBounds.minTime: 1535756672 (Fri Aug 31 16:04:32 PDT 2018)
        tx.timeBounds.maxTime: 1567292672 (Sat Aug 31 16:04:32 PDT 2019)
        tx.memo.type: MEMO_TEXT
        tx.memo.text: "Enjoy this transaction"
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O
        tx.operations[0].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
        tx.operations[0].body.paymentOp.amount: 400004000 (40.0004e7)
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: 4aa07ed0 (GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN)
        signatures[0].signature: defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d31b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c
        """

        let envelope = try TxRep.fromTxRep(txRep:txRep);

        print(envelope)
        XCTAssert(true)
    }
    
    func testTransactionToTxRep2() {
        let xdr = "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"
        
        let txrep = try! TxRep.toTxRep(transactionEnvelope: xdr)
        print(txrep)
        let xdr2 = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssert (xdr == xdr2)
    }
    
    func testFeeBumpTransactionToTxRep() {
        let xdr = "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"
        
        let txrep = try! TxRep.toTxRep(transactionEnvelope: xdr)
        print(txrep)
        let xdr2 = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssert (xdr == xdr2)
    }
    
    func testTransactionEnvelopeXDRStringInit() {
    
        let xdrStringV1 = "AAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAA+gAD7FZAAAABAAAAAAAAAAAAAAAAQAAAAEAAAAAZX6UM0RYk3YWGYlmCus5uOGFhgXzR76FzjzPopiFDE0AAAABAAAAAByH6g1uUljaFtnxQRIrC6x47kLp1vHEcml+WhdzQjWKAAAAAAAAAAAA5OHAAAAAAAAAAAGYhQxNAAAAQMRhbj+98fzgU++ft/Sd5Nd/2qLPofcgLyRKyJafSKM4jSNNkLGQKL5oFSJnaBnaOxZ7Jc4q6s5GV9y1bcnIdQc="
        do {
            // method 1
            var transaction = try Transaction(envelopeXdr: xdrStringV1)
            var tFee = transaction.fee
            XCTAssert(tFee == 1000)
            let encodedEnvelope = try transaction.encodedEnvelope()
            XCTAssertTrue(xdrStringV1 == encodedEnvelope)
            
            // method 2
            var envelope = try TransactionEnvelopeXDR(xdr:xdrStringV1)
            var fee = envelope.txFee
            XCTAssert(fee == 1000)
            let envelopeString = envelope.xdrEncoded
            XCTAssertTrue(xdrStringV1 == envelopeString)
            
            let xdrStringV0 = "AAAAAGV+lDNEWJN2FhmJZgrrObjhhYYF80e+hc48z6KYhQxNAAAD6AAPsVkAAAAEAAAAAAAAAAAAAAABAAAAAQAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAAEAAAAAHIfqDW5SWNoW2fFBEisLrHjuQunW8cRyaX5aF3NCNYoAAAAAAAAAAADk4cAAAAAAAAAAAZiFDE0AAABAxGFuP73x/OBT75+39J3k13/aos+h9yAvJErIlp9IoziNI02QsZAovmgVImdoGdo7FnslzirqzkZX3LVtych1Bw==" //V0 Transaction
            
            // method 1
            transaction = try Transaction(envelopeXdr: xdrStringV0)
            tFee = transaction.fee
            XCTAssert(tFee == 1000)
            XCTAssert("GBSX5FBTIRMJG5QWDGEWMCXLHG4ODBMGAXZUPPUFZY6M7IUYQUGE3EYH" == transaction.sourceAccount.keyPair.accountId)
            
            // method 2
            envelope = try TransactionEnvelopeXDR(xdr:xdrStringV1)
            fee = envelope.txFee
            XCTAssert(fee == 1000)
            XCTAssert("GBSX5FBTIRMJG5QWDGEWMCXLHG4ODBMGAXZUPPUFZY6M7IUYQUGE3EYH" == envelope.txSourceAccountId)
            
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testTransactionXDRStringInit() {
        
        let xdrString = "AAAAAGV+lDNEWJN2FhmJZgrrObjhhYYF80e+hc48z6KYhQxNAAAD6AAPsVkAAAAEAAAAAAAAAAAAAAABAAAAAQAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAAEAAAAAHIfqDW5SWNoW2fFBEisLrHjuQunW8cRyaX5aF3NCNYoAAAAAAAAAAADk4cAAAAAA"
        do {
            let transaction = try TransactionXDR(xdr:xdrString)
            let fee = transaction.fee
            XCTAssert(fee == 1000)
            let transactionXDRString = transaction.xdrEncoded
            XCTAssertTrue(xdrString == transactionXDRString)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testTransactionStringInit() {
        let xdrString = "AAAAAJ/Ax+axve53/7sXfQY0fI6jzBeHEcPl0Vsg1C2tqyRbAAAAZAAAAAAAAAAAAAAAAQAAAABb2L/OAAAAAFvYwPoAAAAAAAAAAQAAAAEAAAAAo7FW8r8Nj+SMwPPeAoL4aUkLob7QU68+9Y8CAia5k78AAAAKAAAAN0NJcDhiSHdnU2hUR042ZDE3bjg1ZlFGRVBKdmNtNFhnSWhVVFBuUUF4cUtORVd4V3JYIGF1dGgAAAAAAQAAAEDh/7kQjZbcXypISjto5NtGLuaDGrfL/F08apZQYp38JNMNQ9p/e1Fy0z23WOg/Ic+e91+hgbdTude6+1+i0V41AAAAAA=="
        do {
            let envelope = try Transaction(xdr:xdrString)
            let envelopeString = envelope.xdrEncoded
            XCTAssertTrue(xdrString == envelopeString)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testGetTransactions() {
        let expectation = XCTestExpectation(description: "Get transactions and parse their details successfully")
        
        sdk.transactions.getTransactions(limit: 1) { (response) -> (Void) in
            switch response {
            case .success(let transactionsResponse):
                checkResult(transactionsResponse:transactionsResponse, limit:1)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        func checkResult(transactionsResponse:PageResponse<TransactionResponse>, limit:Int) {
            
            XCTAssertNotNil(transactionsResponse.links)
            XCTAssertNotNil(transactionsResponse.links.selflink)
            XCTAssertEqual(transactionsResponse.links.selflink.href, "https://horizon-testnet.stellar.org/transactions?order=desc&limit=4&cursor=")
            XCTAssertNil(transactionsResponse.links.selflink.templated)
            
            XCTAssertNotNil(transactionsResponse.links.next)
            XCTAssertEqual(transactionsResponse.links.next?.href, "https://horizon-testnet.stellar.org/transactions?order=desc&limit=4&cursor=32234481175760896")
            XCTAssertNil(transactionsResponse.links.next?.templated)
            
            XCTAssertNotNil(transactionsResponse.links.prev)
            XCTAssertEqual(transactionsResponse.links.prev?.href, "https://horizon-testnet.stellar.org/transactions?order=asc&limit=4&cursor=32234511240531968")
            XCTAssertNil(transactionsResponse.links.prev?.templated)
            
            if limit == 1 {
                XCTAssertEqual(transactionsResponse.records.count, 1)
            } else if limit == 2 {
                XCTAssertEqual(transactionsResponse.records.count, 2)
            }
            
            let firstTransaction = transactionsResponse.records.first
            XCTAssertNotNil(firstTransaction)
            XCTAssertNotNil(firstTransaction?.links)
            XCTAssertNotNil(firstTransaction?.links.selfLink)
            XCTAssertEqual(firstTransaction?.links.selfLink.href, "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36")
            XCTAssertNotNil(firstTransaction?.links.account)
            XCTAssertNotNil(firstTransaction?.links.account.href, "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")
            XCTAssertNil(firstTransaction?.links.account.templated)
            XCTAssertNotNil(firstTransaction?.links.ledger)
            XCTAssertNotNil(firstTransaction?.links.ledger.href, "https://horizon-testnet.stellar.org/ledgers/7505182")
            XCTAssertNil(firstTransaction?.links.ledger.templated)
            XCTAssertNotNil(firstTransaction?.links.operations)
            XCTAssertNotNil(firstTransaction?.links.operations.href, "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36/operations{?cursor,limit,order}")
            XCTAssertNotNil(firstTransaction?.links.operations.templated)
            XCTAssertTrue((firstTransaction?.links.operations.templated)!)
            XCTAssertNotNil(firstTransaction?.links.effects)
            XCTAssertNotNil(firstTransaction?.links.effects.href, "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36/effects{?cursor,limit,order}")
            XCTAssertNotNil(firstTransaction?.links.effects.templated)
            XCTAssertTrue((firstTransaction?.links.effects.templated)!)
            XCTAssertNotNil(firstTransaction?.links.precedes)
            XCTAssertNotNil(firstTransaction?.links.precedes.href, "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=32234511240531968")
            XCTAssertNil(firstTransaction?.links.precedes.templated)
            XCTAssertNotNil(firstTransaction?.links.succeeds)
            XCTAssertNotNil(firstTransaction?.links.succeeds.href, "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=32234511240531968")
            XCTAssertNil(firstTransaction?.links.precedes.templated)
            XCTAssertEqual(firstTransaction?.id, "1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36")
            XCTAssertEqual(firstTransaction?.pagingToken, "32234511240531968")
            XCTAssertEqual(firstTransaction?.transactionHash, "1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36")
            XCTAssertEqual(firstTransaction?.ledger, 7505182)
            let createdAt = DateFormatter.iso8601.date(from:"2018-02-21T15:16:05Z")
            XCTAssertEqual(firstTransaction?.createdAt,createdAt)
            XCTAssertEqual(firstTransaction?.sourceAccount,"GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")
            XCTAssertEqual(firstTransaction?.sourceAccountSequence,"31398186618716187")
            XCTAssertEqual(firstTransaction?.feeAccount,"GALPCCZN4YXA3YMJHKL6CVIECKPLJJCTVMSNYWBTKJW4K5HQLYLDMZTB")
            XCTAssertEqual(firstTransaction?.maxFee, "102")
            XCTAssertEqual(firstTransaction?.feeCharged, "101")
            XCTAssertEqual(firstTransaction?.operationCount,1)
            // TODO xdrs
            XCTAssertEqual(firstTransaction?.memoType, "none")
            XCTAssertEqual(firstTransaction?.memo, Memo.none)
            XCTAssertNotNil(firstTransaction?.signatures.first)
            XCTAssertEqual(firstTransaction?.signatures.first, "ioDroKPUAZn2Pp4OTksPKmitQTZpsFSAN259vcI0E3YtCbOWUQkpOJV68myqgL62CPzK3YIsg+Kok4lQ6ys5Ag==")
            
            if (limit == 2) {
                let secondTransaction = transactionsResponse.records.last
                XCTAssertNotNil(secondTransaction)
                
                XCTAssertNotNil(secondTransaction?.links)
                XCTAssertNotNil(secondTransaction?.links.selfLink)
                XCTAssertEqual(secondTransaction?.links.selfLink.href, "https://horizon-testnet.stellar.org/transactions/d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2")
                XCTAssertNotNil(secondTransaction?.links.account)
                XCTAssertNotNil(secondTransaction?.links.account.href, "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")
                XCTAssertNil(secondTransaction?.links.account.templated)
                XCTAssertNotNil(secondTransaction?.links.ledger)
                XCTAssertNotNil(secondTransaction?.links.ledger.href, "https://horizon-testnet.stellar.org/ledgers/7505182")
                XCTAssertNil(secondTransaction?.links.ledger.templated)
                XCTAssertNotNil(secondTransaction?.links.operations)
                XCTAssertNotNil(secondTransaction?.links.operations.href, "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36/operations{?cursor,limit,order}")
                XCTAssertNotNil(secondTransaction?.links.operations.templated)
                XCTAssertTrue((secondTransaction?.links.operations.templated)!)
                XCTAssertNotNil(secondTransaction?.links.effects)
                XCTAssertNotNil(secondTransaction?.links.effects.href, "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36/effects{?cursor,limit,order}")
                XCTAssertNotNil(secondTransaction?.links.effects.templated)
                XCTAssertTrue((secondTransaction?.links.effects.templated)!)
                XCTAssertNotNil(secondTransaction?.links.precedes)
                XCTAssertNotNil(secondTransaction?.links.precedes.href, "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=32234511240531968")
                XCTAssertNil(secondTransaction?.links.precedes.templated)
                XCTAssertNotNil(secondTransaction?.links.succeeds)
                XCTAssertNotNil(secondTransaction?.links.succeeds.href, "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=32234511240531968")
                XCTAssertNil(secondTransaction?.links.precedes.templated)
                XCTAssertEqual(secondTransaction?.id, "d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2")
                XCTAssertEqual(secondTransaction?.pagingToken, "32234506945564672")
                XCTAssertEqual(secondTransaction?.transactionHash, "d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2")
                XCTAssertEqual(secondTransaction?.ledger, 7505181)
                let createdAt = DateFormatter.iso8601.date(from:"2018-02-21T15:16:00Z")
                XCTAssertEqual(secondTransaction?.createdAt,createdAt)
                XCTAssertEqual(secondTransaction?.sourceAccount,"GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")
                XCTAssertEqual(secondTransaction?.sourceAccountSequence,"31398186618716186")
                XCTAssertEqual(secondTransaction?.feeAccount,"GALPCCZN4YXA3YMJHKL6CVIECKPLJJCTVMSNYWBTKJW4K5HQLYLDMZTB")
                XCTAssertEqual(secondTransaction?.maxFee, "100")
                XCTAssertEqual(secondTransaction?.feeCharged, "100")
                XCTAssertEqual(secondTransaction?.operationCount,1)
                // TODO xdrs
                XCTAssertEqual(secondTransaction?.memoType, "hash")
                XCTAssertNotNil(secondTransaction?.memo)
                XCTAssertEqual(secondTransaction?.memo, Memo.hash(Data(base64Encoded:"UQQWROg9ashoyElBi2OS3b6d9T8AAAAAAAAAAAAAAAA=")!))
                XCTAssertNotNil(secondTransaction?.signatures.first)
                XCTAssertEqual(secondTransaction?.signatures.first, "9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==")
                
                expectation.fulfill()
            } else {
                sdk.transactions.getTransactions(limit: 2) { (response) -> (Void) in
                    switch response {
                    case .success(let transactionsResponse):
                        checkResult(transactionsResponse:transactionsResponse, limit:2)
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    public func successResponse(limit:Int) -> String {
        
        var transactionsResponseString = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions?order=desc&limit=4&cursor="
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/transactions?order=desc&limit=4&cursor=32234481175760896"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/transactions?order=asc&limit=4&cursor=32234511240531968"
                }
            },
            "_embedded": {
                "records": [
                {
                    "_links": {
                        "self": {
                            "href": "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36"
                        },
                        "account": {
                            "href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"
                        },
                        "ledger": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/7505182"
                        },
                        "operations": {
                            "href": "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36/operations{?cursor,limit,order}",
                            "templated": true
                        },
                        "effects": {
                            "href": "https://horizon-testnet.stellar.org/transactions/1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36/effects{?cursor,limit,order}",
                            "templated": true
                        },
                        "precedes": {
                            "href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=32234511240531968"
                        },
                        "succeeds": {
                            "href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=32234511240531968"
                        }
                    },
                    "id": "1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36",
                    "paging_token": "32234511240531968",
                    "hash": "1d1e64643c3351b578e3b87e4430c3aa4764a08b40840c234d4ace2d98933b36",
                    "ledger": 7505182,
                    "created_at": "2018-02-21T15:16:05Z",
                    "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                    "source_account_sequence": "31398186618716187",
                    "max_fee": "102",
                    "fee_charged":"101",
                    "fee_account": "GALPCCZN4YXA3YMJHKL6CVIECKPLJJCTVMSNYWBTKJW4K5HQLYLDMZTB",
                    "operation_count": 1,
                    "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAbAAAAAAAAAAAAAAABAAAAAAAAAAMAAAABRVVSAAAAAABWsKIm44ZManGkwOIyDdbzRjPLfb6ZrVXWOGIi9S2tRwAAAAJDVTEyMzQ1AAAAAAAAAAAAwjUbmH7LrvIY/NDZcKS9j6Dl/dg6KCJgC1GiKwWkdaMAAAAAL68IAAAAAAEAAAPoAAAAAAAAAAAAAAAAAAAAAdNn6woAAABAioDroKPUAZn2Pp4OTksPKmitQTZpsFSAN259vcI0E3YtCbOWUQkpOJV68myqgL62CPzK3YIsg+Kok4lQ6ys5Ag==",
                    "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAADAAAAAAAAAAEAAAAAURqP8nUKuuavLDttwWMCdPjCAiTp+vu5leob71ZdvIAAAAAAAAGcvwAAAAJDVTEyMzQ1AAAAAAAAAAAAwjUbmH7LrvIY/NDZcKS9j6Dl/dg6KCJgC1GiKwWkdaMAAAAAAAw1AAAAAAFFVVIAAAAAAFawoibjhkxqcaTA4jIN1vNGM8t9vpmtVdY4YiL1La1HAAAAAC+vCAAAAAACAAAAAA==",
                    "result_meta_xdr": "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",
                    "fee_meta_xdr": "AAAAAgAAAAMAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUeAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdtysAG+MfAAAABsAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
                    "memo_type": "none",
                    "signatures": [
                        "ioDroKPUAZn2Pp4OTksPKmitQTZpsFSAN259vcI0E3YtCbOWUQkpOJV68myqgL62CPzK3YIsg+Kok4lQ6ys5Ag=="
                    ]
                }
        """
        if limit > 1 {
            let record = """
                ,
                {
                    "_links": {
                        "self": {
                            "href": "https://horizon-testnet.stellar.org/transactions/d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2"
                        },
                        "account": {
                            "href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"
                        },
                        "ledger": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/7505181"
                        },
                        "operations": {
                            "href": "https://horizon-testnet.stellar.org/transactions/d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2/operations{?cursor,limit,order}",
                            "templated": true
                        },
                        "effects": {
                            "href": "https://horizon-testnet.stellar.org/transactions/d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2/effects{?cursor,limit,order}",
                            "templated": true
                        },
                        "precedes": {
                            "href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=32234506945564672"
                        },
                        "succeeds": {
                            "href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=32234506945564672"
                        }
                    },
                    "id": "d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2",
                    "paging_token": "32234506945564672",
                    "hash": "d62dc796bef7e2b838a97a6f91afb21e6dbab54974473176ea293fae2aa40fb2",
                    "ledger": 7505181,
                    "created_at": "2018-02-21T15:16:00Z",
                    "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                    "source_account_sequence": "31398186618716186",
                    "max_fee": 100,
                    "fee_charged":100,
                    "fee_account": "GALPCCZN4YXA3YMJHKL6CVIECKPLJJCTVMSNYWBTKJW4K5HQLYLDMZTB",
                    "operation_count": 1,
                    "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                    "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
                    "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
                    "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
                    "memo_type": "hash",
                    "memo": "UQQWROg9ashoyElBi2OS3b6d9T8AAAAAAAAAAAAAAAA=",
                    "signatures": [
                        "9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="
                    ]
                }
            """
            transactionsResponseString.append(record)
        }
        let end = """
                    ]
                }
            }
            """
        transactionsResponseString.append(end)
        
        return transactionsResponseString
    }
}
