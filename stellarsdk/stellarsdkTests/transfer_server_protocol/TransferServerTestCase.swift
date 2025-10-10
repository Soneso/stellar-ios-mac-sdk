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
    
    
    let successBankDepositAccount = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI"
    let successBTCDepositAccount = "GDZHO73UEHTRLF5H3OUJHT42YXT6GQXRWDLYI7MAM3CGSRFTPT4GEIGD"
    let successRippleDepositAccount = "GCA42DZONGM4U7F5NZRBWBO2LGQDJQP4FJIQ4C2T2XMMMGJI5JF6XZL4"
    let successMXNDepositAccount = "GAILDWJHIV5CV4DDEK4ST4YWHOTNDGXC2XOVDFR36JFTYBRIXLLJKLS5"
    
    let successWithdrawAccount = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI"
    
    let creationNotSupportedAccount = "GBTMF7Y4S7S3ZMYLIU5MLVEECJETO7FYIZ5OH3GBDD7W3Z4A6556RTMC"
    let informationNeededNonInteractiveAccount = "GCIKZJNCDA6W335ODLBIINABY53DJXJTW4PPW6CXK623ZTA6LSYZI7SL"
    let informationNeededInteractiveAccount = "GDO4YFV4DI5CZ4FOZKD7PLBTAVGFGFIX4ZE4QNJCDLLAA4YOCXHWVVHI"
    let informationStatusAccount = "GAT3G3YYJJA6PIJJCP33N6RBJODYHMHVA556SBAOZYV5HTGLTFBI2VI3"
    let errorAccount = "GBYLNNAUUJQ7YJSGIATU432IJP2QYTTPKIY5AFWT7LFZAIT76QYVLTAG"
    
    var transferServerService: TransferServerService!
    var depositServerMock: DepositResponseMock!
    var depositExchangeServerMock: DepositExchangeResponseMock!
    var withdrawServerMock: WithdrawResponseMock!
    var withdrawExchangeServerMock: WithdrawExchangeResponseMock!
    var anchorInfoServerMock: AnchorInfoResponseMock!
    var anchorTransactionsServerMock: AnchorTransactionsResponseMock!
    var feeServerMock: FeeResponseMock!
    var txServerMock: TransactionResponseMock!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        
        depositServerMock = DepositResponseMock(address: transferServer)
        depositExchangeServerMock = DepositExchangeResponseMock(address: transferServer)
        withdrawServerMock = WithdrawResponseMock(address: transferServer)
        withdrawExchangeServerMock = WithdrawExchangeResponseMock(address: transferServer)
        anchorInfoServerMock = AnchorInfoResponseMock(address: transferServer)
        anchorTransactionsServerMock = AnchorTransactionsResponseMock(address: transferServer)
        feeServerMock = FeeResponseMock(address: transferServer)
        txServerMock = TransactionResponseMock(address: transferServer)
        transferServerService = TransferServerService(serviceAddress: "http://\(transferServer)")
    }
    
    override func tearDown() {
        
        
        super.tearDown()
    }
    
    func testDepositBankSuccess() async {
        let request = DepositRequest(assetCode: "USD", account: successBankDepositAccount)
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", response.id)
            XCTAssertEqual("Make a payment to Bank: 121122676 Account: 13719713158835300", response.how)
            XCTAssertNil(response.feeFixed)
            guard let instructions = response.instructions else {
                XCTFail()
                return
            }
            let bankNumberInstruction = instructions["organization.bank_number"]!
            XCTAssertEqual("121122676", bankNumberInstruction.value)
            XCTAssertEqual("US bank routing number", bankNumberInstruction.description)
            let bankAccountNumberInstruction = instructions["organization.bank_account_number"]!
            XCTAssertEqual("13719713158835300", bankAccountNumberInstruction.value)
            XCTAssertEqual("US bank account number", bankAccountNumberInstruction.description)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testDepositBTCSuccess() async {
        var request = DepositRequest(assetCode: "BTC", account: successBTCDepositAccount)
        request.extraFields = ["extra_field1" : "test1", "extra_field2" : "test2"];
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", response.id)
            XCTAssertEqual("Make a payment to Bitcoin address 1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB", response.how)
            XCTAssertEqual(0.0002, response.feeFixed)
            guard let instructions = response.instructions else {
                XCTFail()
                return
            }
            let cryptoAddressInstruction = instructions["organization.crypto_address"]!
            XCTAssertEqual("1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB", cryptoAddressInstruction.value)
            XCTAssertEqual("Bitcoin address", cryptoAddressInstruction.description)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testDepositRippleSuccess() async {
        let request = DepositRequest(assetCode: "XRP", account: successRippleDepositAccount)
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", response.id)
            XCTAssertEqual("Make a payment to Ripple address rNXEkKCxvfLcM1h4HJkaj2FtmYuAWrHGbf with tag 88", response.how)
            XCTAssertEqual(60, response.eta)
            XCTAssertEqual(0.1, response.feePercent)
            XCTAssertEqual("You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete.", response.extraInfo!.message)
            guard let instructions = response.instructions else {
                XCTFail()
                return
            }
            let cryptoAddressInstruction = instructions["organization.crypto_address"]!
            XCTAssertEqual("rNXEkKCxvfLcM1h4HJkaj2FtmYuAWrHGbf", cryptoAddressInstruction.value)
            XCTAssertEqual("Ripple address", cryptoAddressInstruction.description)
            let cryptoMemoInstruction = instructions["organization.crypto_memo"]!
            XCTAssertEqual("88", cryptoMemoInstruction.value)
            XCTAssertEqual("Ripple tag", cryptoMemoInstruction.description)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testDepositMXNSuccess() async {
        var request = DepositRequest(assetCode: "MXN", account: successMXNDepositAccount)
        request.amount = "120"
    
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", response.id)
            XCTAssertEqual("Make a payment to Bank: STP Account: 646180111803859359", response.how)
            XCTAssertEqual(1800, response.eta)
            guard let instructions = response.instructions else {
                XCTFail()
                return
            }
            let clabeNrInstruction = instructions["organization.clabe_number"]!
            XCTAssertEqual("646180111803859359", clabeNrInstruction.value)
            XCTAssertEqual("CLABE number", clabeNrInstruction.description)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testDepositAccountCreationNotSupported() async {
        let request = DepositRequest(assetCode: "BTC", account: creationNotSupportedAccount)
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(_):
            return
        }
    }
    
    func testDepositInformationNeededNonInteractive() async {
        let request = DepositRequest(assetCode: "BTC", account: informationNeededNonInteractiveAccount)
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .informationNeeded(let response):
                switch response {
                case .nonInteractive(let info):
                    XCTAssert(info.fields.count == 4)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testDepositInformationStatus() async {
        let request = DepositRequest(assetCode: "BTC", account: informationStatusAccount)
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .informationNeeded(let response):
                switch response {
                case .status(let info):
                    XCTAssert(info.status == "denied")
                    XCTAssert(info.moreInfoUrl == "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testDepositError() async {
        let request = DepositRequest(assetCode: "ETH", account: errorAccount)
        let responseEnum = await transferServerService.deposit(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .anchorError(let message):
                XCTAssert(message == "This anchor doesn't support the given currency code: ETH")
            default:
                XCTFail()
            }
        }
    }
    
    func testDepositExchangeBankSuccess() async {
        var request = DepositExchangeRequest(destinationAsset: "XYZ", sourceAsset: "iso4217:USD", amount: "100", account: successBankDepositAccount)
        request.quoteId = "282837"
        request.locationId = "999"
        request.extraFields = ["extra_field1" : "test1", "extra_field2" : "test2"];
        
        let responseEnum = await transferServerService.depositExchange(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", response.id)
            XCTAssertEqual("Make a payment to Bank: 121122676 Account: 13719713158835300", response.how)
            XCTAssertNil(response.feeFixed)
            guard let instructions = response.instructions else {
                XCTFail()
                return
            }
            let bankNumberInstruction = instructions["organization.bank_number"]!
            XCTAssertEqual("121122676", bankNumberInstruction.value)
            XCTAssertEqual("US bank routing number", bankNumberInstruction.description)
            let bankAccountNumberInstruction = instructions["organization.bank_account_number"]!
            XCTAssertEqual("13719713158835300", bankAccountNumberInstruction.value)
            XCTAssertEqual("US bank account number", bankAccountNumberInstruction.description)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testWithdrawSuccess() async {
        var request = WithdrawRequest(type: "crypto", assetCode: "XLM")
        request.dest =  successWithdrawAccount
        request.account = "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ"
        request.amount = "120"
        request.extraFields = ["extra_field1" : "test1", "extra_field2" : "test2"];
        
        let responseEnum = await transferServerService.withdraw(request: request)
        switch responseEnum {
        case .success(let info):
            XCTAssertEqual("GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ", info.accountId)
            XCTAssertEqual("id", info.memoType)
            XCTAssertEqual("123", info.memo)
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", info.id)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testWithdrawAccountCreationNotSupported() async {
        var request = WithdrawRequest(type: "crypto", assetCode: "BTC")
        request.dest =  creationNotSupportedAccount
        let responseEnum = await transferServerService.withdraw(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(_):
            return
        }
    }
    
    func testWithdrawInformationNeededNonInteractive() async {
        var request = WithdrawRequest(type: "crypto", assetCode: "BTC")
        request.dest = informationNeededNonInteractiveAccount
        let responseEnum = await transferServerService.withdraw(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .informationNeeded(let response):
                switch response {
                case .nonInteractive(let info):
                    XCTAssert(info.fields.count == 4)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testWithdrawInformationStatus() async {
        var request = WithdrawRequest(type: "crypto", assetCode: "BTC")
        request.dest = informationStatusAccount
        let responseEnum = await transferServerService.withdraw(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .informationNeeded(let response):
                switch response {
                case .status(let info):
                    XCTAssert(info.status == "denied")
                    XCTAssert(info.moreInfoUrl == "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
    }
    
    func testWithdrawError() async {
        var request = WithdrawRequest(type: "crypto", assetCode: "ETH")
        request.dest = errorAccount
        let responseEnum = await transferServerService.withdraw(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .anchorError(let message):
                XCTAssert(message == "This anchor doesn't support the given currency code: ETH")
            default:
                XCTFail()
            }
        }
    }
    
    func testWithdrawExchangeSuccess() async {
        var request = WithdrawExchangeRequest(sourceAsset: "XYZ", destinationAsset: "iso4217:USD", amount: "700", type: "bank_account")
        request.quoteId = "282837"
        request.locationId = "120"
        request.extraFields = ["extra_field1" : "test1", "extra_field2" : "test2"];
        
        let responseEnum = await transferServerService.withdrawExchange(request: request)
        switch responseEnum {
        case .success(let info):
            XCTAssertEqual("GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ", info.accountId)
            XCTAssertEqual("id", info.memoType)
            XCTAssertEqual("123", info.memo)
            XCTAssertEqual("9421871e-0623-4356-b7b5-5996da122f3e", info.id)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testAnchorInfo() async {
        let responseEnum = await transferServerService.info()
        switch responseEnum {
        case .success(let info):
            XCTAssertEqual(2, info.deposit!.count)
            if let depositUsd = info.deposit?["USD"] {
                XCTAssertTrue(depositUsd.enabled)
                XCTAssertNotNil(depositUsd.authenticationRequired)
                XCTAssertTrue(depositUsd.authenticationRequired!)
                XCTAssertNil(depositUsd.feeFixed)
                XCTAssertNil(depositUsd.feePercent)
                XCTAssertEqual(0.1, depositUsd.minAmount)
                XCTAssertEqual(1000.0, depositUsd.maxAmount)
            } else {
                XCTFail()
            }
            if let depositUsdFields = info.deposit?["USD"]?.fields {
                XCTAssertEqual(4, depositUsdFields.count)
                XCTAssertNotNil(depositUsdFields["email_address"])
                let emailAddress = depositUsdFields["email_address"]!
                XCTAssertEqual("your email address for transaction status updates", emailAddress.description)
                XCTAssertNotNil(emailAddress.optional)
                XCTAssertTrue(emailAddress.optional!)
                XCTAssertTrue(depositUsdFields["country_code"]!.choices!.contains("USA"))
                XCTAssertTrue(depositUsdFields["type"]!.choices!.contains("SWIFT"))
            } else {
                XCTFail()
            }
            
            if let depositExUsd = info.depositExchange?["USD"] {
                XCTAssertFalse(depositExUsd.enabled)
                XCTAssertNotNil(depositExUsd.authenticationRequired)
                XCTAssertTrue(depositExUsd.authenticationRequired!)
            } else {
                XCTFail()
            }
            
            if let depositExUsdFields = info.depositExchange?["USD"]?.fields {
                XCTAssertEqual(4, depositExUsdFields.count)
                XCTAssertNotNil(depositExUsdFields["email_address"])
                let emailAddress = depositExUsdFields["email_address"]!
                XCTAssertEqual("your email address for transaction status updates", emailAddress.description)
                XCTAssertNotNil(emailAddress.optional)
                XCTAssertTrue(emailAddress.optional!)
                XCTAssertTrue(depositExUsdFields["country_code"]!.choices!.contains("USA"))
                XCTAssertTrue(depositExUsdFields["type"]!.choices!.contains("SWIFT"))
            } else {
                XCTFail()
            }
            
            XCTAssertEqual(2, info.withdraw!.count)
            if let withdrawUsd = info.withdraw?["USD"] {
                XCTAssertTrue(withdrawUsd.enabled)
                XCTAssertNotNil(withdrawUsd.authenticationRequired)
                XCTAssertTrue(withdrawUsd.authenticationRequired!)
                XCTAssertNil(withdrawUsd.feeFixed)
                XCTAssertNil(withdrawUsd.feePercent)
                XCTAssertEqual(0.1, withdrawUsd.minAmount)
                XCTAssertEqual(1000.0, withdrawUsd.maxAmount)
            } else {
                XCTFail()
            }
            
            if let withdrawUsdTypes = info.withdraw?["USD"]?.types {
                let bankAccountFields = withdrawUsdTypes["bank_account"]!.fields!
                XCTAssertTrue(bankAccountFields["country_code"]!.choices!.contains("PRI"))
                XCTAssertTrue(withdrawUsdTypes["cash"]!.fields!["dest"]!.optional!)
            } else {
                XCTFail()
            }
            
            if let withdrawExUsd = info.withdrawExchange?["USD"] {
                XCTAssertFalse(withdrawExUsd.enabled)
                XCTAssertNotNil(withdrawExUsd.authenticationRequired)
                XCTAssertTrue(withdrawExUsd.authenticationRequired!)
            } else {
                XCTFail()
            }
            
            if let withdrawUsdExTypes = info.withdrawExchange?["USD"]?.types {
                let bankAccountFields = withdrawUsdExTypes["bank_account"]!.fields!
                XCTAssertTrue(bankAccountFields["country_code"]!.choices!.contains("PRI"))
                XCTAssertTrue(withdrawUsdExTypes["cash"]!.fields!["dest"]!.optional!)
            } else {
                XCTFail()
            }
            
            XCTAssertFalse(info.fee!.enabled)
            XCTAssertTrue(info.transactions!.enabled)
            XCTAssertTrue(info.transactions!.authenticationRequired!)
            XCTAssertTrue(info.features!.accountCreation)
            XCTAssertTrue(info.features!.claimableBalances)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testAnchorTransactions() async {
        let request = AnchorTransactionsRequest(assetCode: "XLM", account: "GCTTGO5ABSTHABXWL2FMHPZ2XFOZDXJYJN5CKFRKXMPAAWZW3Y3JZ3JK")
        let responseEnum = await transferServerService.getTransactions(request: request)
        switch responseEnum {
        case .success(let transactions):
            XCTAssert(transactions.transactions.count == 7)
            XCTAssert(transactions.transactions[0].id == "82fhs729f63dh0v4")
            XCTAssert(transactions.transactions[0].kind == .deposit)
            XCTAssert(transactions.transactions[0].status == .pendingExternal)
            XCTAssert(transactions.transactions[0].statusEta == 3600)
            XCTAssert(transactions.transactions[0].externalTransactionId == "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093")
            XCTAssert(transactions.transactions[0].amountIn == "18.34")
            XCTAssert(transactions.transactions[0].amountOut == "18.24")
            XCTAssert(transactions.transactions[0].amountFee == "0.1")
            XCTAssert(transactions.transactions[0].startedAt == Date(rfc3339String: "2017-03-20T17:05:32Z", fractionalSeconds: false))
            XCTAssert(transactions.transactions[0].userActionRequiredBy == Date(rfc3339String: "2024-03-20T17:05:32Z", fractionalSeconds: false))
            
            var tx = transactions.transactions[1]
            XCTAssert(tx.id == "52fys79f63dh3v2")
            XCTAssert(tx.kind == .depositExchange)
            XCTAssert(tx.status == .pendingAnchor)
            XCTAssert(tx.statusEta == 3600)
            XCTAssert(tx.externalTransactionId == "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093")
            XCTAssert(tx.amountIn == "500")
            XCTAssert(tx.amountInAsset == "iso4217:BRL")
            XCTAssert(tx.amountOut == "100")
            XCTAssert(tx.amountOutAsset == "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssert(tx.amountFee == "0.1")
            XCTAssert(tx.amountFeeAsset == "iso4217:BRL")
            XCTAssert(tx.startedAt == Date(rfc3339String: "2021-06-11T17:05:32Z", fractionalSeconds: false))
            
            tx = transactions.transactions[2]
            XCTAssert(tx.id == "82fhs729f63dh0v4")
            XCTAssert(tx.kind == .withdrawal)
            XCTAssert(tx.status == .completed)
            XCTAssertNil(tx.statusEta)
            XCTAssert(tx.amountIn == "510")
            XCTAssert(tx.amountOut == "490")
            XCTAssert(tx.amountFee == "5")
            XCTAssert(tx.startedAt == Date(rfc3339String: "2017-03-20T17:00:02Z", fractionalSeconds: false))
            XCTAssert(tx.completedAt == Date(rfc3339String: "2017-03-20T17:09:58Z", fractionalSeconds: false))
            XCTAssert(tx.stellarTransactionId == "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a")
            XCTAssert(tx.externalTransactionId == "1238234")
            XCTAssert(tx.withdrawAnchorAccount == "GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL")
            XCTAssert(tx.withdrawMemo == "186384")
            XCTAssert(tx.withdrawMemoType == "id")
            
            var refunds = tx.refunds!
            XCTAssert(refunds.amountRefunded == "10")
            XCTAssert(refunds.amountFee == "5")
            
            var payments = refunds.payments!
            XCTAssert(payments.count == 1)
            var payment = payments.first!
            XCTAssert(payment.id == "b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020")
            XCTAssert(payment.idType == "stellar")
            XCTAssert(payment.amount == "10")
            XCTAssert(payment.fee == "5")
            
            tx = transactions.transactions[3]
            XCTAssert(tx.id == "72fhs729f63dh0v1")
            XCTAssert(tx.kind == .deposit)
            XCTAssert(tx.status == .completed)
            XCTAssertNil(tx.statusEta)
            XCTAssert(tx.amountIn == "510")
            XCTAssert(tx.amountOut == "490")
            XCTAssert(tx.amountFee == "5")
            XCTAssert(tx.startedAt == Date(rfc3339String: "2017-03-20T17:00:02Z", fractionalSeconds: false))
            XCTAssert(tx.completedAt == Date(rfc3339String: "2017-03-20T17:09:58Z", fractionalSeconds: false))
            XCTAssert(tx.stellarTransactionId == "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a")
            XCTAssert(tx.externalTransactionId == "1238234")
            XCTAssert(tx.from == "AJ3845SAD")
            XCTAssert(tx.to == "GBITQ4YAFKD2372TNAMNHQ4JV5VS3BYKRK4QQR6FOLAR7XAHC3RVGVVJ")
            
            refunds = tx.refunds!
            XCTAssert(refunds.amountRefunded == "10")
            XCTAssert(refunds.amountFee == "5")
            
            payments = refunds.payments!
            XCTAssert(payments.count == 1)
            payment = payments.first!
            XCTAssert(payment.id == "104201")
            XCTAssert(payment.idType == "external")
            XCTAssert(payment.amount == "10")
            XCTAssert(payment.fee == "5")
            
            tx = transactions.transactions[4]
            XCTAssert(tx.id == "52fys79f63dh3v1")
            XCTAssert(tx.kind == .withdrawal)
            XCTAssert(tx.status == .pendingTransactionInfoUpdate)
            XCTAssertNil(tx.statusEta)
            XCTAssert(tx.amountIn == "750.00")
            XCTAssert(tx.startedAt == Date(rfc3339String: "2017-03-20T17:00:02Z", fractionalSeconds: false))
            XCTAssert(tx.requiredInfoMessage == "We were unable to send funds to the provided bank account. Bank error: 'Account does not exist'. Please provide the correct bank account address.")

            let requiredInfoUpdates = tx.requiredInfoUpdates!
            XCTAssert(requiredInfoUpdates.fields!.count == 2)
            let dest = requiredInfoUpdates.fields!["dest"]!
            XCTAssert(dest.description == "your bank account number")
            let destExtra = requiredInfoUpdates.fields!["dest_extra"]!
            XCTAssert(destExtra.description == "your routing number")
            
            tx = transactions.transactions[5]
            XCTAssert(tx.id == "52fys79f63dh3v2")
            XCTAssert(tx.kind == .withdrawalExchange)
            XCTAssert(tx.status == .pendingAnchor)
            XCTAssert(tx.statusEta == 3600)
            XCTAssert(tx.amountIn == "100")
            XCTAssert(tx.amountInAsset == "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssert(tx.amountOut == "500")
            XCTAssert(tx.amountOutAsset == "iso4217:BRL")
            XCTAssert(tx.amountFee == "0.1")
            XCTAssert(tx.amountFeeAsset == "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssert(tx.startedAt == Date(rfc3339String: "2021-06-11T17:05:32Z", fractionalSeconds: false))

            tx = transactions.transactions[6]
            XCTAssert(tx.id == "92fys79f63dh3v3")
            XCTAssert(tx.kind == .deposit)
            XCTAssert(tx.status == .expired)
            XCTAssert(tx.amountIn == "100.00")
            XCTAssert(tx.amountOut == "0")
            XCTAssert(tx.amountFee == "0")
            XCTAssert(tx.startedAt == Date(rfc3339String: "2023-03-20T17:00:02Z", fractionalSeconds: false))
            XCTAssert(tx.message == "Transaction expired due to user inactivity")
        case .failure(_):
            XCTFail()
        }
    }
    
    func testSingleTxSuccess() async {
        let request = AnchorTransactionRequest(id:"82fhs729f63dh0v4", stellarTransactionId: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a")
        
        let responseEnum = await transferServerService.getTransaction(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssert(response.transaction.id == "82fhs729f63dh0v4")
            XCTAssert(response.transaction.kind == .deposit)
            XCTAssert(response.transaction.status == .pendingExternal)
            XCTAssert(response.transaction.statusEta == 3600)
            XCTAssert(response.transaction.externalTransactionId == "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093")
            XCTAssert(response.transaction.amountIn == "18.34")
            XCTAssert(response.transaction.amountOut == "18.24")
            XCTAssert(response.transaction.amountFee == "0.1")
            XCTAssert(response.transaction.startedAt == Date(rfc3339String: "2017-03-20T17:05:32Z", fractionalSeconds: false))
        case .failure(_):
            XCTFail()
        }
    }
    
    func testFeeSuccess() async {
        var request = FeeRequest(operation: "deposit", assetCode: "ETH", amount: 2034.09)
        request.type = "SEPA"
        
        let responseEnum = await transferServerService.fee(request: request)
        switch responseEnum {
        case .success(let info):
            XCTAssertEqual(0.013, info.fee)
        case .failure(_):
            XCTFail()
        }
    }
}
