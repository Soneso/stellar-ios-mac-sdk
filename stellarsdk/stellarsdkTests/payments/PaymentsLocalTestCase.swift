//
//  PaymentsLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/22/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PaymentsLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var paymentsResponsesMock: PaymentsResponsesMock? = nil
    var mockRegistered = false
    let limit = 4
    let ledgerId = "69859"
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        paymentsResponsesMock = PaymentsResponsesMock()
        
        let firstResponse = successResponse(limit:limit)
        paymentsResponsesMock?.addPaymentsResponse(ledgerId: ledgerId, limit: String(limit), response: firstResponse)
    }
    
    override func tearDown() {
        paymentsResponsesMock = nil
        super.tearDown()
    }
    
    func testGetPayments() {
        let expectation = XCTestExpectation(description: "Get payments and parse their details successfully")
        
        sdk.payments.getPayments(forLedger: ledgerId, limit:limit) { response in
            switch response {
            case .success(let paymentsResponse):
                checkResult(paymentsResponse:paymentsResponse, ledgerId:"69859")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GP Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        func checkResult(paymentsResponse:PageResponse<OperationResponse>, ledgerId:String) {
            
            XCTAssertNotNil(paymentsResponse.links)
            XCTAssertNotNil(paymentsResponse.links.selflink)
            XCTAssertEqual(paymentsResponse.links.selflink.href, "https://horizon-testnet.stellar.org/operations?order=asc&limit=2&cursor=")
            XCTAssertNil(paymentsResponse.links.selflink.templated)
            
            XCTAssertNotNil(paymentsResponse.links.next)
            XCTAssertEqual(paymentsResponse.links.next?.href, "https://horizon-testnet.stellar.org/operations?order=asc&limit=2&cursor=77309415424")
            XCTAssertNil(paymentsResponse.links.next?.templated)
            
            XCTAssertNotNil(paymentsResponse.links.prev)
            XCTAssertEqual(paymentsResponse.links.prev?.href, "https://horizon-testnet.stellar.org/operations?order=desc&limit=2&cursor=77309415424")
            XCTAssertNil(paymentsResponse.links.prev?.templated)
            
            
            XCTAssertEqual(paymentsResponse.records.count, limit)
            
            for payment in paymentsResponse.records {
                
                XCTAssertNotNil(payment)
                XCTAssertNotNil(payment.links)
                XCTAssertNotNil(payment.links.selfLink)
                XCTAssertEqual(payment.links.selfLink.href, "https://horizon-testnet.stellar.org/operations/77309415424")
                
                XCTAssertNotNil(payment.links.transaction)
                XCTAssertEqual(payment.links.transaction.href, "https://horizon-testnet.stellar.org/transactions/77309415424")
                
                XCTAssertNotNil(payment.links.effects)
                XCTAssertEqual(payment.links.effects.href, "https://horizon-testnet.stellar.org/operations/77309415424/effects/{?cursor,limit,order}")
                XCTAssertNotNil(payment.links.effects.templated)
                XCTAssertTrue(payment.links.effects.templated ?? false)
                
                XCTAssertNotNil(payment.links.precedes)
                XCTAssertEqual(payment.links.precedes.href, "https://horizon-testnet.stellar.org/operations?cursor=77309415424&order=asc")
                
                XCTAssertNotNil(payment.links.succeeds)
                XCTAssertEqual(payment.links.succeeds.href, "https://horizon-testnet.stellar.org/operations?cursor=77309415424&order=desc")
                
                XCTAssertEqual(payment.operationTypeString, "payment")
                XCTAssertEqual(payment.operationType, OperationType.payment)
                XCTAssertEqual(payment.id, "77309415424")
                XCTAssertEqual(payment.pagingToken, "77309415424")
                XCTAssertEqual(payment.sourceAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                let createdAt = DateFormatter.iso8601.date(from:"2018-02-21T09:56:26Z")
                XCTAssertEqual(payment.createdAt, createdAt)
                XCTAssertEqual(payment.transactionHash, "5b422945c99ec8bd8b29b0086aeb89027a774be54e8663d3fa538775cde8b51d")
                
                if let payment = payment as? PaymentOperationResponse {
                    XCTAssertEqual(payment.amount, "100.0")
                    XCTAssertEqual(payment.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
                    XCTAssertEqual(payment.assetCode, "EUR")
                    XCTAssertEqual(payment.assetIssuer, "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA")
                    XCTAssertEqual(payment.from, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                    XCTAssertEqual(payment.to, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    public func successResponse(limit:Int) -> String {
        var responseString = """
            {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations?order=asc&limit=2&cursor="
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/operations?order=asc&limit=2&cursor=77309415424"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/operations?order=desc&limit=2&cursor=77309415424"
                }
            },
            "_embedded": {
                "records": [
        """
        
        let record = """
            {
            "_links": {
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/77309415424/effects/{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=77309415424&order=asc"
                },
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations/77309415424"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=77309415424&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/77309415424"
                }
            },
            "id": "77309415424",
            "paging_token": "77309415424",
            "transaction_successful":true,
            "type_i": 1,
            "type": "payment",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "created_at": "2018-02-21T09:56:26Z",
            "transaction_hash": "5b422945c99ec8bd8b29b0086aeb89027a774be54e8663d3fa538775cde8b51d",
            "asset_type": "credit_alphanum4",
            "asset_code": "EUR",
            "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
            "amount": "100.0",
            "from": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
        }
        """
        
        responseString.append(record)
        for _ in 1...limit-1 {
            responseString.append(", " + record)
        }
        let end = """
                    ]
                }
            }
            """
        responseString.append(end)
        
        return responseString
    }
}
