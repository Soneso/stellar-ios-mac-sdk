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

    let sorobanServer = SorobanServer(endpoint: "https://futurenet.sorobandev.com/soroban/rpc")
    let sdk = StellarSDK.futureNet()
    let network = Network.futurenet
    let accountAKeyPair = try! KeyPair.generateRandomKeyPair()
    let accountBKeyPair = try! KeyPair.generateRandomKeyPair()
    var installTransactionId:String? = nil
    var installWasmId:String? = nil
    var installContractFootprint:Footprint? = nil
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
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        let accountAId = accountAKeyPair.accountId
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
                                try! transaction.sign(keyPair: self.accountAKeyPair, network: Network.futurenet)
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
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testAll() {
        getHealth()
        getAccount()
        installContractCode()
        getInstallTransactionStatus()
        getTransactionDetails(transactionHash: self.installTransactionId!, footprint: self.installContractFootprint!.xdrEncoded)
        getTransactionStatusError()
        createContract()
        getCreateTransactionStatus()
        getTransactionDetails(transactionHash: self.createTransactionId!, footprint: self.createContractFootprint!.xdrEncoded)
        getLedgerEntries()
        invokeContract()
        getInvokeTransactionStatus()
        getTransactionDetails(transactionHash: self.invokeTransactionId!, footprint: self.invokeContractFootprint!.xdrEncoded)
        deployTokenCountractWithSourceAccount()
        getDeploySATransactionStatus()
        getTransactionDetails(transactionHash: self.deploySATransactionId!, footprint: self.deploySAFootprint!.xdrEncoded)
        getTokenContractWithSALedgerEntries()
        deployTokenCountractWithAsset()
        getDeployWithAssetTransactionStatus()
        getTransactionDetails(transactionHash: self.deployWithAssetTransactionId!, footprint: self.deployWithAssetFootprint!.xdrEncoded)
        getTokenContractWithAssetLedgerEntries()
    }
    
    func getHealth() {
        let expectation = XCTestExpectation(description: "geth health response received")
        
        sorobanServer.getHealth() { (response) -> (Void) in
            switch response {
            case .success(let healthResponse):
                XCTAssertEqual("healthy", healthResponse.status)
            case .failure(let error):
                self.printError(error: error)
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func getAccount() {
        let expectation = XCTestExpectation(description: "get account response received")
        
        let accountId = accountAKeyPair.accountId
        sorobanServer.getAccount(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accResponse):
                XCTAssertEqual(accountId, accResponse.id)
                XCTAssertNotEqual(accountId, accResponse.sequence)
                expectation.fulfill()
            case .failure(let error):
                self.printError(error: error)
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func installContractCode() {
        let expectation = XCTestExpectation(description: "contract code successfully deployed")
        
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "hello", ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let contractCode = FileManager.default.contents(atPath: path)
        let accountId = accountAKeyPair.accountId
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                let installOperation = try! InvokeHostFunctionOperation.forInstallingContract(contractCode: contractCode!)
                
                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                   operations: [installOperation], memo: Memo.none)
                
                self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        XCTAssert(Int(response.cost.cpuInsns)! > 0)
                        XCTAssert(Int(response.cost.memBytes)! > 0)
                        XCTAssertNotNil(response.results)
                        XCTAssert(response.results!.count > 0)
                        transaction.setFootprint(footprint: response.footprint)
                        self.installContractFootprint = response.footprint
                        try! transaction.sign(keyPair: self.accountAKeyPair, network: self.network)
                        
                        // check encoding and decoding
                        let enveloperXdr = try! transaction.encodedEnvelope();
                        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                        
                        self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                XCTAssert("pending" == response.status)
                                self.installTransactionId = response.transactionId
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
    
    func getInstallTransactionStatus() {
        let expectation = XCTestExpectation(description: "get deployment status of the install transaction")
        
        // wait a couple of seconds before checking the status
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            self.sorobanServer.getTransactionStatus(transactionHash: self.installTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if "success" == response.status {
                        self.installWasmId = response.wasmId
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
    
    func getTransactionDetails(transactionHash:String, footprint:String) {
        XCTContext.runActivity(named: "getInstallTransactionDetails") { activity in
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
                                XCTAssertEqual(op.footprint, footprint)
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
        let expectation = XCTestExpectation(description: "get deployment status of the install transaction containing an error")
        
        self.sorobanServer.getTransactionStatus(transactionHash: "8a6ec76ec8e41b839e7e2df2a5478d5fbf96e5cb0553c86ba1baef6ac1feaa94") { (response) -> (Void) in
            switch response {
            case .success(let response):
                if "error" == response.status {
                    print("Status err: \(response.error!)")
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
    
    func createContract() {
        let expectation = XCTestExpectation(description: "contract successfully created")
        let accountId = accountAKeyPair.accountId
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.installWasmId!)
                
                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                   operations: [createOperation], memo: Memo.none)
                
                self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        XCTAssert(Int(response.cost.cpuInsns)! > 0)
                        XCTAssert(Int(response.cost.memBytes)! > 0)
                        XCTAssertNotNil(response.results)
                        XCTAssert(response.results!.count > 0)
                        self.createContractFootprint = response.footprint
                        transaction.setFootprint(footprint: response.footprint)
                        try! transaction.sign(keyPair: self.accountAKeyPair, network: self.network)
                        
                        // check encoding and decoding
                        let enveloperXdr = try! transaction.encodedEnvelope();
                        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                        
                        self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                XCTAssert("pending" == response.status)
                                self.createTransactionId = response.transactionId
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
    
    func getCreateTransactionStatus() {
        let expectation = XCTestExpectation(description: "get status of the create transaction")
        // wait a couple of seconds before checking the status
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            self.sorobanServer.getTransactionStatus(transactionHash: self.createTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if "success" == response.status {
                        self.contractId = response.contractId
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
    
    func getLedgerEntries() {
        let expectation = XCTestExpectation(description: "get ledger entryies for the created contract")
        let contractCodeKey = createContractFootprint?.contractCodeLedgerKey
        let contractDataKey = createContractFootprint?.contractDataLedgerKey
        self.sorobanServer.getLedgerEntry(base64EncodedKey:contractCodeKey!) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssert(Int(response.latestLedger)! > 0)
                self.sorobanServer.getLedgerEntry(base64EncodedKey:contractDataKey!) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        XCTAssert(Int(response.latestLedger)! > 0)
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
    
    func invokeContract() {
        let expectation = XCTestExpectation(description: "contract successfully invoked")
        let accountId = accountAKeyPair.accountId
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                let arg = SCValXDR.symbol("friend")
                let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: "hello", functionArguments: [arg])
                
                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                   operations: [invokeOperation], memo: Memo.none)
                
                self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        XCTAssert(Int(response.cost.cpuInsns)! > 0)
                        XCTAssert(Int(response.cost.memBytes)! > 0)
                        XCTAssertNotNil(response.results)
                        XCTAssert(response.results!.count > 0)
                        transaction.setFootprint(footprint: response.footprint)
                        try! transaction.sign(keyPair: self.accountAKeyPair, network: self.network)
                        self.invokeContractFootprint = response.footprint
                        
                        // check encoding and decoding
                        let enveloperXdr = try! transaction.encodedEnvelope();
                        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                        
                        self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                XCTAssert("pending" == response.status)
                                self.invokeTransactionId = response.transactionId
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
    
    func getInvokeTransactionStatus() {
        let expectation = XCTestExpectation(description: "get status of the invoke transaction")
        // wait a couple of seconds before checking the status
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            self.sorobanServer.getTransactionStatus(transactionHash: self.invokeTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if "success" == response.status {
                        if let result = response.firstResult {
                            let val = try! SCValXDR.fromXdr(base64: result.xdr)
                            if let vec = val.object?.vec {
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
    
    func deployTokenCountractWithSourceAccount() {
        let expectation = XCTestExpectation(description: "contract successfully deployed")
        let accountId = accountAKeyPair.accountId
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                let deployOperation = try! InvokeHostFunctionOperation.forDeployCreateTokenContractWithSourceAccount()
                
                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                   operations: [deployOperation], memo: Memo.none)
                
                self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        XCTAssert(Int(response.cost.cpuInsns)! > 0)
                        XCTAssert(Int(response.cost.memBytes)! > 0)
                        XCTAssertNotNil(response.results)
                        XCTAssert(response.results!.count > 0)
                        transaction.setFootprint(footprint: response.footprint)
                        try! transaction.sign(keyPair: self.accountAKeyPair, network: self.network)
                        self.deploySAFootprint = response.footprint
                        // check encoding and decoding
                        let enveloperXdr = try! transaction.encodedEnvelope();
                        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                        
                        self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                XCTAssert("pending" == response.status)
                                self.deploySATransactionId = response.transactionId
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
    
    func getDeploySATransactionStatus() {
        let expectation = XCTestExpectation(description: "get status of the deploy token contract with source account transaction")
        // wait a couple of seconds before checking the status
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            self.sorobanServer.getTransactionStatus(transactionHash: self.deploySATransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if "success" != response.status {
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
    
    func getTokenContractWithSALedgerEntries() {
        let expectation = XCTestExpectation(description: "get ledger entryies for the deployed token contract with source account")
        let contractDataKey = deploySAFootprint?.contractDataLedgerKey
        self.sorobanServer.getLedgerEntry(base64EncodedKey:contractDataKey!) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssert(Int(response.latestLedger)! > 0)
            case .failure(let error):
                self.printError(error: error)
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    
    func deployTokenCountractWithAsset() {
        let expectation = XCTestExpectation(description: "contract successfully deployed")
        let accountId = accountBKeyPair.accountId
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                let deployOperation = try! InvokeHostFunctionOperation.forDeployCreateTokenContractWithAsset(asset: self.asset)
                
                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                   operations: [deployOperation], memo: Memo.none)
                
                self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(let response):
                        XCTAssert(Int(response.cost.cpuInsns)! > 0)
                        XCTAssert(Int(response.cost.memBytes)! > 0)
                        XCTAssertNotNil(response.results)
                        XCTAssert(response.results!.count > 0)
                        transaction.setFootprint(footprint: response.footprint)
                        try! transaction.sign(keyPair: self.accountBKeyPair, network: self.network)
                        self.deployWithAssetFootprint = response.footprint
                        // check encoding and decoding
                        let enveloperXdr = try! transaction.encodedEnvelope();
                        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                        
                        self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                XCTAssert("pending" == response.status)
                                self.deployWithAssetTransactionId = response.transactionId
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
    
    func getDeployWithAssetTransactionStatus() {
        let expectation = XCTestExpectation(description: "get status of the deploy token contract with asset transaction")
        // wait a couple of seconds before checking the status
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            self.sorobanServer.getTransactionStatus(transactionHash: self.deployWithAssetTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if "success" != response.status {
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
    
    func getTokenContractWithAssetLedgerEntries() {
        let expectation = XCTestExpectation(description: "get ledger entryies for the deployed token contract with asset")
        let contractDataKey = deployWithAssetFootprint?.contractDataLedgerKey
        self.sorobanServer.getLedgerEntry(base64EncodedKey:contractDataKey!) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssert(Int(response.latestLedger)! > 0)
            case .failure(let error):
                self.printError(error: error)
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
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
}
