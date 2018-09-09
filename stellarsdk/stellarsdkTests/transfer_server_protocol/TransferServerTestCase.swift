//
//  TransferServerTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransferServerTestCase: XCTestCase {

    let transferServer = "127.0.0.1"
    
    let successAccount = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI"
    let creationNotSupportedAccount = "GBTMF7Y4S7S3ZMYLIU5MLVEECJETO7FYIZ5OH3GBDD7W3Z4A6556RTMC"
    let informationNeededNonInteractiveAccount = "GCIKZJNCDA6W335ODLBIINABY53DJXJTW4PPW6CXK623ZTA6LSYZI7SL"
    let informationNeededInteractiveAccount = "GDO4YFV4DI5CZ4FOZKD7PLBTAVGFGFIX4ZE4QNJCDLLAA4YOCXHWVVHI"
    let informationStatusAccount = "GAT3G3YYJJA6PIJJCP33N6RBJODYHMHVA556SBAOZYV5HTGLTFBI2VI3"
    let errorAccount = "GBYLNNAUUJQ7YJSGIATU432IJP2QYTTPKIY5AFWT7LFZAIT76QYVLTAG"
    
    var transferServerService: TransferServerService!
    var depositServerMock: DepositResponseMock!
    var withdrawServerMock: WithdrawResponseMock!
    var anchorInfoServerMock: AnchorInfoResponseMock!
    var anchorTransactionsServerMock: AnchorTransactionsResponseMock!
    var putCustomerInfoServerMock: PutCustomerInfoResponseMock!
    var deleteCustomerInfoResponseMock: DeleteCustomerInfoResponseMock!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        
        depositServerMock = DepositResponseMock(address: transferServer)
        withdrawServerMock = WithdrawResponseMock(address: transferServer)
        anchorInfoServerMock = AnchorInfoResponseMock(address: transferServer)
        anchorTransactionsServerMock = AnchorTransactionsResponseMock(address: transferServer)
        putCustomerInfoServerMock = PutCustomerInfoResponseMock(address: transferServer)
        deleteCustomerInfoResponseMock = DeleteCustomerInfoResponseMock(address: transferServer)
        transferServerService = TransferServerService(transferServiceAddress: "http://\(transferServer)")
    }
    
    override func tearDown() {
        
        
        super.tearDown()
    }
    
    func testDepositSuccess() {
        let request = DepositRequest(assetCode: "BTC", account: successAccount)
        let expectation = XCTestExpectation(description: "Test deposit succcess")
        
        transferServerService.deposit(request: request) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(response.how, "1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB")
                XCTAssertEqual(response.feeFixed, 0.0002)
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDepositAccountCreationNotSupported() {
        let request = DepositRequest(assetCode: "BTC", account: creationNotSupportedAccount)
        let expectation = XCTestExpectation(description: "Test deposit no account creation")
        
        transferServerService.deposit(request: request) { (response) -> (Void) in
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
    
    func testDepositInformationNeededNonInteractive() {
        let request = DepositRequest(assetCode: "BTC", account: informationNeededNonInteractiveAccount)
        let expectation = XCTestExpectation(description: "Test deposit information needed non-interactive")
        
        transferServerService.deposit(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .informationNeeded(let response):
                    switch response {
                    case .nonInteractive(let info):
                        XCTAssert(info.fields.count == 4)
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDepositInformationNeededInteractive() {
        let request = DepositRequest(assetCode: "BTC", account: informationNeededInteractiveAccount)
        let expectation = XCTestExpectation(description: "Test deposit information needed interactive")
        
        transferServerService.deposit(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .informationNeeded(let response):
                    switch response {
                    case .interactive(let info):
                        XCTAssert(info.url == "https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDepositInformationStatus() {
        let request = DepositRequest(assetCode: "BTC", account: informationStatusAccount)
        let expectation = XCTestExpectation(description: "Test deposit information status")
        
        transferServerService.deposit(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .informationNeeded(let response):
                    switch response {
                    case .status(let info):
                        XCTAssert(info.status == "denied")
                        XCTAssert(info.moreInfoUrl == "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDepositError() {
        let request = DepositRequest(assetCode: "BTC", account: errorAccount)
        let expectation = XCTestExpectation(description: "Test deposit error")
        
        transferServerService.deposit(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .anchorError(let message):
                    XCTAssert(message == "This anchor doesn't support the given currency code: ETH")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testWithdrawSuccess() {
        let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: successAccount)
        let expectation = XCTestExpectation(description: "Test withdraw succcess")
        
        transferServerService.withdraw(request: request) { (response) -> (Void) in
            switch response {
            case .success(let info):
                XCTAssert(info.accountId == "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ")
                XCTAssert(info.memoType == "id")
                XCTAssert(info.memo == "123")
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testWithdrawAccountCreationNotSupported() {
        let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: creationNotSupportedAccount)
        let expectation = XCTestExpectation(description: "Test withdraw no account creation")
        
        transferServerService.withdraw(request: request) { (response) -> (Void) in
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
    
    func testWithdrawInformationNeededNonInteractive() {
        let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: informationNeededNonInteractiveAccount)
        let expectation = XCTestExpectation(description: "Test withdraw information needed non-interactive")
        
        transferServerService.withdraw(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .informationNeeded(let response):
                    switch response {
                    case .nonInteractive(let info):
                        XCTAssert(info.fields.count == 4)
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testWithdrawInformationNeededInteractive() {
        let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: informationNeededInteractiveAccount)
        let expectation = XCTestExpectation(description: "Test withdraw information needed interactive")
        
        transferServerService.withdraw(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .informationNeeded(let response):
                    switch response {
                    case .interactive(let info):
                        XCTAssert(info.url == "https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testWithdrawInformationStatus() {
        let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: informationStatusAccount)
        let expectation = XCTestExpectation(description: "Test withdraw information status")
        
        transferServerService.withdraw(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .informationNeeded(let response):
                    switch response {
                    case .status(let info):
                        XCTAssert(info.status == "denied")
                        XCTAssert(info.moreInfoUrl == "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testWithdrawError() {
        let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: errorAccount)
        let expectation = XCTestExpectation(description: "Test withdraw error")
        
        transferServerService.withdraw(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .anchorError(let message):
                    XCTAssert(message == "This anchor doesn't support the given currency code: ETH")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAnchorInfo() {
        let expectation = XCTestExpectation(description: "Test anchor info")
        
        transferServerService.info { (response) -> (Void) in
            switch response {
            case .success(let info):
                XCTAssert(info.deposit["USD"]?.enabled == true)
                XCTAssert(info.deposit["USD"]?.feeFixed == 5)
                XCTAssert(info.deposit["USD"]?.feePercent == 1)
                XCTAssert(info.deposit["USD"]?.fields?["email_address"]?.optional == true)
                XCTAssert(info.deposit["USD"]?.fields?["email_address"]?.description == "your email address for transaction status updates")
                
                XCTAssert(info.withdraw["USD"]?.enabled == true)
                XCTAssert(info.withdraw["USD"]?.feeFixed == 5)
                XCTAssert(info.withdraw["USD"]?.feePercent == 0)
                XCTAssert(info.withdraw["USD"]?.types?["bank_account"]?.fields?["dest"]?.description == "your bank account number")
                
                XCTAssert(info.transactions.enabled == true)
                
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAnchorTransactions() {
        let request = AnchorTransactionsRequest(assetCode: "BTC", account: errorAccount)
        let expectation = XCTestExpectation(description: "Test anchor transactions")
        
        transferServerService.getTransactions(request: request) { (response) -> (Void) in
            switch response {
            case .success(let transactions):
                XCTAssert(transactions.transactions.count == 2)
                XCTAssert(transactions.transactions[0].id == "82fhs729f63dh0v4")
                XCTAssert(transactions.transactions[0].kind == .deposit)
                XCTAssert(transactions.transactions[0].status == .pendingExternal)
                XCTAssert(transactions.transactions[0].statusEta == 3600)
                XCTAssert(transactions.transactions[0].externalTransactionId == "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093")
                XCTAssert(transactions.transactions[0].amountIn == "18.34")
                XCTAssert(transactions.transactions[0].amountOut == "18.24")
                XCTAssert(transactions.transactions[0].amountFee == "0.1")
                XCTAssert(transactions.transactions[0].startedAt == Date(rfc3339String: "2017-03-20T17:05:32Z", fractionalSeconds: false))
                
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutCustomerInfoSuccess() {
        let request = PutCustomerInfoRequest(account: successAccount, jwt: "BTC")
        let expectation = XCTestExpectation(description: "Test put customer info")
        
        transferServerService.putCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutCustomerInfoError() {
        let request = PutCustomerInfoRequest(account: successAccount, jwt: "error_jwt")
        let expectation = XCTestExpectation(description: "Test put customer info")
        
        transferServerService.putCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .anchorError(let message):
                    XCTAssert(message == "This anchor doesn't support the given currency code: ETH")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteCustomerInfoSuccess() {
        let expectation = XCTestExpectation(description: "Test delete customer info")
        
        transferServerService.deleteCustomerInfo(account: successAccount) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteCustomerInfoUnauthorized() {
        let expectation = XCTestExpectation(description: "Test delete customer info")
        
        transferServerService.deleteCustomerInfo(account: creationNotSupportedAccount) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(_):
                XCTAssert(true)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteCustomerInfoNotFound() {
        let expectation = XCTestExpectation(description: "Test delete customer info")
        
        transferServerService.deleteCustomerInfo(account: errorAccount) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(_):
                XCTAssert(true)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
}
