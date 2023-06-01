//
//  SorobanTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SorobanTest: XCTestCase {

    let sorobanServer = SorobanServer(endpoint: "https://rpc-futurenet.stellar.org:443")
    let sdk = StellarSDK.futureNet()
    let network = Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let accountBKeyPair = try! KeyPair.generateRandomKeyPair()
    var installTransactionId:String? = nil
    var installWasmId:String? = nil
    var uploadContractWasmFootprint:Footprint? = nil
    var createTransactionId:String? = nil
    var contractId:String? = nil
    var createContractFootprint:Footprint? = nil
    var invokeTransactionId:String? = nil
    var invokeContractFootprint:Footprint? = nil
    var deploySATransactionId:String? = nil
    var deploySAFootprint:Footprint? = nil
    var asset:Asset? = nil
    var deployWithAssetTransactionId:String? = nil
    var deployWithAssetFootprint:Footprint? = nil
    var submitterAccount:AccountResponse?
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
        sorobanServer.acknowledgeExperimental = true
        let accountAId = submitterKeyPair.accountId
        let accountBId = accountBKeyPair.accountId
        let asset = ChangeTrustAsset(canonicalForm: "SONESO:" + accountBId)!
        self.asset = asset
        let changeTrustOp = ChangeTrustOperation(sourceAccountId:accountAId, asset:asset, limit: 100000000)
        let payOp = try! PaymentOperation(sourceAccountId: accountBId, destinationAccountId: accountAId, asset: asset, amount: 50000)
        
        sdk.accounts.createFutureNetTestAccount(accountId: accountAId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createFutureNetTestAccount(accountId: accountBId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.getAccountDetails(accountId: accountBId) { (response) -> (Void) in
                            switch response {
                            case .success(let accountResponse):
                                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                                  operations: [changeTrustOp, payOp],
                                                                  memo: Memo.none)
                                try! transaction.sign(keyPair: self.submitterKeyPair, network: Network.futurenet)
                                try! transaction.sign(keyPair: self.accountBKeyPair, network: Network.futurenet)
                                try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                    switch response {
                                    case .success(let response):
                                        print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                                        expectation.fulfill()
                                    default:
                                        XCTFail()
                                    }
                                }
                            case .failure(_):
                                XCTFail()
                            }
                        }
                    case .failure(_):
                        XCTFail()
                    }
                }
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testAll() {
        getHealth()
        getNetwork()
        
        // upload
        getSubmitterAccount()
        uploadContractWasm(name: "hello")
        getUploadTransactionStatus()
        getTransactionDetails(transactionHash: self.installTransactionId!, type:"upload_wasm")
        getTransactionStatusError()
        
        // create
        getSubmitterAccount()
        createContract()
        getCreateTransactionStatus()
        getTransactionDetails(transactionHash: self.createTransactionId!, type:"create_contract")
        getLedgerEntries()
        
        // invoke
        getSubmitterAccount()
        invokeContract()
        getInvokeTransactionStatus()
        getTransactionDetails(transactionHash: self.invokeTransactionId!, type:"invoke_contract")
        
        // SAC with source account
        getSubmitterAccount()
        deploySACWithSourceAccount()
        getDeploySATransactionStatus()
        getTransactionDetails(transactionHash: self.deploySATransactionId!, type:"create_contract")
        getSACWithSALedgerEntries()
        
        // SAC with asset
        getSubmitterAccount()
        deploySACWithAsset()
        getDeployWithAssetTransactionStatus()
        getTransactionDetails(transactionHash: self.deployWithAssetTransactionId!, type:"create_contract")
        getSACWithAssetLedgerEntries()
        
        // contract id encoding
        contractIdEncoding()
    }
    
    func getHealth() {
        XCTContext.runActivity(named: "getHealth") { activity in
            let expectation = XCTestExpectation(description: "geth health response received")
            
            sorobanServer.getHealth() { (response) -> (Void) in
                switch response {
                case .success(let healthResponse):
                    XCTAssertEqual(HealthStatus.HEALTHY, healthResponse.status)
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func getSubmitterAccount() {
        XCTContext.runActivity(named: "getSubmitterAccount") { activity in
            let expectation = XCTestExpectation(description: "get account response received")
            
            let accountId = submitterKeyPair.accountId
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accResponse):
                    XCTAssertEqual(accountId, accResponse.accountId)
                    self.submitterAccount = accResponse
                    expectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func getNetwork() {
        XCTContext.runActivity(named: "getNetwork") { activity in
            let expectation = XCTestExpectation(description: "geth network response received")
            
            sorobanServer.getNetwork() { (response) -> (Void) in
                switch response {
                case .success(let networkResponse):
                    XCTAssertEqual("https://friendbot-futurenet.stellar.org/", networkResponse.friendbotUrl)
                    XCTAssertEqual("Test SDF Future Network ; October 2022", networkResponse.passphrase)
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func uploadContractWasm(name:String) {
        XCTContext.runActivity(named: "installContractCode") { activity in
            let expectation = XCTestExpectation(description: "contract code successfully deployed")
            
            let bundle = Bundle(for: type(of: self))
            guard let path = bundle.path(forResource: name, ofType: "wasm") else {
                // File not found
                XCTFail()
                return
            }
            let contractCode = FileManager.default.contents(atPath: path)
            let installOperation = try! InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: contractCode!)
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [installOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssert(Int(simulateResponse.cost.cpuInsns)! > 0)
                    XCTAssert(Int(simulateResponse.cost.memBytes)! > 0)
                    XCTAssertNotNil(simulateResponse.results)
                    XCTAssert(simulateResponse.results!.count > 0)
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    
                    self.uploadContractWasmFootprint = simulateResponse.footprint
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope();
                    XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.installTransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getUploadTransactionStatus() {
        XCTContext.runActivity(named: "getUploadTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get deployment status of the upload transaction")
            
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.installTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
                            self.installWasmId = statusResponse.wasmId
                            XCTAssertNotNil(self.installWasmId)
                        } else {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getTransactionDetails(transactionHash:String, type:String) {
        XCTContext.runActivity(named: "getTransactionDetails") { activity in
            let expectation = XCTestExpectation(description: "Get install transaction and operation details sucessfully")
            sdk.transactions.getTransactionDetails(transactionHash: transactionHash) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    XCTAssert(response.operationCount == 1)
                    self.sdk.operations.getOperations(forTransaction: transactionHash, includeFailed:true) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            XCTAssert(response.records.count > 0)
                            if let op = response.records.first! as? InvokeHostFunctionOperationResponse {
                                if let hf = op.hostFunctions?.first {
                                    XCTAssertEqual(hf.type, type)
                                } else {
                                    XCTFail()
                                }
                            } else {
                                XCTFail()
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForTransaction", horizonRequestError: error)
                            XCTFail()
                        }
                        
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionDetails", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func getTransactionStatusError() {
        XCTContext.runActivity(named: "getTransactionStatusError") { activity in
            let expectation = XCTestExpectation(description: "get deployment status of the install transaction containing an error")
            
            self.sorobanServer.getTransaction(transactionHash: "8a6ec76ec8e41b839e7e2df2a5478d5fbf96e5cb0553c86ba1baef6ac1feaa94") { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if GetTransactionResponse.STATUS_NOT_FOUND == response.status {
                        print("OK")
                    } else {
                        XCTFail()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func createContract() {
        XCTContext.runActivity(named: "createContract") { activity in
            let expectation = XCTestExpectation(description: "contract successfully created")
            let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.installWasmId!)
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [createOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssert(Int(simulateResponse.cost.cpuInsns)! > 0)
                    XCTAssert(Int(simulateResponse.cost.memBytes)! > 0)
                    XCTAssertNotNil(simulateResponse.results)
                    XCTAssert(simulateResponse.results!.count > 0)
                    self.createContractFootprint = simulateResponse.footprint
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope();
                    XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.createTransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getCreateTransactionStatus() {
        XCTContext.runActivity(named: "getCreateTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get status of the create transaction")
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.createTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
                            self.contractId = statusResponse.contractId
                            XCTAssertNotNil(self.contractId)
                        } else {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getLedgerEntries() {
        XCTContext.runActivity(named: "getLedgerEntries") { activity in
            let expectation = XCTestExpectation(description: "get ledger entryies for the created contract")
            let contractCodeKey = createContractFootprint?.contractCodeLedgerKey
            let contractDataKey = createContractFootprint?.contractDataLedgerKey
            self.sorobanServer.getLedgerEntry(base64EncodedKey:contractCodeKey!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    XCTAssert(Int(response.latestLedger)! > 0)
                    self.sorobanServer.getLedgerEntry(base64EncodedKey:contractDataKey!) { (response) -> (Void) in
                        switch response {
                        case .success(let ledgerResponse):
                            XCTAssert(Int(ledgerResponse.latestLedger)! > 0)
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func invokeContract() {
        XCTContext.runActivity(named: "invokeContract") { activity in
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let functionName = "hello"
            let arg = SCValXDR.symbol("friend")
            let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: [arg])
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [invokeOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssert(Int(simulateResponse.cost.cpuInsns)! > 0)
                    XCTAssert(Int(simulateResponse.cost.memBytes)! > 0)
                    XCTAssertNotNil(simulateResponse.results)
                    XCTAssert(simulateResponse.results!.count > 0)
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    self.invokeContractFootprint = simulateResponse.footprint
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope();
                    XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.invokeTransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getInvokeTransactionStatus() {
        XCTContext.runActivity(named: "getInvokeTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get status of the invoke transaction")
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.invokeTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
                            if let vec = statusResponse.resultValue?.vec, vec.count > 1 {
                                print("[" + vec[0].symbol! + "," + vec[1].symbol! + "]")
                            }
                            if let vec = statusResponse.resultValue?.vec {
                                for val in vec {
                                    if let sym = val.symbol {
                                        print(sym)
                                        expectation.fulfill()
                                    } else {
                                        XCTFail()
                                    }
                                }
                            } else {
                                XCTFail()
                            }
                        } else {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func deploySACWithSourceAccount() {
        XCTContext.runActivity(named: "deploySACWithSourceAccount") { activity in
            let expectation = XCTestExpectation(description: "contract successfully deployed")
            let deployOperation = try! InvokeHostFunctionOperation.forDeploySACWithSourceAccount()
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [deployOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssert(Int(simulateResponse.cost.cpuInsns)! > 0)
                    XCTAssert(Int(simulateResponse.cost.memBytes)! > 0)
                    XCTAssertNotNil(simulateResponse.results)
                    XCTAssert(simulateResponse.results!.count > 0)
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    self.deploySAFootprint = simulateResponse.footprint
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope();
                    XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.deploySATransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getDeploySATransactionStatus() {
        XCTContext.runActivity(named: "getDeploySATransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get status of the deploy token contract with source account transaction")
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.deploySATransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS != statusResponse.status {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getSACWithSALedgerEntries() {
        XCTContext.runActivity(named: "getSACWithSALedgerEntries") { activity in
            let expectation = XCTestExpectation(description: "get ledger entryies for the deployed token contract with source account")
            let contractDataKey = deploySAFootprint?.contractDataLedgerKey
            self.sorobanServer.getLedgerEntry(base64EncodedKey:contractDataKey!) { (response) -> (Void) in
                switch response {
                case .success(let ledgerResponse):
                    XCTAssert(Int(ledgerResponse.latestLedger)! > 0)
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    
    func deploySACWithAsset() {
        XCTContext.runActivity(named: "deploySACWithAsset") { activity in
            let expectation = XCTestExpectation(description: "contract successfully deployed")
            let accountId = accountBKeyPair.accountId
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let deployOperation = try! InvokeHostFunctionOperation.forDeploySACWithAsset(asset: self.asset)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                       operations: [deployOperation], memo: Memo.none)
                    
                    self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let simulateResponse):
                            XCTAssert(Int(simulateResponse.cost.cpuInsns)! > 0)
                            XCTAssert(Int(simulateResponse.cost.memBytes)! > 0)
                            XCTAssertNotNil(simulateResponse.results)
                            XCTAssert(simulateResponse.results!.count > 0)
                            XCTAssertNotNil(simulateResponse.footprint)
                            XCTAssertNotNil(simulateResponse.transactionData)
                            XCTAssertNotNil(simulateResponse.minResourceFee)
                            
                            transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                            transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                            try! transaction.sign(keyPair: self.accountBKeyPair, network: self.network)
                            self.deployWithAssetFootprint = simulateResponse.footprint
                            // check encoding and decoding
                            let enveloperXdr = try! transaction.encodedEnvelope();
                            XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                            
                            self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                                switch response {
                                case .success(let sendResponse):
                                    XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                                    self.deployWithAssetTransactionId = sendResponse.transactionId
                                case .failure(let error):
                                    self.printError(error: error)
                                    XCTFail()
                                }
                                expectation.fulfill()
                            }
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(_):
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getDeployWithAssetTransactionStatus() {
        XCTContext.runActivity(named: "getDeployWithAssetTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get status of the deploy token contract with asset transaction")
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.deployWithAssetTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS != statusResponse.status {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getSACWithAssetLedgerEntries() {
        XCTContext.runActivity(named: "getSACWithAssetLedgerEntries") { activity in
            let expectation = XCTestExpectation(description: "get ledger entryies for the deployed token contract with asset")
            let contractDataKey = deployWithAssetFootprint?.contractDataLedgerKey
            self.sorobanServer.getLedgerEntry(base64EncodedKey:contractDataKey!) { (response) -> (Void) in
                switch response {
                case .success(let ledgerResponse):
                    XCTAssert(Int(ledgerResponse.latestLedger)! > 0)
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func printError(error:SorobanRpcRequestError) {
        switch error {
        case .requestFailed(let message):
            print(message)
        case .errorResponse(let err):
            print(err)
        case .parsingResponseFailed(let message, _):
            print(message)
        }
    }
    
    func contractIdEncoding() {
        let contractIdA = "86efd9a9d6fbf70297294772c9676127e16a23c2141cab3e29be836bb537a9b9";
        let strEncodedA = "CCDO7WNJ2357OAUXFFDXFSLHMET6C2RDYIKBZKZ6FG7IG25VG6U3SLHT";
        let strEncodedB = try! contractIdA.encodeContractIdHex();
        XCTAssertEqual(strEncodedA, strEncodedB)
        
        let contractIdB = try! strEncodedB.decodeContractIdHex();
        XCTAssertEqual(contractIdA, contractIdB)
    }
}
