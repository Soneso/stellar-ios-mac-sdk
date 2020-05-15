//
//  WebAuthenticatorSendChallengeResponseMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 16/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

class WebAuthenticatorSendChallengeResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully(), let json = try! JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any] {
                if let key = json["transaction"] as? String {
                    let transactionEnvelope = try! TransactionEnvelopeXDR(xdr: key)
                    //let transactionXDR = transactionEnvelope.tx
                    let transactionHash = try! [UInt8](transactionEnvelope.txHash(network: .testnet))
                    
                    // validate signature
                    var validSignature = false
                    for signature in transactionEnvelope.txSignatures {
                        let sign = signature.signature
                        let clientKeyPair = try! KeyPair(accountId: "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V")
                        let signatureIsValid = try! clientKeyPair.verify(signature: [UInt8](sign), message: transactionHash)
                        if signatureIsValid {
                            validSignature = true
                        }
                    }
                    
                    if validSignature {
                        mock.statusCode = 200
                        return self?.requestSuccess()
                    } else if key == "GA5YLRKU57II42AXED2LA3IO2AL4URSVO3WXI7CIE4KJDPJSSRUSDJU7" {
                        mock.statusCode = 400
                        return self?.requestError
                    }
                }
            }
            
            return self?.requestError
        }
        
        return RequestMock(host: address,
                           path: "/auth",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
    
    func requestSuccess() -> String {
        return """
        {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0"
        }
        """
    }
    
    let requestError = """
    {
        "error": "The provided transaction is not valid"
    }
    """
    
}
