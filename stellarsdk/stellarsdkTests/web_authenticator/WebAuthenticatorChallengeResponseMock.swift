//
//  WebAuthenticatorGetChallengeResponseMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 16/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

class WebAuthenticatorChallengeResponseMock: ResponsesMock {
    var address: String
    var serverKeyPair: KeyPair
    
    init(address:String, serverKeyPair:KeyPair) {
        self.address = address
        self.serverKeyPair = serverKeyPair
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let key = mock.variables["account"] {
                if key == "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V" {
                    mock.statusCode = 200
                    return self?.requestSuccess(account: key)
                } else if key == "GAUQO2IDU23EJGLTUTOLSL2VBSWCS3YCVUBP3FET6VQJAUULNZ5CCW3Y" {
                    mock.statusCode = 200
                    return self?.requestInvalidSeq(account: "GAUQO2IDU23EJGLTUTOLSL2VBSWCS3YCVUBP3FET6VQJAUULNZ5CCW3Y")
                } else if key == "GDWPRWTBZBVNUBRPHQXOKIJR4GRAALJ34HWHEWO7O3GGLJ5DA3XKSLMD" {
                    mock.statusCode = 200
                    return self?.requestSuccess(account: "GBCJQ6Q7PVSRZJA26A76AP4UJM4WORKUSMDEIAAZLYR4HHRG3GQI4GUZ")
                } else if key == "GBCJQ6Q7PVSRZJA26A76AP4UJM4WORKUSMDEIAAZLYR4HHRG3GQI4GUZ" {
                    mock.statusCode = 400
                    return self?.requestError
                } else if key == "GDRNSOWWZWLVFMBY4ZUUFVJXWYRVVGCC7ALXNEWZU7X2TODIRHAZANNA" {
                    mock.statusCode = 200
                    return self?.requestInvalidOperationType()
                } else if key == "GDTJSQ4KGWKKYDIAR5WKMKDQVNKK2BUR6KY43VWZ464T6FWJHHIG7ZI4" {
                    mock.statusCode = 200
                    return self?.requestInvalidOperationCount()
                } else if key == "GBLIKSJM67PCYH7CNFLQETPPOWATL2PVH2SY7WGWDQEOK47FANF3PIIX" {
                    mock.statusCode = 200
                    return self?.requestInvalidTimebounds(account: key)
                } else if key == "GBPFFS63LXKHUL5SFJAI4737JJ2UHEQJXKJRQ3BFBN2PQC4RQ2OLMPSY" {
                    mock.statusCode = 200
                    return self?.requestInvalidSignature(account: key)
                } else if key == "GBGWIAAKWQFGARYINLHSPFIQCHMMGNJICNRRO435L4AP7DNYYHYMNFFT" {
                    mock.statusCode = 200
                    return self?.requestNotFoundSignature(account: key)
                } else if key == "GA5YLRKU57II42AXED2LA3IO2AL4URSVO3WXI7CIE4KJDPJSSRUSDJU7" {
                    mock.statusCode = 200
                    return self?.requestSuccess(account: key)
                }
            }
            
            return "not treated"
        }
        
        return RequestMock(host: address,
                           path: "/auth",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    func generateNonce(length: Int) -> String? {
        let nonce = NSMutableData(length: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, nonce!.length, nonce!.mutableBytes)
        if result == errSecSuccess {
            return (nonce! as Data).base64EncodedString()
        } else {
            return nil
        }
    }
    
    func requestSuccess(account: String) -> String {
        let clientKeyPair = try! KeyPair(accountId: account)
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970), maxTime: UInt64(Date().timeIntervalSince1970 + 300))
        
        let operation = ManageDataOperation(sourceAccount: clientKeyPair, name: "test auth", data: generateNonce(length: 64)?.data(using: .utf8))
        
        let transaction = try! Transaction(sourceAccount: transactionAccount, operations: [operation], memo: nil, timeBounds: timeBounds)
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        
        return """
                {
                "transaction": "\(try! transaction.encodedEnvelope())"
                }
                """
    }
    
    func requestInvalidSeq(account: String) -> String {
        let clientKeyPair = try! KeyPair(accountId: account)
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: 123)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970), maxTime: UInt64(Date().timeIntervalSince1970 + 300))
        
        let operation = ManageDataOperation(sourceAccount: clientKeyPair, name: "test auth", data: generateNonce(length: 64)?.data(using: .utf8))
        
        let transaction = try! Transaction(sourceAccount: transactionAccount, operations: [operation], memo: nil, timeBounds: timeBounds)
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        
        return """
        {
        "transaction": "\(try! transaction.encodedEnvelope())"
        }
        """
    }
    
    func requestInvalidOperationType() -> String {
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970), maxTime: UInt64(Date().timeIntervalSince1970 + 300))
        
        let sourceAccountKeyPair = try! KeyPair(secretSeed:"SBCUVXRTONIII2HOZLCXQUSNMBKFLZBSN3BEZKTP7ACPBG5DZQEV62F5")
        let destinationAccountKeyPair = try! KeyPair(secretSeed: "SDA6XCDPNHTT7ZAHMW4H5LJG4HN7SJC2DU3RZ6QXVR3QFIFNWJ5ZAFHT")
        let operation = PaymentOperation(sourceAccount: sourceAccountKeyPair,
                                         destination: destinationAccountKeyPair,
                                         asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                         amount: 1.5)
        
        let transaction = try! Transaction(sourceAccount: transactionAccount, operations: [operation], memo: nil, timeBounds: timeBounds)
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        
        return """
        {
        "transaction": "\(try! transaction.encodedEnvelope())"
        }
        """
    }
    
    func requestInvalidOperationCount() -> String {
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: 0)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970), maxTime: UInt64(Date().timeIntervalSince1970 + 300))
        
        var transaction = TransactionXDR(sourceAccount: transactionAccount.keyPair.publicKey, seqNum: transactionAccount.sequenceNumber, timeBounds: timeBounds.toXdr(), memo: .none, operations: [])
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        
        return """
        {
        "transaction": "\(try! transaction.encodedEnvelope())"
        }
        """
    }
    
    func requestInvalidTimebounds(account: String) -> String {
        let clientKeyPair = try! KeyPair(accountId: account)
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970) + 800, maxTime: UInt64(Date().timeIntervalSince1970 + 1200))
        
        let operation = ManageDataOperation(sourceAccount: clientKeyPair, name: "test auth", data: generateNonce(length: 64)?.data(using: .utf8))
        
        let transaction = try! Transaction(sourceAccount: transactionAccount, operations: [operation], memo: nil, timeBounds: timeBounds)
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        
        return "{ \"transaction\": \"\(try! transaction.encodedEnvelope())\" }"
    }
    
    func requestInvalidSignature(account: String) -> String {
        let clientKeyPair = try! KeyPair(accountId: account)
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970), maxTime: UInt64(Date().timeIntervalSince1970 + 300))
        
        let operation = ManageDataOperation(sourceAccount: clientKeyPair, name: "test auth", data: generateNonce(length: 64)?.data(using: .utf8))
        
        let transaction = try! Transaction(sourceAccount: transactionAccount, operations: [operation], memo: nil, timeBounds: timeBounds)
        let keyPair = try! KeyPair(secretSeed: "SCNNPRMRJSIEZ2M64YP5TKM3P2XPJJDEQ2YS33RA5Y4GS7AOJHKLXVP4")
        try! transaction.sign(keyPair: keyPair, network: .testnet)
        
        return "{ \"transaction\": \"\(try! transaction.encodedEnvelope())\" }"
    }
    
    func requestNotFoundSignature(account: String) -> String {
        let clientKeyPair = try! KeyPair(accountId: account)
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: 0)
        
        let timeBounds = try! TimeBounds(minTime: UInt64(Date().timeIntervalSince1970), maxTime: UInt64(Date().timeIntervalSince1970 + 300))
        
        let operation = ManageDataOperation(sourceAccount: clientKeyPair, name: "test auth", data: generateNonce(length: 64)?.data(using: .utf8))
        
        let transaction = TransactionXDR(sourceAccount: transactionAccount.keyPair.publicKey, seqNum: transactionAccount.sequenceNumber, timeBounds: timeBounds.toXdr(), memo: .none, operations: [try! operation.toXDR()])
        
        let envelopeV1 = TransactionV1EnvelopeXDR(tx: transaction, signatures: [])
        let envelope = TransactionEnvelopeXDR.v1(envelopeV1)
        var encodedEnvelope = try! XDREncoder.encode(envelope)
        
        return "{ \"transaction\": \"\(Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString())\" }"
    }
    
    let requestError = """
    {
        "error": "The provided account has requested too many challenges recently. Try again later."
    }
    """
    
}
