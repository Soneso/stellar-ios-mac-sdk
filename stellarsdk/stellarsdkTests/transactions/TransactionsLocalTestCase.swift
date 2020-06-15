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
