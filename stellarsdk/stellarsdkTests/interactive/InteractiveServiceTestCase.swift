import XCTest
import stellarsdk

class InteractiveServiceTestCase: XCTestCase {

    let interactiveServer = "127.0.0.1"
    
    var interactiveService: InteractiveService!
    var sep24InfoResponseMock: Sep24InfoResponseMock!
    var sep24FeeResponseMock: Sep24FeeResponseMock!
    var sep24DepositResponseMock: Sep24DepositResponseMock!
    var sep24WithdrawResponseMock: Sep24WithdrawResponseMock!
    var sep24TransactionsResponseMock: Sep24TransactionsResponseMock!
    var sep24TransactionResponseMock: Sep24TransactionResponseMock!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        sep24InfoResponseMock = Sep24InfoResponseMock(address: interactiveServer)
        sep24FeeResponseMock = Sep24FeeResponseMock(address: interactiveServer)
        sep24DepositResponseMock = Sep24DepositResponseMock(address: interactiveServer)
        sep24WithdrawResponseMock = Sep24WithdrawResponseMock(address: interactiveServer)
        sep24TransactionsResponseMock = Sep24TransactionsResponseMock(address: interactiveServer)
        sep24TransactionResponseMock = Sep24TransactionResponseMock(address: interactiveServer)
        interactiveService = InteractiveService(serviceAddress: "http://\(interactiveServer)")

    }
    
    
    func testInfo() async {

        let responseEnum = await interactiveService.info(language: "en")
        switch responseEnum {
        case .success(let info):
            XCTAssert(info.depositAssets?.count == 3)
            let depositAssetUSD = info.depositAssets!["USD"]!;
            XCTAssertTrue(depositAssetUSD.enabled)
            XCTAssertEqual(5.0, depositAssetUSD.feeFixed)
            XCTAssertEqual(1.0, depositAssetUSD.feePercent)
            XCTAssertNil(depositAssetUSD.feeMinimum)
            XCTAssertEqual(0.1, depositAssetUSD.minAmount)
            XCTAssertEqual(1000.0, depositAssetUSD.maxAmount)
            
            let depositAssetETH = info.depositAssets!["ETH"]!;
            XCTAssertTrue(depositAssetETH.enabled)
            XCTAssertEqual(0.002, depositAssetETH.feeFixed)
            XCTAssertEqual(0.0, depositAssetETH.feePercent)
            XCTAssertNil(depositAssetETH.feeMinimum)
            XCTAssertNil(depositAssetETH.minAmount)
            XCTAssertNil(depositAssetETH.maxAmount)
            
            let depositAssetNative = info.depositAssets!["native"]!;
            XCTAssertTrue(depositAssetNative.enabled)
            XCTAssertEqual(0.00001, depositAssetNative.feeFixed)
            XCTAssertEqual(0.0, depositAssetNative.feePercent)
            XCTAssertNil(depositAssetETH.feeMinimum)
            XCTAssertNil(depositAssetETH.minAmount)
            XCTAssertNil(depositAssetETH.maxAmount)
            
            XCTAssert(info.withdrawAssets?.count == 3)
            let withdrawAssetUSD = info.withdrawAssets!["USD"]!;
            XCTAssertTrue(withdrawAssetUSD.enabled)
            XCTAssertEqual(5.0, withdrawAssetUSD.feeMinimum)
            XCTAssertEqual(0.5, withdrawAssetUSD.feePercent)
            XCTAssertNil(withdrawAssetUSD.feeFixed)
            XCTAssertEqual(0.1, withdrawAssetUSD.minAmount)
            XCTAssertEqual(1000.0, withdrawAssetUSD.maxAmount)
            
            let withdrawAssetETH = info.withdrawAssets!["ETH"]!;
            XCTAssertFalse(withdrawAssetETH.enabled)
            
            let withdrawAssetNative = info.withdrawAssets!["native"]!;
            XCTAssertTrue(withdrawAssetNative.enabled)
            
            XCTAssertFalse(info.feeEndpointInfo!.enabled)
            XCTAssertTrue(info.featureFlags!.accountCreation)
            XCTAssertTrue(info.featureFlags!.claimableBalances)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testFee() async {
        let rUsd = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: rUsd)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0.013, result.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFeeErr() async {
        let rEth = Sep24FeeRequest(operation: "deposit", assetCode: "ETH", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: rEth)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err{
            case .anchorError(let message):
                XCTAssertEqual("This anchor doesn't support the given currency code: ETH", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testDeposit() async {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.customFields = [String:String]()
        req.customFields!["have"] = "fun"
        req.kycFields = [KYCNaturalPersonFieldsEnum.firstName("John"),
                         KYCNaturalPersonFieldsEnum.lastName("Doe"),
                         KYCNaturalPersonFieldsEnum.emailAddress("john.doe@gmail.com"),];
        
        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual("82fhs729f63dh0v4", result.id)
            XCTAssertEqual("completed", result.type)
            XCTAssertEqual("https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI", result.url)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testWithdraw() async {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.customFields = [String:String]()
        req.customFields!["have"] = "fun"
        req.kycFields = [KYCNaturalPersonFieldsEnum.firstName("John"),
                         KYCNaturalPersonFieldsEnum.lastName("Doe"),
                         KYCNaturalPersonFieldsEnum.emailAddress("john.doe@gmail.com"),];
        
        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual("82fhs729f63dh0v4", result.id)
            XCTAssertEqual("completed", result.type)
            XCTAssertEqual("https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI", result.url)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testTransactions() async {
        
        let req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(4, result.transactions.count)
            let tx = result.transactions[0]
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual("deposit", tx.kind)
            XCTAssertEqual("pending_external", tx.status)
            XCTAssertEqual(3600, tx.statusEta)
            XCTAssertEqual("2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093", tx.externalTransactionId)
            XCTAssertEqual("18.34", tx.amountIn)
            XCTAssertEqual("18.24", tx.amountOut)
            XCTAssertEqual("0.1", tx.amountFee)
            XCTAssertEqual("2017-03-20T17:05:32Z", tx.startedAt.ISO8601Format())
            XCTAssertEqual("2024-03-20T17:05:32Z", tx.userActionRequiredBy?.ISO8601Format())
            XCTAssertNil(tx.claimableBalanceId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testTransaction() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.id = "82fhs729f63dh0v4"
        
        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(let result):
            let tx = result.transaction
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual("withdrawal", tx.kind)
            XCTAssertEqual("completed", tx.status)
            XCTAssertEqual("17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a", tx.stellarTransactionId)
            XCTAssertEqual("1941491", tx.externalTransactionId)
            XCTAssertEqual("510", tx.amountIn)
            XCTAssertEqual("490", tx.amountOut)
            XCTAssertEqual("5", tx.amountFee)
            XCTAssertEqual("2017-03-20T17:00:02Z", tx.startedAt.ISO8601Format())
            XCTAssertEqual("2017-03-20T17:09:58Z", tx.completedAt!.ISO8601Format())
            XCTAssertEqual("2017-03-20T17:09:58Z", tx.updatedAt!.ISO8601Format())
            XCTAssertEqual("https://youranchor.com/tx/242523523", tx.moreInfoUrl)
            XCTAssertNil(tx.claimableBalanceId)
            XCTAssertNil(tx.refunded)
            XCTAssertEqual("186384", tx.withdrawMemo)
            XCTAssertEqual("id", tx.withdrawMemoType)
            XCTAssertNotNil(tx.refunds)
            let refunds = tx.refunds!
            XCTAssertEqual("10", refunds.amountRefunded)
            XCTAssertEqual("5", refunds.amountFee)
            XCTAssertEqual(1, refunds.payments?.count)
            let payment = refunds.payments![0]
            XCTAssertEqual("b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020", payment.id)
            XCTAssertEqual("stellar", payment.idType)
            XCTAssertEqual("10", payment.amount)
            XCTAssertEqual("5", payment.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testEmptyTransactions() async {
        let req = Sep24TransactionsRequest(jwt: "test", assetCode: "USD")
        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0, result.transactions.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testTransactionNotFound() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.id = "1234"
        
        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
                case .notFound(let message):
                    XCTAssertEqual("Transaction not found", message)
                default:
                    XCTFail(err.localizedDescription)
            }
        }
    }
    
    func testForbidden() async {
        let req = Sep24FeeRequest(operation: "deposit", assetCode: "XYZ", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: req)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
                case .authenticationRequired:
                    XCTAssertTrue(true)
                default:
                    XCTFail(err.localizedDescription)
            }
        }
    }
    
    
    func testRequestError() async {
        let req = Sep24FeeRequest(operation: "deposit", assetCode: "ABC", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: req)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
                case .anchorError(let message):
                    XCTAssertEqual("This anchor doesn't support the given currency code: ABC", message)
                default:
                    XCTFail(err.localizedDescription)
            }
        }
    }
}
