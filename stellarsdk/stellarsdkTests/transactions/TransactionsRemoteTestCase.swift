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
    var ledgerId:String? = nil
    var feeBumpTransactionId:String? = nil
    var feeBumpTransactionV0Id:String? = nil
    let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
    let network = Network.testnet
    
    override func setUp() async throws {
        try await super.setUp()
        
        let testAccountId = testKeyPair.accountId
        
        let createAccountOp1 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: claimantKeyPair.accountId, startBalance: 100)
        let createAccountOp2 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: destinationKeyPair.accountId, startBalance: 100)
        let createAccountOp3 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: payerKeyPair.accountId, startBalance: 100)
        
        let responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createAccountOp1, createAccountOp2, createAccountOp3],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
                self.transactionId = details.transactionHash
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func testAll() async {
        await getTransactions()
        await getTransactionsForAccount()
        await createClaimableBalance()
        await getTransactionsForClaimableBalance()
        await getTransactionDetails()
        await getTransactionsForLedger()
        checkTransactionSigning()
        checkTransactionV0Signing()
        await checkTransactionMultiSigning()
        await checkTransactionEnvelopePost()
        checkTransactionV1Sign()
        checkTransactionV1Sign2()
        checkTransactionSponsoringXDR()
        checkTransactionSponsoringXDR2()
        checkTransactionSponsoringXDR3()
        checkTransactionV0SignWithTwoOperations()
        coSignTransactionEnvelope()
        coSignTransactionEnvelope2()
        coSignTransactionEnvelope3()
        await feeBumpTransactionEnvelopePost()
        await getFeeBumpTransactionDetails()
    }
    
    func getTransactions() async {
        
        let transactionsResponseEnum = await sdk.transactions.getTransactions(limit: 15);
        switch transactionsResponseEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    XCTAssertTrue(page.records.count > 0)
                    XCTAssertTrue(firstPage.records.count > 0)
                    let transaction1 = firstPage.records.first!
                    let transaction2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(transaction1.id == transaction2.id)
                    XCTAssertTrue(transaction1.transactionHash == transaction2.transactionHash)
                    XCTAssertTrue(transaction1.ledger == transaction2.ledger)
                    XCTAssertTrue(transaction1.createdAt == transaction2.createdAt)
                    XCTAssertTrue(transaction1.sourceAccount == transaction2.sourceAccount)
                    XCTAssertTrue(transaction1.sourceAccountSequence == transaction2.sourceAccountSequence)
                    XCTAssertTrue(transaction1.maxFee == transaction2.maxFee)
                    XCTAssertTrue(transaction1.feeAccount == transaction2.feeAccount)
                    XCTAssertTrue(transaction1.feeCharged == transaction2.feeCharged)
                    XCTAssertTrue(transaction1.operationCount == transaction2.operationCount)
                    XCTAssertTrue(transaction1.memoType == transaction2.memoType)
                    XCTAssertTrue(transaction1.memo == transaction2.memo)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
                    XCTFail("failed to load prev page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
                XCTFail("failed to load next page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
            XCTFail("failed to load transactions")
        }
    }
    
    func getTransactionsForAccount() async {
        let transactionsResponseEnum = await sdk.transactions.getTransactions(forAccount: testKeyPair.accountId ,order: Order.descending)
        switch transactionsResponseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionsForAccount()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func createClaimableBalance() async {
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
        var accountDetails:AccountResponse? = nil
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let details):
            accountDetails = details
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance()", horizonRequestError: error)
            XCTFail("could not load account details of source account \(sourceAccountKeyPair.accountId)")
            expectation.fulfill()
        }
        
        let claimant = Claimant(destination:claimantAccountId)
        let claimants = [ claimant]
        let createClaimableBalance = CreateClaimableBalanceOperation(asset: self.assetNative!, amount: 1.00, claimants: claimants)
        
        let transaction = try! Transaction(sourceAccount: accountDetails!,
                                          operations: [createClaimableBalance],
                                          memo: Memo.none)
        try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
        
        
        let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitTxResultEnum {
        case .success(let submitTransactionResponse):
            XCTAssertTrue(submitTransactionResponse.operationCount > 0)
            switch submitTransactionResponse.transactionResult.resultBody {
            case .success(let array):
                for opResult in array {
                    switch opResult {
                    case .createClaimableBalance(_, let createClaimableBalanceResultXDR):
                        switch createClaimableBalanceResultXDR {
                        case .success(_, let claimableBalanceIDXDR):
                            switch claimableBalanceIDXDR {
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
            default:
                break
            }
            XCTAssertNotNil(self.claimableBalanceId)
        case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
            XCTFail("destination account \(destinationAccountId) requires memo")
        case .failure(error: let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance()", horizonRequestError: error)
            XCTFail("submit transaction error")
        }
    
        await fulfillment(of: [expectation], timeout: 15.0)
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
    
    func getTransactionsForClaimableBalance() async {
        let claimableBalanceId = self.claimableBalanceId!
        let transactionsResponseEnum = await sdk.transactions.getTransactions(forClaimableBalance: claimableBalanceId)
        switch transactionsResponseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionsForClaimableBalance()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getTransactionDetails() async {
        let txDetailsEnum = await sdk.transactions.getTransactionDetails(transactionHash: self.transactionId!)
        switch txDetailsEnum {
        case .success(let details):
            self.ledgerId = "\(details.ledger)"
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionDetails", horizonRequestError: error)
            XCTFail("could not load tx details for tx \(self.transactionId!)")
        }
        XCTAssertNotNil(self.ledgerId)
    }
    
    func getTransactionsForLedger() async {
        
        let ledgerSeq = self.ledgerId!
        let transactionsResponseEnum = await sdk.transactions.getTransactions(forLedger: ledgerSeq)
        switch transactionsResponseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionsForLedger()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func checkTransactionSigning() {
        let keyPair = self.testKeyPair
        
        let operationBody = OperationBodyXDR.inflation
        let mux = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
        let operation = OperationXDR(sourceAccount: mux, body: operationBody)
        let tb = TimeBoundsXDR(minTime: 100, maxTime: 4000101011)
        let cond = PreconditionsXDR.time(tb)
        var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: 12, cond: cond, memo: .none, operations: [operation])
        XCTAssertNoThrow(try transaction.sign(keyPair: keyPair, network: Network.testnet))
    }
    
    func checkTransactionV0Signing() {
        let keyPair = self.testKeyPair
        let operationBody = OperationBodyXDR.inflation
        let mux = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
        let operation = OperationXDR(sourceAccount: mux, body: operationBody)
        var transaction = TransactionV0XDR(sourceAccount: keyPair.publicKey, seqNum: 12, timeBounds: nil, memo: .none, operations: [operation])
        XCTAssertNoThrow(try transaction.sign(keyPair: keyPair, network: Network.testnet))
    }
    
    func checkTransactionMultiSigning() async {
        let expectation = XCTestExpectation(description: "Multisigned transaction submited")
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
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionMultiSigning()", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: source.accountId)
        switch accDetailsEnum {
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
            
            XCTAssertNoThrow(try transaction.sign(keyPair: source, network: .testnet))
            XCTAssertNoThrow(try transaction.sign(keyPair: destination, network: .testnet))
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionMultiSigning()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionMultiSigning()", horizonRequestError: error)
            XCTFail("could not load account details for \(source.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func checkTransactionEnvelopePost() async {
        let keyPair = testKeyPair
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch accDetailsEnum {
        case .success(let data):
            let operationBody0 = OperationBodyXDR.manageData(ManageDataOperationXDR(dataName: "kop", dataValue: "api.stellar.org".data(using: .utf8)))
            let mux = MuxedAccountXDR.ed25519(keyPair.publicKey.bytes)
            let operation0 = OperationXDR(sourceAccount: mux, body: operationBody0)
            let operationBody = OperationBodyXDR.bumpSequence(BumpSequenceOperationXDR(bumpTo: data.sequenceNumber + 10))
            let operation = OperationXDR(sourceAccount: mux, body: operationBody)
            var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, cond: PreconditionsXDR.none, memo: .none, operations: [operation0, operation], maxOperationFee: 190)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: keyPair, network: .testnet))
            let xdrEnvelope = try! transaction.encodedEnvelope()
            
            let postTxEnum = await sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope)
            switch postTxEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionEnvelopePost()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"checkTransactionEnvelopePost()", horizonRequestError: error)
            XCTFail("could not load account details for \(keyPair.accountId)")
        }
    }
    
    func checkTransactionV1Sign() {
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

    func checkTransactionV1Sign2() {
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
    
    func checkTransactionSponsoringXDR()  {
        let xdr = "AAAAAgAAAAA0jCzxfXQz6m2qbnLP+65jGoAlFe4iq6PDscyjMQFpaQAtxsAB6r3KAAAB3AAAAAEAAAAAAAAAAAAAAABgJQcCAAAAAAAAAAMAAAABAAAAAB4iR3Mb6J8v89M2SdB9HqBrRdxzyIS66zoSEI3YmXjBAAAAEAAAAACHq6ZMhPkTrMxCxpHMRzP0+x9RiQrWytu63h+8FZ9paAAAAAEAAAAAh6umTIT5E6zMQsaRzEcz9PsfUYkK1srbut4fvBWfaWgAAAAGAAAAAVVTREMAAAAAO5kROA7+mIugqJAOsc/kTzZvfb6Ua+0HckD39iTfFcV//////////wAAAAEAAAAAh6umTIT5E6zMQsaRzEcz9PsfUYkK1srbut4fvBWfaWgAAAARAAAAAAAAAAHYmXjBAAAAQFiyng7KylEQ2YEAL+mmEmPx4V0WipbQy6kuc/RDVjGVsjW45L1FQbGU7eja7gAIsaU0m83xW1eGQn/m1A5RTww="

        let transaction = try! Transaction(envelopeXdr: xdr)
        let envelopeXDR = try! transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
    
    func checkTransactionSponsoringXDR2() {
        let xdr = "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"

        let transaction = try! Transaction(envelopeXdr: xdr)
        let envelopeXDR = try! transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
    
    func checkTransactionSponsoringXDR3() {
        let xdr = "AAAAAgAAAACihyLOUMbcixRy/6eWFjofjp/WvOulrLUSTdifhvbfBwAAASwACEtuAAAAFwAAAAAAAAAAAAAAAwAAAAEAAAAAoocizlDG3IsUcv+nlhY6H46f1rzrpay1Ek3Yn4b23wcAAAAQAAAAAPMed6fp3yGhZYD8Eof0kFShAqGI7iL4T3+Hn/FDiIvQAAAAAAAAAAYAAAABU0tZAAAAAAB+byWqW6fUDTqmlHOBjzkyAptP3jcizGYO/CWH/S5RKQAAABdIdugAAAAAAAAAABEAAAAAAAAAAob23wcAAABAO34o58GqRbKPAUI4fGanjzp10b+H76SNOdWQhBsU9F/LdnapUQmfhJGgd9Y7IqEOrNL9Ht+8T75Q1xfjaJXCAUOIi9AAAABA7pSUP0CRTs+uJStx2W/LvsXBM0AK8pKbeqHLVHLn+cNVWjfxO2whYvqOUewvLcFrZhcqQqfkw6QVP91DfmRFBQ=="

        let transaction = try! Transaction(envelopeXdr: xdr)
        let envelopeXDR = try! transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
    
    func checkTransactionV0SignWithTwoOperations() {
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
    
    func coSignTransactionEnvelope() {
        let keyPair = try! KeyPair(secretSeed: "SA33GXHR62NBMBH5OZK5JHXR3X7KAANKMVXPIP6VQQO6N5HGKFB66HWR")
        
        let xdr = "AAAAALR6uVN4RmrfW6K8wdmNznPg6i3Q0dFJTu+fC/RccUZQAAABkAAN4SkAAAABAAAAAAAAAAAAAAAEAAAAAAAAAAYAAAABRFNRAAAAAABHB84JGCc/5+R3BOlxDMXPzkRrWjzfWQvocgCZlHVYu3//////////AAAAAAAAAAYAAAABVVNEAAAAAAABxhW5NR6QVXaxvG7fKS5GdaoNNuHlB1wIB+Sdra3GIn//////////AAAAAAAAAAUAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAEAAAACAAAAAQAAAAIAAAABAAAAAgAAAAAAAAABAAAAADcAko3Ije9aGOP0RkukFkQVJtdyFphVAsp/A/iOD8+7AAAAAQAAAAEAAAAAb0vB44BU2bPolZjPxTq49MypRuzHJ9s9aYwS1QoGvoAAAAABAAAAALR6uVN4RmrfW6K8wdmNznPg6i3Q0dFJTu+fC/RccUZQAAAAAURTUQAAAAAARwfOCRgnP+fkdwTpcQzFz85Ea1o831kL6HIAmZR1WLsAAAAAO5rKAAAAAAAAAAABCga+gAAAAEAceq3kjgzL9Hd0ad60WltzntByI1fdBUXp8nmR8V1d5QlEoDcrOHMo73SvpqvW4yfmksM4P4ixS5Pi4VUeboQL"
        
        let transaction = try! Transaction(envelopeXdr: xdr)
        
        try! transaction.sign(keyPair: keyPair, network: .testnet)
        
        let xdrEnvelope = try! transaction.encodedEnvelope()
        XCTAssertEqual("AAAAAgAAAAC0erlTeEZq31uivMHZjc5z4Oot0NHRSU7vnwv0XHFGUAAAAZAADeEpAAAAAQAAAAAAAAAAAAAABAAAAAAAAAAGAAAAAURTUQAAAAAARwfOCRgnP+fkdwTpcQzFz85Ea1o831kL6HIAmZR1WLt//////////wAAAAAAAAAGAAAAAVVTRAAAAAAAAcYVuTUekFV2sbxu3ykuRnWqDTbh5QdcCAfkna2txiJ//////////wAAAAAAAAAFAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAABAAAAAgAAAAEAAAACAAAAAQAAAAIAAAAAAAAAAQAAAAA3AJKNyI3vWhjj9EZLpBZEFSbXchaYVQLKfwP4jg/PuwAAAAEAAAABAAAAAG9LweOAVNmz6JWYz8U6uPTMqUbsxyfbPWmMEtUKBr6AAAAAAQAAAAC0erlTeEZq31uivMHZjc5z4Oot0NHRSU7vnwv0XHFGUAAAAAFEU1EAAAAAAEcHzgkYJz/n5HcE6XEMxc/ORGtaPN9ZC+hyAJmUdVi7AAAAADuaygAAAAAAAAAAAgoGvoAAAABAHHqt5I4My/R3dGnetFpbc57QciNX3QVF6fJ5kfFdXeUJRKA3KzhzKO90r6ar1uMn5pLDOD+IsUuT4uFVHm6EC1xxRlAAAABABUdvOuwn2dZZBCXRTiofGH6nBwCV82+n3cX3nD29QkW48ls3c+GTryfvUun8XgPTBWnKcpGIUiMuQ9NL4ntyCA==", xdrEnvelope)
        XCTAssertTrue(transaction.fee == 400)
    }
    
    func coSignTransactionEnvelope2() {
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

    func coSignTransactionEnvelope3() {
        let keyPair = try! KeyPair(secretSeed: "SA6QS22REFMONMF3O7MMUCUVCXQIS6EHC63VY4FIEIF4KGET4BR6UQAI")
        
        let xdr = "AAAAAAZHmUf2xSOqrDLf0wK1KnpKn9gLAyk3Djc7KHL5e2YuAAAAAf//////////AAAAAQAAAABe1CIaAAAAAF7UI0YAAAAAAAAAAQAAAAEAAAAA305u1W+C8ChCMyOCQa/OjrYFXs3VQvneddHTq+p6CqcAAAAKAAAAClZhdWx0IGF1dGgAAAAAAAEAAABANGQ5ZjQ5OWNmMWE5ZTJiM2RkZWUyMWNjZGNmZjQ3MTIzZjgwM2UzNjdmZDYxZmY5Mjc1NGZmMTJhMWNmOWE0ZAAAAAAAAAAB+XtmLgAAAEAidHX75sVl7ZdXrkOL+EX7qskl/9xVMKkXC4lr1zjQQbNZyeO9Sa49BC1ln54k9FFvabWG0RAf7IChg4E7QN8C"
        
        let transaction = try! Transaction(envelopeXdr: xdr)
        try! transaction.sign(keyPair: keyPair, network: .public)
        let xdrEnvelope = try! transaction.encodedEnvelope()
        XCTAssertEqual("AAAAAgAAAAAGR5lH9sUjqqwy39MCtSp6Sp/YCwMpNw43Oyhy+XtmLgAAAAH//////////wAAAAEAAAAAXtQiGgAAAABe1CNGAAAAAAAAAAEAAAABAAAAAN9ObtVvgvAoQjMjgkGvzo62BV7N1UL53nXR06vqegqnAAAACgAAAApWYXVsdCBhdXRoAAAAAAABAAAAQDRkOWY0OTljZjFhOWUyYjNkZGVlMjFjY2RjZmY0NzEyM2Y4MDNlMzY3ZmQ2MWZmOTI3NTRmZjEyYTFjZjlhNGQAAAAAAAAAAvl7Zi4AAABAInR1++bFZe2XV65Di/hF+6rJJf/cVTCpFwuJa9c40EGzWcnjvUmuPQQtZZ+eJPRRb2m1htEQH+yAoYOBO0DfAup6CqcAAABATrYAEx9qMRnym42XNlZWJlshMCTJ1k1Adzc865ydc0OVWxymmAP+2MJcrkmgfgFZn5wcYYxzaWrQ4gCqYrlCDw==", xdrEnvelope)
    }
    
    func feeBumpTransactionEnvelopePost() async {
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
        
        var sourceAccount:AccountResponse? = nil
        var accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            sourceAccount = accountResponse
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"feeBumpTransactionEnvelopePost()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        XCTAssertNotNil(sourceAccount)
        
        let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                    destinationAccountId: self.destinationKeyPair.accountId,
                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                amount: 1.5)
        let innerTx = try! Transaction(sourceAccount: sourceAccount!,
                                          operations: [paymentOperation],
                                          memo: Memo.none)
        XCTAssertNoThrow(try innerTx.sign(keyPair: sourceAccountKeyPair, network: Network.testnet))
        
        var payerAccount:AccountResponse? = nil
        accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: payerKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            payerAccount = accountResponse
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"feeBumpTransactionEnvelopePost()", horizonRequestError: error)
            XCTFail("could not load account details for \(payerKeyPair.accountId)")
        }
        
        XCTAssertNotNil(payerAccount)
        let mux = try! MuxedAccount(accountId: payerAccount!.accountId, sequenceNumber: payerAccount!.sequenceNumber, id: 929299292)
        let fb = try! FeeBumpTransaction(sourceAccount: mux, fee: 200, innerTransaction: innerTx)
        
        XCTAssertNoThrow(try fb.sign(keyPair: payerKeyPair, network: Network.testnet))
        
        let submitFBEnum = await sdk.transactions.submitFeeBumpTransaction(transaction: fb)
        switch submitFBEnum {
        case .success(let details):
            self.feeBumpTransactionId = details.transactionHash
        case .destinationRequiresMemo(let destinationAccountId):
            XCTFail("destination account \(destinationAccountId) requires memo")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"feeBumpTransactionEnvelopePost()", horizonRequestError: error)
            XCTFail("submit transaction error")
        }
        XCTAssertNotNil(self.feeBumpTransactionId)
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }
    
    func getFeeBumpTransactionDetails() async {
        
        let txDetailsEnum = await sdk.transactions.getTransactionDetails(transactionHash: self.feeBumpTransactionId!)
        switch txDetailsEnum {
        case .success(let details):
            XCTAssertNotNil(details.feeBumpTransactionResponse)
            XCTAssertNotNil(details.innerTransactionResponse)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getFeeBumpTransactionDetails()", horizonRequestError: error)
            XCTFail("could not load tx details for tx \(self.transactionId!)")
        }
        XCTAssertNotNil(self.ledgerId)
    }
}
