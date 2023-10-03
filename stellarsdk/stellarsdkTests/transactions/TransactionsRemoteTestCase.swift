//
//  TransactionsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionsRemoteTestCase: XCTestCase {

    let sdk = StellarSDK()
    var streamItem:TransactionsStreamItem? = nil
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let destinationKeyPair = try! KeyPair.generateRandomKeyPair()
    let claimantKeyPair = try! KeyPair.generateRandomKeyPair()
    let payerKeyPair = try! KeyPair.generateRandomKeyPair()
    var effectsStreamItem:EffectsStreamItem? = nil
    var claimableBalanceId:String? = nil
    var transactionId:String? = nil
    var feeBumpTransactionId:String? = nil
    var feeBumpTransactionV0Id:String? = nil
    let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
    let network = Network.testnet
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")
        let createAccountOp1 = try! CreateAccountOperation(sourceAccountId: testKeyPair.accountId, destinationAccountId: claimantKeyPair.accountId, startBalance: 100)
        let createAccountOp2 = try! CreateAccountOperation(sourceAccountId: testKeyPair.accountId, destinationAccountId: destinationKeyPair.accountId, startBalance: 100)
        let createAccountOp3 = try! CreateAccountOperation(sourceAccountId: testKeyPair.accountId, destinationAccountId: payerKeyPair.accountId, startBalance: 100)
        
        sdk.accounts.createTestAccount(accountId: testKeyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.getAccountDetails(accountId: self.testKeyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountResponse):
                        let transaction = try! Transaction(sourceAccount: accountResponse,
                                                          operations: [createAccountOp1, createAccountOp2, createAccountOp3],
                                                          memo: Memo.none)
                        try! transaction.sign(keyPair: self.testKeyPair, network: self.network)
                        
                        try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                                self.transactionId = response.transactionHash
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
        wait(for: [expectation], timeout: 25.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() {
        getTransactions()
        getTransactionsForAccount()
        createClaimableBalance()
        getTransactionsForClaimableBalance()
        getTransactionsForLedger()
        getTransactionDetails()
        checkTransactionSigning()
        checkTransactionMultiSigning()
        checkTransactionEnvelopePost()
        checkTransactionV1Sign()
        checkTransactionV1Sign2()
        checkTransactionSponsoringXDR()
        checkTransactionSponsoringXDR2()
        checkTransactionSponsoringXDR3()
        checkTransactionV0SignWithTwoOperations()
        coSignTransactionEnvelope()
        coSignTransactionEnvelope2()
        coSignTransactionEnvelope3()
        feeBumpTransactionEnvelopePost()
        getFeeBumpTransactionDetails()
    }
    
    func getTransactions() {
        XCTContext.runActivity(named: "getTransactions") { activity in
            let expectation = XCTestExpectation(description: "Get transactions")
            
            sdk.transactions.getTransactions(limit: 15) { (response) -> (Void) in
                switch response {
                case .success(let transactionsResponse):
                    // load next page
                    transactionsResponse.getNextPage(){ (response) -> (Void) in
                        switch response {
                        case .success(let nextTransactionsResponse):
                            // load previous page, should contain the same transactions as the first page
                            nextTransactionsResponse.getPreviousPage(){ (response) -> (Void) in
                                switch response {
                                case .success(let prevTransactionsResponse):
                                    let transaction1 = transactionsResponse.records.first
                                    let transaction2 = prevTransactionsResponse.records.last // because ordering is asc now.
                                    XCTAssertTrue(transaction1?.id == transaction2?.id)
                                    XCTAssertTrue(transaction1?.transactionHash == transaction2?.transactionHash)
                                    XCTAssertTrue(transaction1?.ledger == transaction2?.ledger)
                                    XCTAssertTrue(transaction1?.createdAt == transaction2?.createdAt)
                                    XCTAssertTrue(transaction1?.sourceAccount == transaction2?.sourceAccount)
                                    XCTAssertTrue(transaction1?.sourceAccountSequence == transaction2?.sourceAccountSequence)
                                    XCTAssertTrue(transaction1?.maxFee == transaction2?.maxFee)
                                    XCTAssertTrue(transaction1?.feeAccount == transaction2?.feeAccount)
                                    XCTAssertTrue(transaction1?.feeCharged == transaction2?.feeCharged)
                                    XCTAssertTrue(transaction1?.operationCount == transaction2?.operationCount)
                                    XCTAssertTrue(transaction1?.memoType == transaction2?.memoType)
                                    XCTAssertTrue(transaction1?.memo == transaction2?.memo)
                                    XCTAssert(true)
                                    expectation.fulfill()
                                case .failure(let error):
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                                    XCTFail()
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                            XCTFail()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getTransactionsForAccount() {
        XCTContext.runActivity(named: "getTransactionsForAccount") { activity in
            let expectation = XCTestExpectation(description: "Get transactions for account")
            let pk = testKeyPair.accountId
            sdk.transactions.getTransactions(forAccount: pk ,order: Order.descending) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    XCTAssertFalse(response.records.isEmpty)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionsForAccount", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func createClaimableBalance() {
        XCTContext.runActivity(named: "createClaimableBalance") { activity in
            
            let expectation = XCTestExpectation(description: "creates claimable balance")
            let sourceAccountKeyPair = testKeyPair
            let sourceAccountId = sourceAccountKeyPair.accountId
            let claimantAccountKeyPair = claimantKeyPair
            let claimantAccountId = claimantAccountKeyPair.accountId
            
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:sourceAccountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? ClaimableBalanceCreatedEffectResponse {
                        if let balanceId = self.claimableBalanceId, effect.balanceId.hasSuffix(balanceId) {
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("createClaimableBalance stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let claimant = Claimant(destination:claimantAccountId)
                    let claimants = [ claimant]
                    let createClaimableBalance = CreateClaimableBalanceOperation(asset: self.assetNative!, amount: 1.00, claimants: claimants)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [createClaimableBalance],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let submitTransactionResponse):
                            switch submitTransactionResponse.transactionMeta {
                            case .transactionMetaV3(let metaV3):
                                for opMeta in metaV3.operations {
                                    for change in opMeta.changes.ledgerEntryChanges {
                                        switch change {
                                        case .created(let entry):
                                            switch entry.data {
                                            case .claimableBalance(let IDXdr):
                                                switch IDXdr.claimableBalanceID {
                                                case .claimableBalanceIDTypeV0(let data):
                                                    self.claimableBalanceId = self.hexEncodedBalanceId(data: data.wrapped)
                                                }
                                            default:
                                                break
                                            }
                                        default:
                                            break
                                        }
                                    }
                                }
                            default:
                                break
                            }
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 315.0)
        }
    }
    
    func hexEncodedBalanceId(data: Data) -> String {
        let hexDigits = Array(("0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * data.count)
        for byte in data {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        var z = String(utf16CodeUnits: chars, count: chars.count)
        let leadingZeros = 72 - chars.count
        if (leadingZeros > 0){
            z = String(format: "%0"+String(leadingZeros)+"d", 0) + z
        }
        return z
    }
    
    func getTransactionsForClaimableBalance() {
        XCTContext.runActivity(named: "getTransactionsForClaimableBalance") { activity in
            let expectation = XCTestExpectation(description: "Get transactions for claimabe balance")
                let claimableBalanceId = self.claimableBalanceId!
            sdk.transactions.getTransactions(forClaimableBalance: claimableBalanceId) { (response) -> (Void) in
                switch response {
                case .success(let transactions):
                    if let _ = transactions.records.first {
                        XCTAssert(true)
                    } else {
                        XCTFail()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionsForClaimableBalance", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getTransactionsForLedger() {
        XCTContext.runActivity(named: "getTransactionsForLedger") { activity in
            let expectation = XCTestExpectation(description: "Get transactions for ledger")
            
            sdk.transactions.getTransactions(forLedger: "19") { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionsForLedger", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getTransactionDetails() {
        XCTContext.runActivity(named: "getTransactionDetails") { activity in
            let expectation = XCTestExpectation(description: "Get transaction details")
            
            sdk.transactions.getTransactionDetails(transactionHash: self.transactionId!) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionDetails", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func checkTransactionSigning() {
        XCTContext.runActivity(named: "checkTransactionSigning") { activity in
            let keyPair = self.testKeyPair
            
            let expectation = XCTestExpectation(description: "Transaction successfully signed.")
            sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let data):
                    let operationBody = OperationBodyXDR.inflation
                    let mux = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
                    let operation = OperationXDR(sourceAccount: mux, body: operationBody)
                    let tb = TimeBoundsXDR(minTime: 100, maxTime: 4000101011)
                    let cond = PreconditionsXDR.time(tb)
                    var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, cond: cond, memo: .none, operations: [operation])
                    try! transaction.sign(keyPair: keyPair, network: .testnet)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionSigning", horizonRequestError:error)
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func checkTransactionV0Signing() {
        XCTContext.runActivity(named: "checkTransactionV0Signing") { activity in
            let keyPair = self.testKeyPair
            
            let expectation = XCTestExpectation(description: "Transaction successfully signed.")
            sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let data):
                    let operationBody = OperationBodyXDR.inflation
                    let mux = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
                    let operation = OperationXDR(sourceAccount: mux, body: operationBody)
                    var transaction = TransactionV0XDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation])
                    try! transaction.sign(keyPair: keyPair, network: .testnet)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionV0Signing", horizonRequestError:error)
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func checkTransactionMultiSigning() {
        XCTContext.runActivity(named: "checkTransactionV0Signing") { activity in
            let expectation = XCTestExpectation(description: "Transaction Multisignature")
            let source = self.testKeyPair
            let destination = self.destinationKeyPair
            streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: source.accountId, cursor: "now"))
            streamItem?.onReceive { response in
                switch response {
                case .open:
                    break
                case .response(_, let response):
                    if response.signatures.count == 2 {
                        expectation.fulfill()
                        self.streamItem?.closeStream()
                        self.streamItem = nil
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: source.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let paymentOperation = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId,
                                                            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                            amount: 1.5)
                    
                    let paymentOperation2 = try! PaymentOperation(sourceAccountId: destination.accountId,
                                                             destinationAccountId: source.accountId,
                                                            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                            amount: 3.5)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [paymentOperation, paymentOperation2],
                                                      memo: Memo.none)
                    
                    try! transaction.sign(keyPair: source, network: .testnet)
                    try! transaction.sign(keyPair: destination, network: .testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        case .destinationRequiresMemo(let destinationAccountId):
                            print("checkTransactionMultiSigning: Destination requires memo \(destinationAccountId)")
                            XCTFail()
                            expectation.fulfill()
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionMultiSigning", horizonRequestError:error)
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionMultiSigning", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func checkTransactionEnvelopePost() {
        XCTContext.runActivity(named: "checkTransactionEnvelopePost") { activity in
            let keyPair = testKeyPair
            
            let expectation = XCTestExpectation(description: "Transaction from envelope successfully sent.")
            sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let data):
                    let operationBody0 = OperationBodyXDR.manageData(ManageDataOperationXDR(dataName: "kop", dataValue: "api.stellar.org".data(using: .utf8)))
                    let mux = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
                    let operation0 = OperationXDR(sourceAccount: mux, body: operationBody0)
                    let operationBody = OperationBodyXDR.bumpSequence(BumpSequenceOperationXDR(bumpTo: data.sequenceNumber + 10))
                    let operation = OperationXDR(sourceAccount: mux, body: operationBody)
                    var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, cond: PreconditionsXDR.none, memo: .none, operations: [operation0, operation], maxOperationFee: 190)
                    
                    try! transaction.sign(keyPair: keyPair, network: .testnet)
                    let xdrEnvelope = try! transaction.encodedEnvelope()
                    self.sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            expectation.fulfill()
                        case .destinationRequiresMemo(let destinationAccountId):
                            print("checkTransactionEnvelopePost: Destination requires memo \(destinationAccountId)")
                            XCTFail()
                            expectation.fulfill()
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionEnvelopePost", horizonRequestError:error)
                            XCTFail()
                        }
                    })
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionEnvelopePost", horizonRequestError:error)
                    XCTFail()
                }
            }
            wait(for: [expectation], timeout: 25.0)
        }
    }
    
    func checkTransactionV1Sign() {
        XCTContext.runActivity(named: "checkTransactionV1Sign") { activity in
            let keyPair = try! KeyPair(secretSeed: "SB2VUAO2O2GLVUQOY46ZDAF3SGWXOKTY27FYWGZCSV26S24VZ6TUKHGE")
            // GDKLKYIQHG7S54YKQ6SMF5JZLYJFO4JZCI4WENCJMBCW3AEYSDSGTIWS
            // transaction envelope v1
            let xdr = "AAAAAgAAAADUtWEQOb8u8wqHpML1OV4SV3E5EjliNElgRW2AmJDkaQAAJxAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAA1LVhEDm/LvMKh6TC9TleEldxORI5YjRJYEVtgJiQ5GkAAAABAAAAANS1YRA5vy7zCoekwvU5XhJXcTkSOWI0SWBFbYCYkORpAAAAAAAAAAAAAAABAAAAAAAAAAA="

            let envelopeXDR = try! TransactionEnvelopeXDR(xdr: xdr)
            let txHash = try! [UInt8](envelopeXDR.txHash(network: .public))
            envelopeXDR.appendSignature(signature: keyPair.signDecorated(txHash))

            let userSignature = envelopeXDR.txSignatures.first!.signature.base64EncodedString()
            let validUserSignature = "1iw8QognbB+8DmvUTAk0SQSxjpsYqa2pnP9/A7qJwyJ5IPVG+wl4w6M5mHel5CjzsnWKwurE/LCY26Jmz5KiBw=="
            
            XCTAssertEqual(validUserSignature, userSignature)
        }
    }

    func checkTransactionV1Sign2() {
        XCTContext.runActivity(named: "checkTransactionV1Sign2") { activity in
            let keyPair = try! KeyPair(secretSeed: "SB2VUAO2O2GLVUQOY46ZDAF3SGWXOKTY27FYWGZCSV26S24VZ6TUKHGE")
            // transaction envelope v1
            let xdr = "AAAAAgAAAADUtWEQOb8u8wqHpML1OV4SV3E5EjliNElgRW2AmJDkaQAAJxAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAA1LVhEDm/LvMKh6TC9TleEldxORI5YjRJYEVtgJiQ5GkAAAABAAAAANS1YRA5vy7zCoekwvU5XhJXcTkSOWI0SWBFbYCYkORpAAAAAAAAAAAAAAABAAAAAAAAAAA="

            let transaction = try! Transaction(envelopeXdr: xdr)
            try! transaction.sign(keyPair: keyPair, network: .public)
            let envelopeXDR = try! TransactionEnvelopeXDR(xdr: transaction.encodedEnvelope())

            let userSignature = envelopeXDR.txSignatures.first!.signature.base64EncodedString()
            let validUserSignature = "1iw8QognbB+8DmvUTAk0SQSxjpsYqa2pnP9/A7qJwyJ5IPVG+wl4w6M5mHel5CjzsnWKwurE/LCY26Jmz5KiBw=="
            
            XCTAssertEqual(validUserSignature, userSignature)
        }
    }
    
    func checkTransactionSponsoringXDR()  {
        XCTContext.runActivity(named: "checkTransactionSponsoringXDR") { activity in
            let xdr = "AAAAAgAAAAA0jCzxfXQz6m2qbnLP+65jGoAlFe4iq6PDscyjMQFpaQAtxsAB6r3KAAAB3AAAAAEAAAAAAAAAAAAAAABgJQcCAAAAAAAAAAMAAAABAAAAAB4iR3Mb6J8v89M2SdB9HqBrRdxzyIS66zoSEI3YmXjBAAAAEAAAAACHq6ZMhPkTrMxCxpHMRzP0+x9RiQrWytu63h+8FZ9paAAAAAEAAAAAh6umTIT5E6zMQsaRzEcz9PsfUYkK1srbut4fvBWfaWgAAAAGAAAAAVVTREMAAAAAO5kROA7+mIugqJAOsc/kTzZvfb6Ua+0HckD39iTfFcV//////////wAAAAEAAAAAh6umTIT5E6zMQsaRzEcz9PsfUYkK1srbut4fvBWfaWgAAAARAAAAAAAAAAHYmXjBAAAAQFiyng7KylEQ2YEAL+mmEmPx4V0WipbQy6kuc/RDVjGVsjW45L1FQbGU7eja7gAIsaU0m83xW1eGQn/m1A5RTww="

            let transaction = try! Transaction(envelopeXdr: xdr)
            let envelopeXDR = try! transaction.encodedEnvelope()
            
            XCTAssertEqual(xdr, envelopeXDR)
        }
    }
    
    func checkTransactionSponsoringXDR2() {
        XCTContext.runActivity(named: "checkTransactionSponsoringXDR2") { activity in
            let xdr = "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"

            let transaction = try! Transaction(envelopeXdr: xdr)
            let envelopeXDR = try! transaction.encodedEnvelope()
            
            XCTAssertEqual(xdr, envelopeXDR)
        }
    }
    
    func checkTransactionSponsoringXDR3() {
        XCTContext.runActivity(named: "checkTransactionSponsoringXDR3") { activity in
            let xdr = "AAAAAgAAAACihyLOUMbcixRy/6eWFjofjp/WvOulrLUSTdifhvbfBwAAASwACEtuAAAAFwAAAAAAAAAAAAAAAwAAAAEAAAAAoocizlDG3IsUcv+nlhY6H46f1rzrpay1Ek3Yn4b23wcAAAAQAAAAAPMed6fp3yGhZYD8Eof0kFShAqGI7iL4T3+Hn/FDiIvQAAAAAAAAAAYAAAABU0tZAAAAAAB+byWqW6fUDTqmlHOBjzkyAptP3jcizGYO/CWH/S5RKQAAABdIdugAAAAAAAAAABEAAAAAAAAAAob23wcAAABAO34o58GqRbKPAUI4fGanjzp10b+H76SNOdWQhBsU9F/LdnapUQmfhJGgd9Y7IqEOrNL9Ht+8T75Q1xfjaJXCAUOIi9AAAABA7pSUP0CRTs+uJStx2W/LvsXBM0AK8pKbeqHLVHLn+cNVWjfxO2whYvqOUewvLcFrZhcqQqfkw6QVP91DfmRFBQ=="

            let transaction = try! Transaction(envelopeXdr: xdr)
            let envelopeXDR = try! transaction.encodedEnvelope()
            
            XCTAssertEqual(xdr, envelopeXDR)
        }
    }
    
    func checkTransactionV0SignWithTwoOperations() {
        XCTContext.runActivity(named: "checkTransactionV0SignWithTwoOperations") { activity in
            let keyPair = try! KeyPair(secretSeed: "SB2VUAO2O2GLVUQOY46ZDAF3SGWXOKTY27FYWGZCSV26S24VZ6TUKHGE")
            // transaction envelope v0 with two payment operations
            let xdr = "AAAAANS1YRA5vy7zCoekwvU5XhJXcTkSOWI0SWBFbYCYkORpAAAAyAAAAAAAAAABAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAABAAAAAE8LpHirFqhklgFS3bqZmOEvg53t/uQ8CFrefQom/uZVAAAAAAAAAAAF9eEAAAAAAAAAAAEAAAAATwukeKsWqGSWAVLdupmY4S+Dne3+5DwIWt59Cib+5lUAAAAAAAAAAAL68IAAAAAAAAAAAA=="
            
            var envelopeXDR = try! TransactionEnvelopeXDR(xdr: xdr)
            switch envelopeXDR {
            case .v0(let txEnvV0):
                // if its a v0 transaction envelope, convert it to a v1 transaction envelope
                let tV0Xdr = txEnvV0.tx
                let pk = try! PublicKey(tV0Xdr.sourceAccountEd25519)
                var cond = PreconditionsXDR.none
                if let tb = tV0Xdr.timeBounds {
                    cond = PreconditionsXDR.time(tb)
                }
                let transactionXdr = TransactionXDR(sourceAccount: pk, seqNum: tV0Xdr.seqNum, cond: cond, memo: tV0Xdr.memo, operations: tV0Xdr.operations, maxOperationFee: tV0Xdr.fee / UInt32(tV0Xdr.operations.count) )
                let txV1E = TransactionV1EnvelopeXDR(tx: transactionXdr, signatures: envelopeXDR.txSignatures)
                envelopeXDR = TransactionEnvelopeXDR.v1(txV1E)
            default:
                break
            }
            let txHash = try! [UInt8](envelopeXDR.txHash(network: .public))
            envelopeXDR.appendSignature(signature: keyPair.signDecorated(txHash))

            let userSignature = envelopeXDR.txSignatures.first!.signature.base64EncodedString()
            let validUserSignature = "/x+ipnunmfDID9kX09bmnZOLSG/3Cwld0zgHzpgN6vNAQ4ebrcnALv8hwvVlS5IFY6wKRacWBM0gA9eSd68/CQ=="

            XCTAssertEqual(validUserSignature, userSignature)
        }
    }
    
    func coSignTransactionEnvelope() {
        XCTContext.runActivity(named: "testCoSignTransactionEnvelope") { activity in
            let keyPair = try! KeyPair(secretSeed: "SA33GXHR62NBMBH5OZK5JHXR3X7KAANKMVXPIP6VQQO6N5HGKFB66HWR")
            
            let xdr = "AAAAALR6uVN4RmrfW6K8wdmNznPg6i3Q0dFJTu+fC/RccUZQAAABkAAN4SkAAAABAAAAAAAAAAAAAAAEAAAAAAAAAAYAAAABRFNRAAAAAABHB84JGCc/5+R3BOlxDMXPzkRrWjzfWQvocgCZlHVYu3//////////AAAAAAAAAAYAAAABVVNEAAAAAAABxhW5NR6QVXaxvG7fKS5GdaoNNuHlB1wIB+Sdra3GIn//////////AAAAAAAAAAUAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAEAAAACAAAAAQAAAAIAAAABAAAAAgAAAAAAAAABAAAAADcAko3Ije9aGOP0RkukFkQVJtdyFphVAsp/A/iOD8+7AAAAAQAAAAEAAAAAb0vB44BU2bPolZjPxTq49MypRuzHJ9s9aYwS1QoGvoAAAAABAAAAALR6uVN4RmrfW6K8wdmNznPg6i3Q0dFJTu+fC/RccUZQAAAAAURTUQAAAAAARwfOCRgnP+fkdwTpcQzFz85Ea1o831kL6HIAmZR1WLsAAAAAO5rKAAAAAAAAAAABCga+gAAAAEAceq3kjgzL9Hd0ad60WltzntByI1fdBUXp8nmR8V1d5QlEoDcrOHMo73SvpqvW4yfmksM4P4ixS5Pi4VUeboQL"
            
            let transaction = try! Transaction(envelopeXdr: xdr)
            
            try! transaction.sign(keyPair: keyPair, network: .testnet)
            
            let xdrEnvelope = try! transaction.encodedEnvelope()
            XCTAssertEqual("AAAAAgAAAAC0erlTeEZq31uivMHZjc5z4Oot0NHRSU7vnwv0XHFGUAAAAZAADeEpAAAAAQAAAAAAAAAAAAAABAAAAAAAAAAGAAAAAURTUQAAAAAARwfOCRgnP+fkdwTpcQzFz85Ea1o831kL6HIAmZR1WLt//////////wAAAAAAAAAGAAAAAVVTRAAAAAAAAcYVuTUekFV2sbxu3ykuRnWqDTbh5QdcCAfkna2txiJ//////////wAAAAAAAAAFAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAABAAAAAgAAAAEAAAACAAAAAQAAAAIAAAAAAAAAAQAAAAA3AJKNyI3vWhjj9EZLpBZEFSbXchaYVQLKfwP4jg/PuwAAAAEAAAABAAAAAG9LweOAVNmz6JWYz8U6uPTMqUbsxyfbPWmMEtUKBr6AAAAAAQAAAAC0erlTeEZq31uivMHZjc5z4Oot0NHRSU7vnwv0XHFGUAAAAAFEU1EAAAAAAEcHzgkYJz/n5HcE6XEMxc/ORGtaPN9ZC+hyAJmUdVi7AAAAADuaygAAAAAAAAAAAgoGvoAAAABAHHqt5I4My/R3dGnetFpbc57QciNX3QVF6fJ5kfFdXeUJRKA3KzhzKO90r6ar1uMn5pLDOD+IsUuT4uFVHm6EC1xxRlAAAABABUdvOuwn2dZZBCXRTiofGH6nBwCV82+n3cX3nD29QkW48ls3c+GTryfvUun8XgPTBWnKcpGIUiMuQ9NL4ntyCA==", xdrEnvelope)
            XCTAssertTrue(transaction.fee == 400)
        }
    }
    
    func coSignTransactionEnvelope2() {
        XCTContext.runActivity(named: "coSignTransactionEnvelope2") { activity in
            let seed = "SB2VUAO2O2GLVUQOY46ZDAF3SGWXOKTY27FYWGZCSV26S24VZ6TUKHGE"
            let keyPair = try! KeyPair(secretSeed: seed)
            
            let transaction = "AAAAAgAAAADUtWEQOb8u8wqHpML1OV4SV3E5EjliNElgRW2AmJDkaQAAJxAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAA1LVhEDm/LvMKh6TC9TleEldxORI5YjRJYEVtgJiQ5GkAAAABAAAAANS1YRA5vy7zCoekwvU5XhJXcTkSOWI0SWBFbYCYkORpAAAAAAAAAAAAAAABAAAAAAAAAAA="
            
            let transactionEnvelope = try! TransactionEnvelopeXDR(xdr: transaction)
            let txHash = try! [UInt8](transactionEnvelope.txHash(network: .public))
            transactionEnvelope.appendSignature(signature: keyPair.signDecorated(txHash))

            var encodedEnvelope = try! XDREncoder.encode(transactionEnvelope)
            
            let result = Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    
            XCTAssertEqual("AAAAAgAAAADUtWEQOb8u8wqHpML1OV4SV3E5EjliNElgRW2AmJDkaQAAJxAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAA1LVhEDm/LvMKh6TC9TleEldxORI5YjRJYEVtgJiQ5GkAAAABAAAAANS1YRA5vy7zCoekwvU5XhJXcTkSOWI0SWBFbYCYkORpAAAAAAAAAAAAAAABAAAAAAAAAAGYkORpAAAAQNYsPEKIJ2wfvA5r1EwJNEkEsY6bGKmtqZz/fwO6icMieSD1RvsJeMOjOZh3peQo87J1isLqxPywmNuiZs+Sogc=", result)
        }
    }

    func coSignTransactionEnvelope3() {
        XCTContext.runActivity(named: "coSignTransactionEnvelope3") { activity in
            let keyPair = try! KeyPair(secretSeed: "SA6QS22REFMONMF3O7MMUCUVCXQIS6EHC63VY4FIEIF4KGET4BR6UQAI")
            
            let xdr = "AAAAAAZHmUf2xSOqrDLf0wK1KnpKn9gLAyk3Djc7KHL5e2YuAAAAAf//////////AAAAAQAAAABe1CIaAAAAAF7UI0YAAAAAAAAAAQAAAAEAAAAA305u1W+C8ChCMyOCQa/OjrYFXs3VQvneddHTq+p6CqcAAAAKAAAAClZhdWx0IGF1dGgAAAAAAAEAAABANGQ5ZjQ5OWNmMWE5ZTJiM2RkZWUyMWNjZGNmZjQ3MTIzZjgwM2UzNjdmZDYxZmY5Mjc1NGZmMTJhMWNmOWE0ZAAAAAAAAAAB+XtmLgAAAEAidHX75sVl7ZdXrkOL+EX7qskl/9xVMKkXC4lr1zjQQbNZyeO9Sa49BC1ln54k9FFvabWG0RAf7IChg4E7QN8C"
            
            let transaction = try! Transaction(envelopeXdr: xdr)
            try! transaction.sign(keyPair: keyPair, network: .public)
            let xdrEnvelope = try! transaction.encodedEnvelope()
            XCTAssertEqual("AAAAAgAAAAAGR5lH9sUjqqwy39MCtSp6Sp/YCwMpNw43Oyhy+XtmLgAAAAH//////////wAAAAEAAAAAXtQiGgAAAABe1CNGAAAAAAAAAAEAAAABAAAAAN9ObtVvgvAoQjMjgkGvzo62BV7N1UL53nXR06vqegqnAAAACgAAAApWYXVsdCBhdXRoAAAAAAABAAAAQDRkOWY0OTljZjFhOWUyYjNkZGVlMjFjY2RjZmY0NzEyM2Y4MDNlMzY3ZmQ2MWZmOTI3NTRmZjEyYTFjZjlhNGQAAAAAAAAAAvl7Zi4AAABAInR1++bFZe2XV65Di/hF+6rJJf/cVTCpFwuJa9c40EGzWcnjvUmuPQQtZZ+eJPRRb2m1htEQH+yAoYOBO0DfAup6CqcAAABATrYAEx9qMRnym42XNlZWJlshMCTJ1k1Adzc865ydc0OVWxymmAP+2MJcrkmgfgFZn5wcYYxzaWrQ4gCqYrlCDw==", xdrEnvelope)
        }
    }
    
    func feeBumpTransactionEnvelopePost() {
        XCTContext.runActivity(named: "feeBumpTransactionEnvelopePost") { activity in
            let expectation = XCTestExpectation(description: "FeeBumpTransaction successfully sent.")
            let sourceAccountKeyPair = testKeyPair
            let payerKeyPair = self.payerKeyPair
            
            
            
            streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: payerKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { response in
                switch response {
                case .open:
                    break
                case .response(_, let response):
                    
                    if let _ = response.feeBumpTransactionResponse, let _ = response.innerTransactionResponse {
                        XCTAssert(true)
                    } else {
                        XCTFail()
                    }
                    expectation.fulfill()
                    self.streamItem?.closeStream()
                    self.streamItem = nil
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"feeBumpTransactionEnvelopePost - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                                    destinationAccountId: self.destinationKeyPair.accountId,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 1.5)
                        let innerTx = try Transaction(sourceAccount: accountResponse,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none)
                        try innerTx.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        self.sdk.accounts.getAccountDetails(accountId: payerKeyPair.accountId) { (response) -> (Void) in
                            switch response {
                            case .success(let accountResponse):
                                let mux = try! MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 929299292)
                                let fb = try! FeeBumpTransaction(sourceAccount: mux, fee: 200, innerTransaction: innerTx)
                                
                                try! fb.sign(keyPair: payerKeyPair, network: Network.testnet)
                                
                                try! self.sdk.transactions.submitFeeBumpTransaction(transaction: fb) { (response) -> (Void) in
                                    switch response {
                                    case .success(let response):
                                        self.feeBumpTransactionId = response.transactionHash
                                        XCTAssert(true)
                                    case .destinationRequiresMemo(let destinationAccountId):
                                        print("feeBumpTransactionEnvelopePost: Destination requires memo \(destinationAccountId)")
                                        XCTFail()
                                        expectation.fulfill()
                                    case .failure(let error):
                                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"FBT Test", horizonRequestError:error)
                                        XCTFail()
                                        expectation.fulfill()
                                    }
                                }
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"feeBumpTransactionEnvelopePost", horizonRequestError:error)
                                XCTFail()
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTFail()
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"feeBumpTransactionEnvelopePost", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 25.0)
        }
    }
    
    func getFeeBumpTransactionDetails() {
        XCTContext.runActivity(named: "getFeeBumpTransactionDetails") { activity in
            let expectation = XCTestExpectation(description: "Get transaction details")
            
            sdk.transactions.getTransactionDetails(transactionHash: self.feeBumpTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    if let _ = response.feeBumpTransactionResponse, let _ = response.innerTransactionResponse {
                        XCTAssert(true)
                    } else {
                        XCTFail()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getFeeBumpTransactionDetails", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    /*
    func getTransactionDetailsP19() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        
        sdk.transactions.getTransactionDetails(transactionHash: "855424532154d21ad9df42e4fb642f2a855569314aebb41da7f6d129cd9997f4") { (response) -> (Void) in
            switch response {
            case .success(let tx):
                XCTAssert(tx.preconditions != nil)
                XCTAssert(tx.preconditions?.timeBounds?.minTime == "1652110741")
                XCTAssert(tx.preconditions?.timeBounds?.maxTime == "1752110741")
                XCTAssert(tx.preconditions?.ledgerBounds?.minLedger == 892052)
                XCTAssert(tx.preconditions?.ledgerBounds?.maxLedger == 1892052)
                XCTAssert(tx.preconditions?.minAccountSequence == "3266266794033160")
                XCTAssert(tx.preconditions?.minAccountSequenceAge == "1")
                XCTAssert(tx.preconditions?.minAccountSequenceLedgerGap == 1)
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GTD Test", horizonRequestError: error)
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }*/
}
