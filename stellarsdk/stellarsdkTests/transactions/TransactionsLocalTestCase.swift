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
            let astroAsset:ChangeTrustAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ASTRO", issuer: sourceAccountKeyPair)!
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
            
            let timeBounds = TimeBounds(minTime: 1597351082, maxTime: 1597388888);
            
            let accountMergeOperation = try AccountMergeOperation(destinationAccountId: accountBId, sourceAccountId: sourceAccountKeyPair.accountId)
            
            let manageDataOperation = ManageDataOperation(sourceAccountId: sourceAccountKeyPair.accountId, name: "Sommer", data: "Die Möbel sind heiß!".data(using: .utf8))
            
            let bumpSequenceOperation = BumpSequenceOperation(bumpTo: accountA.sequenceNumber + 10, sourceAccountId: nil)
            
            let createAccountOperation = CreateAccountOperation(sourceAccountId: sourceAccountKeyPair.accountId, destination: try KeyPair(accountId: accountBId), startBalance: 10)
            
            let operations = [paymentOperation, pathPaymentStrictReceiveOperation, pathPaymentStrictSendOperation, manageSellOfferOperation, manageBuyOfferOperation, createPassiveSellOfferOperation, changeTrustOperation, allowTrustOperation, setOptionsOperation, accountMergeOperation, manageDataOperation, bumpSequenceOperation, createAccountOperation]
        
        
            let preconditions = TransactionPreconditions(timeBounds:timeBounds)
            let transaction = try Transaction(sourceAccount: accountA,
                                              operations: operations,
                                              memo: Memo.text("Enjoy this transaction!"),
                                              preconditions:preconditions)
            
            try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            print(try! TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope()));
            
            let keyPairC = try! KeyPair.generateRandomKeyPair()
            let feeBump = try FeeBumpTransaction(sourceAccount: MuxedAccount(accountId: keyPairC.accountId), fee: 101, innerTransaction: transaction)
            try feeBump.sign(keyPair: keyPairC, network: Network.testnet)
            // print(try TxRep.toTxRep(transactionEnvelope: feeBump.encodedEnvelope()));
        } catch {
            XCTFail()
        }
    }
    
    func testTransactionToTxRepExample() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 1535756672 (Sat Sep  1 01:04:32 CEST 2018)
        tx.cond.timeBounds.maxTime: 1567292672 (Sun Sep  1 01:04:32 CEST 2019)
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
        // print(envelope)
        
        let xdr = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="
        XCTAssertEqual(xdr, envelope)

    }
    
    func testTransactionToTxRep2() {
        let xdr = "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"
        
        let txrep = try! TxRep.toTxRep(transactionEnvelope: xdr)
        // print(txrep)
        let xdr2 = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(xdr, xdr2)
    }
    
    func testTransactionToTxRepSoroban() {
        let invokeXdr = "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"
        
        var txrep = try! TxRep.toTxRep(transactionEnvelope: invokeXdr)
        //print(txrep)
        var xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(invokeXdr, xdr)

        let uploadContractXdr = "AAAAAgAAAABIX3Dc+6c1k4NV9BfTH6V5dracuPihPEgfi738DuxO1AABDGUAHd+JAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAgAAAhsAYXNtAQAAAAEPA2ACfn4BfmABfgF+YAAAAgcBAXYBZwAAAwMCAQIFAwEAEAYZA38BQYCAwAALfwBBgIDAAAt/AEGAgMAACwcxBQZtZW1vcnkCAAVoZWxsbwABAV8AAgpfX2RhdGFfZW5kAwELX19oZWFwX2Jhc2UDAgrIAQLCAQECfyOAgICAAEEgayIBJICAgIAAAkACQCAAp0H/AXEiAkEORg0AIAJBygBHDQELIAEgADcDCCABQo7o8di6AjcDAEEAIQIDQAJAIAJBEEcNAEEAIQICQANAIAJBEEYNASABQRBqIAJqIAEgAmopAwA3AwAgAkEIaiECDAALCyABQRBqrUIghkIEhEKEgICAIBCAgICAACEAIAFBIGokgICAgAAgAA8LIAFBEGogAmpCAjcDACACQQhqIQIMAAsLAAALAgALAEMOY29udHJhY3RzcGVjdjAAAAAAAAAAAAAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAnRvAAAAAAARAAAAAQAAA+oAAAARAB4RY29udHJhY3RlbnZtZXRhdjAAAAAAAAAAFAAAAAAAbw5jb250cmFjdG1ldGF2MAAAAAAAAAAFcnN2ZXIAAAAAAAAGMS43NC4xAAAAAAAAAAAACHJzc2RrdmVyAAAALzIwLjAuMCM4MjJjZTZjYzNlNDYxY2NjOTI1Mjc1YjQ3MmQ3N2I2Y2EzNWIyY2Q5AAAAAAAAAAAAAQAAAAAAAAABAAAAB8GmUFBvfCDI9NFqrnP4lPMCzQEdfvM63vVy8gs092U+AAAAAAAX8g8AAAKAAAAAAAAAAAAAAQwBAAAAAQ7sTtQAAABAxNCu+lC8Xuee36jeGsz7YXNEBvg3Eq6Wqd0ZQ6qnLv8LpxbubpDOzFo86rcpAAWzO70Wdyl3op2ZRSHzsnaRDg=="
        
        txrep = try! TxRep.toTxRep(transactionEnvelope: uploadContractXdr)
        //print(txrep)
        xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(uploadContractXdr, xdr)
        
        let createContractXdr = "AAAAAgAAAABIX3Dc+6c1k4NV9BfTH6V5dracuPihPEgfi738DuxO1AAWOa0AHd+JAAAABAAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAAAAAAAAAAAAEhfcNz7pzWTg1X0F9MfpXl2tpy4+KE8SB+LvfwO7E7Uim0WqDBGeseONDCj0peIZwJ4EOMpvMrpcR5GXffg4AkAAAAAwaZQUG98IMj00Wquc/iU8wLNAR1+8zre9XLyCzT3ZT4AAAABAAAAAAAAAAEAAAAAAAAAAAAAAABIX3Dc+6c1k4NV9BfTH6V5dracuPihPEgfi738DuxO1IptFqgwRnrHjjQwo9KXiGcCeBDjKbzK6XEeRl334OAJAAAAAMGmUFBvfCDI9NFqrnP4lPMCzQEdfvM63vVy8gs092U+AAAAAAAAAAEAAAAAAAAAAQAAAAfBplBQb3wgyPTRaq5z+JTzAs0BHX7zOt71cvILNPdlPgAAAAEAAAAGAAAAAXw9vhysdvciUg3nErv76mvhqOiPxqaxaUhacQTpSiicAAAAFAAAAAEAAlNNAAACgAAAAGgAAAAAABY5SQAAAAEO7E7UAAAAQN4uzM1B4G60lKSmytQbCS8zfwyi274rFhotmwBZN6qBb5ksBbVqC5r2q4QqxeJgxdXD5IjysZbFuUmTDbeS/QQ="
        
        txrep = try! TxRep.toTxRep(transactionEnvelope: createContractXdr)
        //print(txrep)
        xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(createContractXdr, xdr)
        
        let restoreFootprintXdr = "AAAAAgAAAAC+5AsLKJXPTGnveUAhL2cjFaOe6mneuq0bWVUbZttrKQAB1kkAHeCGAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAaAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC2XAAAAAFm22spAAAAQPvw3PtxT3tzS15GMDjNUa0i7bykd0BJbr4O43QqrujSYe8RBv3Z6pj6e5dfQST6nz2BfUKB1bzXavNUPdDpTA8="
        txrep = try! TxRep.toTxRep(transactionEnvelope: restoreFootprintXdr)
        //print(txrep)
        xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(restoreFootprintXdr, xdr)
        
        let extendFootprintXdr = "AAAAAgAAAAC+5AsLKJXPTGnveUAhL2cjFaOe6mneuq0bWVUbZttrKQAAtwUAHeCGAAAAAwAAAAAAAAAAAAAAAQAAAAAAAAAZAAAAAAAAJxAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAtqEAAAABZttrKQAAAEAeae7iCVUwUOWlG1ai0z9GfswZstfWW8x0iC+bvtqWvYvrkIFA4Hy6ZpCsvWgPcljuDN5X8oiy2WT15egFcFUB"
        txrep = try! TxRep.toTxRep(transactionEnvelope: extendFootprintXdr)
        //print(txrep)
        xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(extendFootprintXdr, xdr)
        
        let deploySacWithAssetXdr = "AAAAAgAAAABxW9E8HvJ8y/Uo60YQVQRdVxbZXkyyqJC//cKccViIQgBivo0AHeDLAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAEAAAACU09ORVNPAAAAAAAAAAAAAHFb0Twe8nzL9SjrRhBVBF1XFtleTLKokL/9wpxxWIhCAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAABgAAAAF2AfJVgDq1MvSnUdklLI+KInZbJj/1BbL2GfVMBtwTKQAAABQAAAABAAK6lgAAAAAAAAHoAAAAAABivikAAAABcViIQgAAAEBSslktJS0iD3ObWkvXUQetp459tfnQyL3acMFhdl9H7wmUCj6UWzvZmt/X5mt/wmJlxnsyHBX6TkQv4jFkIWcG"
        txrep = try! TxRep.toTxRep(transactionEnvelope: deploySacWithAssetXdr)
        //print(txrep)
        xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(deploySacWithAssetXdr, xdr)
        
        let deploySacWithSrcAccXdr = "AAAAAgAAAAAbabUDd9S4GOPKgqESpn8By1G0TregWA0BWOfVFU66bAAPsTsAHeDKAAAABgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAAAAAAAAAAAABtptQN31LgY48qCoRKmfwHLUbROt6BYDQFY59UVTrpsvNipWcbiYhu2d8eo1jDinP914WszeL5g2tae6RwdHB4AAAABAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAG2m1A3fUuBjjyoKhEqZ/ActRtE63oFgNAVjn1RVOumy82KlZxuJiG7Z3x6jWMOKc/3XhazN4vmDa1p7pHB0cHgAAAAEAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAYAAAABPTcI9wETxIwLcM+S1/4yEsjMC/JU6l/Td2jwUvEQx4kAAAAUAAAAAQABuoEAAAAAAAAASAAAAAAAD7DXAAAAARVOumwAAABAZ8jZ2vKUTeuPjyeQBkj+pGJdzWATUXoSAlzo+5BeXhZsv5WizK+2kdEX4aeJULBnF/H+6AL9YLCqMjkmhvJ5BQ=="
        
        txrep = try! TxRep.toTxRep(transactionEnvelope: deploySacWithSrcAccXdr)
        // print(txrep)
        xdr = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(deploySacWithSrcAccXdr, xdr)
        
    }
    
    func testFeeBumpTransactionToTxRep() {
        let xdr = "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"
        
        let txrep = try! TxRep.toTxRep(transactionEnvelope: xdr)
        // print(txrep)
        let xdr2 = try! TxRep.fromTxRep(txRep: txrep)
        XCTAssertEqual(xdr, xdr2)
    }
    
    func testPreconditionsTxRep1() {
        let xdr = "AAAAAgAAAQAAAAAAABODoXOW2Y6q7AdenusH1X8NBxVPFXEW+/PQFDiBQV05qf4DAAAAZAAKAJMAAAACAAAAAgAAAAEAAAAAYnk1lQAAAABobxaVAAAAAQANnJQAHN7UAAAAAQAKAJMAAAABAAAAAAAAAAEAAAABAAAAAgAAAACUkeBPpCcGYCoqeszK1YjZ1Ww1qY6fRI02d2hKG1nqvwAAAAHW9EEhELfDtkfmtBrXuEgEpTBlO8E/iQ2ZI/uNXLDV9AAAAAEAAAAEdGVzdAAAAAEAAAABAAABAAAAAAAAE4Ohc5bZjqrsB16e6wfVfw0HFU8VcRb789AUOIFBXTmp/gMAAAABAAABAAAAAAJPOttvlJHgT6QnBmAqKnrMytWI2dVsNamOn0SNNndoShtZ6r8AAAAAAAAAAADk4cAAAAAAAAAAATmp/gMAAABAvm+8CxO9sj4KEDwSS6hDxZAiUGdpIN2l+KOxTIkdI2joBFjT9B1U9YaORVDx4LTrLd4QM2taUuzXB51QtDQYDA=="
        
        let txrep = try! TxRep.toTxRep(transactionEnvelope: xdr)
        //print(txrep)
        let xdr2 = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr2)
        XCTAssertEqual(xdr, xdr2)
    }
    
    func testPreconditionsTxRep2() {
        let xdr = "AAAAAgAAAQAAAAAAABODoa9e0m5apwHpUf3/HzJOJeQ5q7+CwSWrnHXENS8XoAfmAAAAZAAJ/s4AAAACAAAAAgAAAAEAAAAAYnk1lQAAAABobxaVAAAAAQANnJQAHN7UAAAAAQAJ/s4AAAABAAAAAAAAAAEAAAABAAAAAgAAAAJulGoyRpAB8JhKT+ffEiXh8Kgd8qrEXfiG3aK69JgQlAAAAAM/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAACABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAAEAAAAEdGVzdAAAAAEAAAABAAABAAAAAAAAE4Ohr17SblqnAelR/f8fMk4l5Dmrv4LBJaucdcQ1LxegB+YAAAABAAABAAAAAAJPOttvipEw04NyfzwAhgQlf2S77YVGYbytcXKVNuM46+sMNAYAAAAAAAAAAADk4cAAAAAAAAAAARegB+YAAABAJG8wTpECV0rpq3TV9d26UL0MULmDxXKXGmKSJLiy9NCNJW3WMcrvrA6wiBsLHuCN7sIurD3o1/AKgntagup3Cw=="
        
        let _ = try! TxRep.toTxRep(transactionEnvelope: xdr)
        //print(txrep)
    }
    
    func testPreconditionsTxRep3() {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBGZGXYWXZ65XBD4Q4UTOMIDXRZ5X5OJGNC54IQBLSPI2DDB5VGFZO2V
        tx.fee: 6000
        tx.seqNum: 5628434382323746
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: GD53ZDEHFQPY25NBF6NPDYEA5IWXSS5FYMLQ3AE6AIGAO75XQK7SIVNU
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 100000000
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: 61ed4c5c
        signatures[0].signature: bd33b8de6ca4354d653329e4cfd2f012a3c155c816bca8275721bd801defb868642e2cd49330e904d2df270b4a2c95359536ba81eed9775c5982e411ac9c3909
        """

        let envelope = try? TxRep.fromTxRep(txRep:txRep);
        //print(envelope!)
        
        let xdr = "AAAAAgAAAABNk18Wvn3bhHyHKTcxA7xz2/XJM0XeIgFcno0MYe1MXAAAF3AAE/8IAAAAIgAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAPu8jIcsH411oS+a8eCA6i15S6XDFw2AngIMB3+3gr8kAAAAAAAAAAAF9eEAAAAAAAAAAAFh7UxcAAAAQL0zuN5spDVNZTMp5M/S8BKjwVXIFryoJ1chvYAd77hoZC4s1JMw6QTS3ycLSiyVNZU2uoHu2XdcWYLkEaycOQk="
        XCTAssertEqual(xdr, envelope)
    }
    
    func testCreateClaimableBalanceTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 100
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: true
        tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
        tx.operations[0].body.createClaimableBalanceOp.asset: XLM
        tx.operations[0].body.createClaimableBalanceOp.amount: 2900000000
        tx.operations[0].body.createClaimableBalanceOp.claimants.len: 6
        tx.operations[0].body.createClaimableBalanceOp.claimants[0].type: CLAIMANT_TYPE_V0
        tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GAF2EOTBIWV45XDG5O2QSIVXQ5KPI6EJIALVGI7VFOX7ENDNI6ONBYQO
        tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL
        tx.operations[0].body.createClaimableBalanceOp.claimants[1].type: CLAIMANT_TYPE_V0
        tx.operations[0].body.createClaimableBalanceOp.claimants[1].v0.destination: GCUEJ6YLQFWETNAXLIM3B3VN7CJISN6XLGXGDHQDVLWTYZODGSHRJWPS
        tx.operations[0].body.createClaimableBalanceOp.claimants[1].v0.predicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[1].v0.predicate.relBefore: 400
        tx.operations[0].body.createClaimableBalanceOp.claimants[2].type: CLAIMANT_TYPE_V0
        tx.operations[0].body.createClaimableBalanceOp.claimants[2].v0.destination: GCWV5WETMS3RD2ZZUF7S3NQPEVMCXBCODMV7MIOUY4D3KR66W7ACL4LE
        tx.operations[0].body.createClaimableBalanceOp.claimants[2].v0.predicate.type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[2].v0.predicate.absBefore: 1683723100
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].type: CLAIMANT_TYPE_V0
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.destination: GBOAHYPSVULLKLH4OMESGA5BGZTK37EYEPZVI2AHES6LANTCIUPFHUPE
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.type: CLAIM_PREDICATE_AND
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates.len: 2
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].type: CLAIM_PREDICATE_NOT
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].notPredicate._present: true
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].notPredicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].notPredicate.relBefore: 600
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[1].type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[1].absBefore: 1683723100
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].type: CLAIMANT_TYPE_V0
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.destination: GDOA4UYIQ3A74WTHQ4BA56Z7F7NU7F34WP2KOGYHV4UXP2T5RXVEYLLF
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.type: CLAIM_PREDICATE_OR
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates.len: 2
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[0].type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[0].absBefore: 1646723251
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[1].type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[1].absBefore: 1645723269
        tx.operations[0].body.createClaimableBalanceOp.claimants[5].type: CLAIMANT_TYPE_V0
        tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.destination: GBCZ2KRFMG7IGUSBTHXTJP3ULN2TK4F3EAYSVMS5X4MLOO3DT2LSISOR
        tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.type: CLAIM_PREDICATE_NOT
        tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.notPredicate._present: true
        tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.notPredicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
        tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.notPredicate.relBefore: 8000
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 98f329b240374d898cfcb0171b37f495c488db1abd0e290c0678296e6db09d773e6e73f14a51a017808584d1c4dae13189e4539f4af8b81b6cc830fc43e9d500
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAADgAAAAAAAAAArNp9AAAAAAYAAAAAAAAAAAuiOmFFq87cZuu1CSK3h1T0eIlAF1Mj9Suv8jRtR5zQAAAAAAAAAAAAAAAAqET7C4FsSbQXWhmw7q34kok311muYZ4Dqu08ZcM0jxQAAAAFAAAAAAAAAZAAAAAAAAAAAK1e2JNktxHrOaF/LbYPJVgrhE4bK/Yh1McHtUfet8AlAAAABAAAAABkW5NcAAAAAAAAAABcA+HyrRa1LPxzCSMDoTZmrfyYI/NUaAckvLA2YkUeUwAAAAEAAAACAAAAAwAAAAEAAAAFAAAAAAAAAlgAAAAEAAAAAGRbk1wAAAAAAAAAANwOUwiGwf5aZ4cCDvs/L9tPl3yz9KcbB68pd+p9jepMAAAAAgAAAAIAAAAEAAAAAGInALMAAAAEAAAAAGIXvoUAAAAAAAAAAEWdKiVhvoNSQZnvNL90W3U1cLsgMSqyXb8YtztjnpckAAAAAwAAAAEAAAAFAAAAAAAAH0AAAAAAAAAAAezRl+8AAABAmPMpskA3TYmM/LAXGzf0lcSI2xq9DikMBngpbm2wnXc+bnPxSlGgF4CFhNHE2uExieRTn0r4uBtsyDD8Q+nVAA==";

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        // print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testClaimClaimableBalanceTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 100
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE
        tx.operations[0].body.claimClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
        tx.operations[0].body.claimClaimableBalanceOp.balanceID.v0: ceab14eebbdbfe25a1830e39e311c2180846df74947ba24a386b8314ccba6622
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 9475bef299458bb105f63ac58df4201064d60f7cfd8ffec8ac8fd34198b94e279a257f9b7bae7f2e3a759268612b565043dacb689f7df7c99cd55d9d51bb0b06
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAADwAAAADOqxTuu9v+JaGDDjnjEcIYCEbfdJR7oko4a4MUzLpmIgAAAAAAAAAB7NGX7wAAAECUdb7ymUWLsQX2OsWN9CAQZNYPfP2P/sisj9NBmLlOJ5olf5t7rn8uOnWSaGErVlBD2ston333yZzVXZ1RuwsG";

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        // print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        // print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testSponsorshipTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 200
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 2
        tx.operations[0].sourceAccount._present: true
        tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
        tx.operations[0].body.beginSponsoringFutureReservesOp.sponsoredID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[1].sourceAccount._present: true
        tx.operations[1].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[1].body.type: END_SPONSORING_FUTURE_RESERVES
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 194a962d2f51ae1af1c4bfa3e8eeca7aa2b6654a84ac03de37d1738171e43f8ece2101fe6bd44cacd9f0bf10c93616cdfcf04639727a08ca84339fade990d40e
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAMgAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAEAAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAEAAAAARJW9RyahO88Zbk3lbcGLzpOAM9MN5KwMZ0rgROzRl+8AAAARAAAAAAAAAAHs0ZfvAAAAQBlKli0vUa4a8cS/o+juynqitmVKhKwD3jfRc4Fx5D+OziEB/mvUTKzZ8L8QyTYWzfzwRjlyegjKhDOfremQ1A4=";

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testRevokeSponsorshipTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 800
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 8
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: REVOKE_SPONSORSHIP
        tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
        tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: ACCOUNT
        tx.operations[0].body.revokeSponsorshipOp.ledgerKey.account.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[1].sourceAccount._present: false
        tx.operations[1].body.type: REVOKE_SPONSORSHIP
        tx.operations[1].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
        tx.operations[1].body.revokeSponsorshipOp.ledgerKey.type: TRUSTLINE
        tx.operations[1].body.revokeSponsorshipOp.ledgerKey.trustLine.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[1].body.revokeSponsorshipOp.ledgerKey.trustLine.asset: ACC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[2].sourceAccount._present: false
        tx.operations[2].body.type: REVOKE_SPONSORSHIP
        tx.operations[2].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
        tx.operations[2].body.revokeSponsorshipOp.ledgerKey.type: OFFER
        tx.operations[2].body.revokeSponsorshipOp.ledgerKey.offer.sellerID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[2].body.revokeSponsorshipOp.ledgerKey.offer.offerID: 293893
        tx.operations[3].sourceAccount._present: false
        tx.operations[3].body.type: REVOKE_SPONSORSHIP
        tx.operations[3].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
        tx.operations[3].body.revokeSponsorshipOp.ledgerKey.type: DATA
        tx.operations[3].body.revokeSponsorshipOp.ledgerKey.data.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[3].body.revokeSponsorshipOp.ledgerKey.data.dataName: "Soneso"
        tx.operations[4].sourceAccount._present: false
        tx.operations[4].body.type: REVOKE_SPONSORSHIP
        tx.operations[4].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
        tx.operations[4].body.revokeSponsorshipOp.ledgerKey.type: CLAIMABLE_BALANCE
        tx.operations[4].body.revokeSponsorshipOp.ledgerKey.claimableBalance.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
        tx.operations[4].body.revokeSponsorshipOp.ledgerKey.claimableBalance.balanceID.v0: ceab14eebbdbfe25a1830e39e311c2180846df74947ba24a386b8314ccba6622
        tx.operations[5].sourceAccount._present: true
        tx.operations[5].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[5].body.type: REVOKE_SPONSORSHIP
        tx.operations[5].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
        tx.operations[5].body.revokeSponsorshipOp.signer.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[5].body.revokeSponsorshipOp.signer.signerKey: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[6].sourceAccount._present: false
        tx.operations[6].body.type: REVOKE_SPONSORSHIP
        tx.operations[6].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
        tx.operations[6].body.revokeSponsorshipOp.signer.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[6].body.revokeSponsorshipOp.signer.signerKey: XD3J3C5TAC4FCWIKWL45L3Z6LE3KK4OZ3DN3AC3CAE4HHYIGVW4TUVTH
        tx.operations[7].sourceAccount._present: false
        tx.operations[7].body.type: REVOKE_SPONSORSHIP
        tx.operations[7].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
        tx.operations[7].body.revokeSponsorshipOp.signer.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[7].body.revokeSponsorshipOp.signer.signerKey: TD3J3C5TAC4FCWIKWL45L3Z6LE3KK4OZ3DN3AC3CAE4HHYIGVW4TVRW6
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 73c223f85c34f1399e9af3322a638a8877987724567e452179a9f2b159a96a1dd4e63cfb8c54e7803aa2f3787492f255698ea536070fc3e3ad9f87e36a0e660c
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAyAAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAEgAAAAAAAAAAAAAAANsckvAQBXW3k2y4RII0grJp/OOnH95cepXI17IxxLNzAAAAAAAAABIAAAAAAAAAAQAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAFBQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAAAAAABIAAAAAAAAAAgAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAAABHwFAAAAAAAAABIAAAAAAAAAAwAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAZTb25lc28AAAAAAAAAAAASAAAAAAAAAAQAAAAAzqsU7rvb/iWhgw454xHCGAhG33SUe6JKOGuDFMy6ZiIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAEgAAAAEAAAAA2xyS8BAFdbeTbLhEgjSCsmn846cf3lx6lcjXsjHEs3MAAAAARJW9RyahO88Zbk3lbcGLzpOAM9MN5KwMZ0rgROzRl+8AAAAAAAAAEgAAAAEAAAAA2xyS8BAFdbeTbLhEgjSCsmn846cf3lx6lcjXsjHEs3MAAAAC9p2LswC4UVkKsvnV7z5ZNqVx2djbsAtiAThz4QatuToAAAAAAAAAEgAAAAEAAAAA2xyS8BAFdbeTbLhEgjSCsmn846cf3lx6lcjXsjHEs3MAAAAB9p2LswC4UVkKsvnV7z5ZNqVx2djbsAtiAThz4QatuToAAAAAAAAAAezRl+8AAABAc8Ij+Fw08TmemvMyKmOKiHeYdyRWfkUheanysVmpah3U5jz7jFTngDqi83h0kvJVaY6lNgcPw+Otn4fjag5mDA==";

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testClawbackTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 100
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: true
        tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.type: CLAWBACK
        tx.operations[0].body.clawbackOp.asset: ACC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.clawbackOp.from: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[0].body.clawbackOp.amount: 2330000000
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 336998785b7815aac464789d04735d06d0421c5f92d1307a9d164e270fa1a214d30d3f00260146a80a3bb0318c92058c05f6de07589b1172c4b6ab630c628c04
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAEwAAAAFBQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAANsckvAQBXW3k2y4RII0grJp/OOnH95cepXI17IxxLNzAAAAAIrg+oAAAAAAAAAAAezRl+8AAABAM2mYeFt4FarEZHidBHNdBtBCHF+S0TB6nRZOJw+hohTTDT8AJgFGqAo7sDGMkgWMBfbeB1ibEXLEtqtjDGKMBA==";

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testClawbackClamableBalanceTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 100
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE
        tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
        tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.v0: f69d8bb300b851590ab2f9d5ef3e5936a571d9d8dbb00b62013873e106adb93a
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 6db5b9ff8e89c2103971550a485754286d1f782aa7fac17e2553bbaec9ab3969794d0fd5ba6d0b4575b9c75c1c464337fee1b4e5592eb77877b7a72487acb909
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAFAAAAAD2nYuzALhRWQqy+dXvPlk2pXHZ2NuwC2IBOHPhBq25OgAAAAAAAAAB7NGX7wAAAEBttbn/jonCEDlxVQpIV1QobR94Kqf6wX4lU7uuyas5aXlND9W6bQtFdbnHXBxGQzf+4bTlWS63eHe3pySHrLkJ"

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testSetTrustlineFlagsTxRep() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 200
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 2
        tx.operations[0].sourceAccount._present: true
        tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.type: SET_TRUST_LINE_FLAGS
        tx.operations[0].body.setTrustLineFlagsOp.trustor: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[0].body.setTrustLineFlagsOp.asset: ACC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.setTrustLineFlagsOp.clearFlags: 6
        tx.operations[0].body.setTrustLineFlagsOp.setFlags: 1
        tx.operations[1].sourceAccount._present: false
        tx.operations[1].body.type: SET_TRUST_LINE_FLAGS
        tx.operations[1].body.setTrustLineFlagsOp.trustor: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
        tx.operations[1].body.setTrustLineFlagsOp.asset: BCC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[1].body.setTrustLineFlagsOp.clearFlags: 5
        tx.operations[1].body.setTrustLineFlagsOp.setFlags: 2
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: 5d4569d07068fd4824c87bf531061cf962a820d9ac5d4fdda0a2728f035d154e5cc842aa8aa398bf8ba2f42577930af129c593832ab14ff02c25989eaf8fbf0b
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAMgAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAFQAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAFBQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAABgAAAAEAAAAAAAAAFQAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAFCQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAABQAAAAIAAAAAAAAAAezRl+8AAABAXUVp0HBo/UgkyHv1MQYc+WKoINmsXU/doKJyjwNdFU5cyEKqiqOYv4ui9CV3kwrxKcWTgyqxT/AsJZier4+/Cw=="
        

        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
    }
    
    func testLiquidityPool() {
        let txrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.fee: 200
        tx.seqNum: 2916609211498497
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 0
        tx.cond.timeBounds.maxTime: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 2
        tx.operations[0].sourceAccount._present: true
        tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
        tx.operations[0].body.type: LIQUIDITY_POOL_DEPOSIT
        tx.operations[0].body.liquidityPoolDepositOp.liquidityPoolID: f69d8bb300b851590ab2f9d5ef3e5936a571d9d8dbb00b62013873e106adb93a
        tx.operations[0].body.liquidityPoolDepositOp.maxAmountA: 1000000000
        tx.operations[0].body.liquidityPoolDepositOp.maxAmountB: 2000000000
        tx.operations[0].body.liquidityPoolDepositOp.minPrice.n: 20
        tx.operations[0].body.liquidityPoolDepositOp.minPrice.d: 1
        tx.operations[0].body.liquidityPoolDepositOp.maxPrice.n: 30
        tx.operations[0].body.liquidityPoolDepositOp.maxPrice.d: 1
        tx.operations[1].sourceAccount._present: false
        tx.operations[1].body.type: LIQUIDITY_POOL_WITHDRAW
        tx.operations[1].body.liquidityPoolWithdrawOp.liquidityPoolID: ceab14eebbdbfe25a1830e39e311c2180846df74947ba24a386b8314ccba6622
        tx.operations[1].body.liquidityPoolWithdrawOp.amount: 9000000000
        tx.operations[1].body.liquidityPoolWithdrawOp.minAmountA: 2000000000
        tx.operations[1].body.liquidityPoolWithdrawOp.minAmountB: 4000000000
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: ecd197ef
        signatures[0].signature: ed97d0d018a671c5a914a15346c1b38912d6695d1d152ffe976b8c9689ce2e7770b0e6cc8889c4a2423323898b087e5fbf43306ef7e63a75366befd3e2a9bd03
        """;
        
        let expected = "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAMgAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAFvadi7MAuFFZCrL51e8+WTalcdnY27ALYgE4c+EGrbk6AAAAADuaygAAAAAAdzWUAAAAABQAAAABAAAAHgAAAAEAAAAAAAAAF86rFO672/4loYMOOeMRwhgIRt90lHuiSjhrgxTMumYiAAAAAhhxGgAAAAAAdzWUAAAAAADuaygAAAAAAAAAAAHs0ZfvAAAAQO2X0NAYpnHFqRShU0bBs4kS1mldHRUv/pdrjJaJzi53cLDmzIiJxKJCMyOJiwh+X79DMG735jp1Nmvv0+KpvQM=";
        
        let xdr = try! TxRep.fromTxRep(txRep: txrep)
        //print(xdr)
        XCTAssertEqual(expected, xdr)
        let txRepRes = try! TxRep.toTxRep(transactionEnvelope: xdr);
        //print(txRepRes)
        XCTAssertEqual(txRepRes, txrep)
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
            XCTFail()
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
            XCTFail()
        }
    }
    
    func testTransactionXDRP19() {
        
        let xdrString = "AAAAAgAAAQAAAAAAABODof/acuzxAA9pILE4Qo4ywluEu8QPmzZdt9lqLwuIhryTAAAAZAALmqcAAAAMAAAAAgAAAAAAAAABAA2clAAc3tQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAQAAAQAAAAAAABODof/acuzxAA9pILE4Qo4ywluEu8QPmzZdt9lqLwuIhryTAAAAAQAAAQAAAAACTzrbb3aC2IBy/P5SR+6HUM0IKF3u4XY6AiFDhxsJI3NF3+ibAAAAAAAAAAAA5OHAAAAAAAAAAAGIhryTAAAAQAOqw3zOmA6SaTDpeLmfQUB9w0h4kjE4y4CQUDWVl8KtW1QhikTt4mYbF2ZOSSdYM6hiY/QWtpB19nNMxqy/1gU="
        do {
            let tx = try Transaction(envelopeXdr: xdrString)
            let pc = tx.preconditions
            XCTAssertTrue(pc?.ledgerBounds != nil)
            XCTAssertTrue(pc?.ledgerBounds?.minLedger == 892052)
            XCTAssertTrue(pc?.ledgerBounds?.maxLedger == 1892052)
        } catch {
            XCTFail()
        }
    }
    
    func testTransactionStringInit() {
        let xdrString = "AAAAAJ/Ax+axve53/7sXfQY0fI6jzBeHEcPl0Vsg1C2tqyRbAAAAZAAAAAAAAAAAAAAAAQAAAABb2L/OAAAAAFvYwPoAAAAAAAAAAQAAAAEAAAAAo7FW8r8Nj+SMwPPeAoL4aUkLob7QU68+9Y8CAia5k78AAAAKAAAAN0NJcDhiSHdnU2hUR042ZDE3bjg1ZlFGRVBKdmNtNFhnSWhVVFBuUUF4cUtORVd4V3JYIGF1dGgAAAAAAQAAAEDh/7kQjZbcXypISjto5NtGLuaDGrfL/F08apZQYp38JNMNQ9p/e1Fy0z23WOg/Ic+e91+hgbdTude6+1+i0V41AAAAAA=="
        do {
            let envelope = try Transaction(xdr:xdrString)
            let envelopeString = envelope.xdrEncoded
            XCTAssertTrue(xdrString == envelopeString)
        } catch {
            XCTFail()
        }
    }
    
    func testSetTimeBounds() {
        do {
            let kp = try KeyPair(secretSeed: "SCH27VUZZ6UAKB67BDNF6FA42YMBMQCBKXWGMFD5TZ6S5ZZCZFLRXKHS")
            let acc = Account(keyPair: kp, sequenceNumber: 2908908335136768)
            let op = try CreateAccountOperation(sourceAccountId: nil, destinationAccountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR", startBalance: 2000)
            let preconditions = TransactionPreconditions(timeBounds: TimeBounds(minTime: 0, maxTime: 120))
            let transaction = try Transaction(sourceAccount: acc, operations: [op], memo: nil, preconditions: preconditions)
            XCTAssertTrue(transaction.preconditions?.timeBounds?.minTime == 0)
            XCTAssertTrue(transaction.preconditions?.timeBounds?.maxTime == 120)
            try transaction.sign(keyPair: kp, network: Network.testnet)
            let envelopeString = try transaction.encodedEnvelope()
            print(envelopeString)
            let tx2 = try Transaction(envelopeXdr:envelopeString)
            XCTAssertTrue(tx2.preconditions?.timeBounds?.minTime == 0)
            XCTAssertTrue(tx2.preconditions?.timeBounds?.maxTime == 120)
        } catch {
            XCTFail()
        }
    }
    
    func testSetLedgerBounds() {
        do {
            let kp = try KeyPair(secretSeed: "SCH27VUZZ6UAKB67BDNF6FA42YMBMQCBKXWGMFD5TZ6S5ZZCZFLRXKHS")
            let acc = Account(keyPair: kp, sequenceNumber: 2908908335136768)
            let op = try CreateAccountOperation(sourceAccountId: nil, destinationAccountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR", startBalance: 2000)
            let preconditions = TransactionPreconditions(ledgerBounds: LedgerBounds(minLedger: 1, maxLedger: 2), timeBounds: TimeBounds(minTime: 0, maxTime: 0))
            let transaction = try Transaction(sourceAccount: acc, operations: [op], memo: nil, preconditions: preconditions)
            XCTAssertTrue(transaction.preconditions?.ledgerBounds?.minLedger == 1)
            XCTAssertTrue(transaction.preconditions?.ledgerBounds?.maxLedger == 2)
            try transaction.sign(keyPair: kp, network: Network.testnet)
            let envelopeString = try transaction.encodedEnvelope()
            print(envelopeString)
            let tx2 = try Transaction(envelopeXdr:envelopeString)
            XCTAssertTrue(tx2.preconditions?.ledgerBounds?.minLedger == 1)
            XCTAssertTrue(tx2.preconditions?.ledgerBounds?.maxLedger == 2)
        } catch {
            XCTFail()
        }
    }
    
    func testSetMinPreconditions() {
        do {
            let kp = try KeyPair(secretSeed: "SCH27VUZZ6UAKB67BDNF6FA42YMBMQCBKXWGMFD5TZ6S5ZZCZFLRXKHS")
            let acc = Account(keyPair: kp, sequenceNumber: 2908908335136768)
            let op = try CreateAccountOperation(sourceAccountId: nil, destinationAccountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR", startBalance: 2000)
            let preconditions = TransactionPreconditions(minSeqNumber:120, minSeqAge: 19999, minSeqLedgerGap: 199)
            let transaction = try Transaction(sourceAccount: acc, operations: [op], memo: nil, preconditions: preconditions)
            XCTAssertTrue(transaction.preconditions?.minSeqNumber == 120)
            XCTAssertTrue(transaction.preconditions?.minSeqAge == 19999)
            XCTAssertTrue(transaction.preconditions?.minSeqLedgerGap == 199)
            try transaction.sign(keyPair: kp, network: Network.testnet)
            let envelopeString = try transaction.encodedEnvelope()
            print(envelopeString)
            let tx2 = try Transaction(envelopeXdr:envelopeString)
            XCTAssertTrue(tx2.preconditions?.minSeqNumber == 120)
            XCTAssertTrue(tx2.preconditions?.minSeqAge == 19999)
            XCTAssertTrue(tx2.preconditions?.minSeqLedgerGap == 199)
        } catch {
            XCTFail()
        }
    }
    
    func testSetExtraSigners() {
        do {
            let kp = try KeyPair(secretSeed: "SCH27VUZZ6UAKB67BDNF6FA42YMBMQCBKXWGMFD5TZ6S5ZZCZFLRXKHS")
            let acc = Account(keyPair: kp, sequenceNumber: 2908908335136768)
            let op = try CreateAccountOperation(sourceAccountId: nil, destinationAccountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR", startBalance: 2000)
            let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
            let data = try Data(base16Encoded: dataStr)
            let accId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
            let signerKey = try Signer.signedPayload(accountId: accId, payload: data)
            
            let preconditions = TransactionPreconditions(extraSigners:[signerKey])
            let transaction = try Transaction(sourceAccount: acc, operations: [op], memo: nil, preconditions: preconditions)
            var sk = transaction.preconditions!.extraSigners[0]
            switch sk {
            case .signedPayload(let payload):
                XCTAssertTrue(try payload.publicKey().accountId == accId)
                XCTAssertTrue(payload.payload.base16EncodedString() == dataStr)
            default:
                XCTFail()
            }
            try transaction.sign(keyPair: kp, network: Network.testnet)
            let envelopeString = try transaction.encodedEnvelope()
            print(envelopeString)
            let tx2 = try Transaction(envelopeXdr:envelopeString)
            sk = tx2.preconditions!.extraSigners[0]
            switch sk {
            case .signedPayload(let payload):
                XCTAssertTrue(try payload.publicKey().accountId == accId)
                XCTAssertTrue(payload.payload.base16EncodedString() == dataStr)
            default:
                XCTFail()
            }
        } catch {
            XCTFail()
        }
    }
    
    func testParsingIssue140() {
        let transactionResultXdr = "AAAAAAAAAMgAAAAAAAAAAgAAAAAAAAANAAAAAAAAAAIAAAACNfCKzrfR7vcGZKmF9u4JB9rXOtH0Avwy+G1ERVFOXC8AAAABVVNEQwAAAAA7mRE4Dv6Yi6CokA6xz+RPNm99vpRr7QdyQPf2JN8VxQAAAAAABkjxAAAAAVVTRAAAAAAA6KYahh5gr2D4B3PgY0blxyy+Wdyt2jdgjVjvQlEdn9wAAAAAAAZhQgAAAAEAAAAAclv7rnXBwN/wHMcTeKMrqR8n8UWSCkRkTKjFU7OhzpoAAAAANyoO2wAAAAAAAAAAABokRQAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAAAAGSPEAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAAAAAAAAAAaJEUAAAAAAAAABQAAAAAAAAAA"
        let envelopeResultXdr = "AAAAAgAAAAAzLZ8nl00dWGwmhZ41swmc14jvBRVZNf4HKJZC7Cn7rwADDUAB6XUMAAAIeQAAAAAAAAAAAAAAAgAAAAEAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAANAAAAAVVTRAAAAAAA6KYahh5gr2D4B3PgY0blxyy+Wdyt2jdgjVjvQlEdn9wAAAAAAAZhQgAAAAAzLZ8nl00dWGwmhZ41swmc14jvBRVZNf4HKJZC7Cn7rwAAAAAAAAAAABngLwAAAAEAAAABVVNEQwAAAAA7mRE4Dv6Yi6CokA6xz+RPNm99vpRr7QdyQPf2JN8VxQAAAAEAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAJbG9ic3RyLmNvAAAAAAAAAAAAAAAAAAAC7Cn7rwAAAEBtbQWhFE9e1z+uCEm/D54NYqSkQXL3kP+pgYYFmTiDNFCm0Bj4mljcPaANvqBGc1Kj/LoRWJh582FR5MAwGcIIAY1PewAAAEA0aWjOGDvgZ3vOreMwoHuuiapX9n4i79Lr3eZPXGmbZON97F46zEkjjqXavkp3TmvjAsEiOr++7hrdrnNXzhoG"
        
        let metaResultXdr = "AAAAAgAAAAIAAAADAlvFrQAAAAAAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAAADtuLQwHpdQwAAAh4AAAAGgAAAAEAAAAAxHHGQ3BiyVBqiTQuU4oa2kBNL0HPHTolX0Mh98bg4XUAAAAAAAAAEXN0YWdpbmcubG9ic3RyLmNvAAAAChQUFAAAAAIAAAAAF9mFjahe1uzu7J4Zntu7568o3vsj4+LFcokaNQGNT3sAAAAKAAAAADU/Gj+t73CScyRkApJnA2Toxxe93xdMgpkGHC3BlONQAAAAAQAAAAEAAADpD6c/mAAAAAAAAYagAAAAAgAAAAAAAAAQAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAABAlvFrQAAAAAAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAAADtuLQwHpdQwAAAh5AAAAGgAAAAEAAAAAxHHGQ3BiyVBqiTQuU4oa2kBNL0HPHTolX0Mh98bg4XUAAAAAAAAAEXN0YWdpbmcubG9ic3RyLmNvAAAAChQUFAAAAAIAAAAAF9mFjahe1uzu7J4Zntu7568o3vsj4+LFcokaNQGNT3sAAAAKAAAAADU/Gj+t73CScyRkApJnA2Toxxe93xdMgpkGHC3BlONQAAAAAQAAAAEAAADpD6c/mAAAAAAAAYagAAAAAgAAAAAAAAAQAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAACAAAADAAAAAMCW8WtAAAAAAAAAAAzLZ8nl00dWGwmhZ41swmc14jvBRVZNf4HKJZC7Cn7rwAAAAAO24tDAel1DAAACHkAAAAaAAAAAQAAAADEccZDcGLJUGqJNC5TihraQE0vQc8dOiVfQyH3xuDhdQAAAAAAAAARc3RhZ2luZy5sb2JzdHIuY28AAAAKFBQUAAAAAgAAAAAX2YWNqF7W7O7snhme27vnryje+yPj4sVyiRo1AY1PewAAAAoAAAAANT8aP63vcJJzJGQCkmcDZOjHF73fF0yCmQYcLcGU41AAAAABAAAAAQAAAOkPpz+YAAAAAAABhqAAAAACAAAAAAAAABAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAECW8WtAAAAAAAAAAAzLZ8nl00dWGwmhZ41swmc14jvBRVZNf4HKJZC7Cn7rwAAAAAO9a+IAel1DAAACHkAAAAaAAAAAQAAAADEccZDcGLJUGqJNC5TihraQE0vQc8dOiVfQyH3xuDhdQAAAAAAAAARc3RhZ2luZy5sb2JzdHIuY28AAAAKFBQUAAAAAgAAAAAX2YWNqF7W7O7snhme27vnryje+yPj4sVyiRo1AY1PewAAAAoAAAAANT8aP63vcJJzJGQCkmcDZOjHF73fF0yCmQYcLcGU41AAAAABAAAAAQAAAOkPpz+YAAAAAAABhqAAAAACAAAAAAAAABAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAMCW8WsAAAAAQAAAAByW/uudcHA3/AcxxN4oyupHyfxRZIKRGRMqMVTs6HOmgAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAAr9Lqj1//////////wAAAAEAAAABAAAAAlnCs/4AAAACd4jHrgAAAAAAAAAAAAAAAQJbxa0AAAABAAAAAHJb+651wcDf8BzHE3ijK6kfJ/FFkgpEZEyoxVOzoc6aAAAAAVVTREMAAAAAO5kROA7+mIugqJAOsc/kTzZvfb6Ua+0HckD39iTfFcUAAAACv1HzLn//////////AAAAAQAAAAEAAAACWbxrDQAAAAJ3iMeuAAAAAAAAAAAAAAADAlvFrAAAAAAAAAAAclv7rnXBwN/wHMcTeKMrqR8n8UWSCkRkTKjFU7OhzpoAAAAK3ZTUQQID8fwAMZXdAAAADAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAApP6Ei3AAAACcF2dr0AAAAAAAAAAAAAAAECW8WtAAAAAAAAAAByW/uudcHA3/AcxxN4oyupHyfxRZIKRGRMqMVTs6HOmgAAAArdeq/8AgPx/AAxld0AAAAMAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAACk/oSLcAAAAJwVxSeAAAAAAAAAAAAAAAAwJbxawAAAACAAAAAHJb+651wcDf8BzHE3ijK6kfJ/FFkgpEZEyoxVOzoc6aAAAAADcqDtsAAAAAAAAAAVVTREMAAAAAO5kROA7+mIugqJAOsc/kTzZvfb6Ua+0HckD39iTfFcUAAAAAHc1lAAAkr1MAmJaAAAAAAAAAAAAAAAAAAAAAAQJbxa0AAAACAAAAAHJb+651wcDf8BzHE3ijK6kfJ/FFkgpEZEyoxVOzoc6aAAAAADcqDtsAAAAAAAAAAVVTREMAAAAAO5kROA7+mIugqJAOsc/kTzZvfb6Ua+0HckD39iTfFcUAAAAAHbNAuwAkr1MAmJaAAAAAAAAAAAAAAAAAAAAAAwJbxVAAAAAFNfCKzrfR7vcGZKmF9u4JB9rXOtH0Avwy+G1ERVFOXC8AAAAAAAAAAVVTRAAAAAAA6KYahh5gr2D4B3PgY0blxyy+Wdyt2jdgjVjvQlEdn9wAAAABVVNEQwAAAAA7mRE4Dv6Yi6CokA6xz+RPNm99vpRr7QdyQPf2JN8VxQAAAB4AAAAAHZETmQAAAAAdPR9wAAAAABznSNsAAAAAAAAAAwAAAAAAAAABAlvFrQAAAAU18IrOt9Hu9wZkqYX27gkH2tc60fQC/DL4bURFUU5cLwAAAAAAAAABVVNEAAAAAADophqGHmCvYPgHc+BjRuXHLL5Z3K3aN2CNWO9CUR2f3AAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAHgAAAAAdl3TbAAAAAB021n8AAAAAHOdI2wAAAAAAAAADAAAAAAAAAAMCW8VdAAAAAQAAAAAzLZ8nl00dWGwmhZ41swmc14jvBRVZNf4HKJZC7Cn7rwAAAAFVU0QAAAAAAOimGoYeYK9g+Adz4GNG5ccsvlncrdo3YI1Y70JRHZ/cAAAAAAAGYUJ//////////wAAAAEAAAAAAAAAAAAAAAECW8WtAAAAAQAAAAAzLZ8nl00dWGwmhZ41swmc14jvBRVZNf4HKJZC7Cn7rwAAAAFVU0QAAAAAAOimGoYeYK9g+Adz4GNG5ccsvlncrdo3YI1Y70JRHZ/cAAAAAAAAAAB//////////wAAAAEAAAAAAAAAAAAAAAIAAAADAlvFrQAAAAAAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAAADvWviAHpdQwAAAh5AAAAGgAAAAEAAAAAxHHGQ3BiyVBqiTQuU4oa2kBNL0HPHTolX0Mh98bg4XUAAAAAAAAAEXN0YWdpbmcubG9ic3RyLmNvAAAAChQUFAAAAAIAAAAAF9mFjahe1uzu7J4Zntu7568o3vsj4+LFcokaNQGNT3sAAAAKAAAAADU/Gj+t73CScyRkApJnA2Toxxe93xdMgpkGHC3BlONQAAAAAQAAAAEAAADpD6c/mAAAAAAAAYagAAAAAgAAAAAAAAAQAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAABAlvFrQAAAAAAAAAAMy2fJ5dNHVhsJoWeNbMJnNeI7wUVWTX+ByiWQuwp+68AAAAADvWviAHpdQwAAAh5AAAAGgAAAAEAAAAAxHHGQ3BiyVBqiTQuU4oa2kBNL0HPHTolX0Mh98bg4XUAAAAAAAAACWxvYnN0ci5jbwAAAAoUFBQAAAACAAAAABfZhY2oXtbs7uyeGZ7bu+evKN77I+PixXKJGjUBjU97AAAACgAAAAA1Pxo/re9wknMkZAKSZwNk6McXvd8XTIKZBhwtwZTjUAAAAAEAAAABAAAA6Q+nP5gAAAAAAAGGoAAAAAIAAAAAAAAAEAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        
        do {
            let envelopeData = Data(base64Encoded: envelopeResultXdr)!
            let transactionEnvelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data:envelopeData)
            XCTAssertTrue(transactionEnvelope.type() == 2)
            
            let resultData = Data(base64Encoded: transactionResultXdr)!
            let transactionResult = try XDRDecoder.decode(TransactionResultXDR.self, data:resultData)
            XCTAssertTrue(transactionResult.feeCharged == 200)
            
            let metaData = Data(base64Encoded: metaResultXdr)!
            let transactionMeta = try XDRDecoder.decode(TransactionMetaXDR.self, data:metaData)
            switch(transactionMeta) {
            case .transactionMetaV2(let v2):
                XCTAssertTrue(v2.operations.count == 2)
                break
            default:
                XCTFail()
            }
        } catch {
            XCTFail()
        }
    }
    
    func testGetTransactions() async {
        let responseEnum = await sdk.transactions.getTransactions(limit: 1)
        switch responseEnum {
        case .success(let transactionsResponse):
            await checkResult(transactionsResponse:transactionsResponse, limit:1)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetTransactions()", horizonRequestError: error)
            XCTFail()
        }
    
        func checkResult(transactionsResponse:PageResponse<TransactionResponse>, limit:Int) async {
            
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

            } else {
                let responseEnum = await sdk.transactions.getTransactions(limit: 2)
                switch responseEnum {
                case .success(let transactionsResponse):
                    await checkResult(transactionsResponse:transactionsResponse, limit:2)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                    XCTFail()
                }
            }
        }
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
    
    func testEnvelopeNoSignatures() {
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let accountBId = try! KeyPair.generateRandomKeyPair().accountId
        let accountASeqNr = Int64(379748123410432)
        let accountA = Account(keyPair:sourceAccountKeyPair, sequenceNumber: accountASeqNr)
        
        do {
            
            let createAccountOperation = CreateAccountOperation(sourceAccountId: sourceAccountKeyPair.accountId, destination: try KeyPair(accountId: accountBId), startBalance: 10)
            
            let transaction = try Transaction(sourceAccount: accountA,
                                              operations: [createAccountOperation],
                                              memo: Memo.text("Enjoy this transaction!"))
            
            
            let envelopeXdrBase64 = try! transaction.encodedEnvelope()
            let transaction2 = try! Transaction(envelopeXdr: envelopeXdrBase64)
            XCTAssertEqual(transaction.sourceAccount.keyPair.accountId, transaction2.sourceAccount.keyPair.accountId)
        } catch {
            XCTFail()
        }
    }
    
    func testXdrChangeTrustAssetSorting() {
    
        let xdrEnvelope = "AAAAAgAAAABn/gGugyO02pFFGaHeLzNEHF4xG6LdYuDPD98S59AjuwADDUABL9thAAAHOQAAAAEAAAAAAAAAAAAAAABnflzGAAAAAAAAAAIAAAAAAAAAF17U/Ee2yWNcLItkCC67OfbsTUVaBlLoBV+SBdMv/ujIAAAAAAAAoHQAAAAAAACgCwAAAAAAAKDeAAAAAAAAAAYAAAADAAAAAAAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAAXNVU0QAAAAAj2+KyPmYjEMFuwqWpv33O3NZCGoASCtyAGDvCBhfZ/QAAAAeAAAAAAAAAAAAAAAAAAAAAA=="
        do {
            let transaction = try Transaction(envelopeXdr: xdrEnvelope)
            let encodedEnvelope = try transaction.encodedEnvelope()
            XCTAssertTrue(xdrEnvelope == encodedEnvelope)

        } catch {
            XCTFail()
        }
    }
}
