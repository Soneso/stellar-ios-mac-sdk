//
//  Sep30SignTransactionErrMock.swift
//  stellarsdk
//
//  Created by Soneso on 06.02.26.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep30SignTransactionErrMock: ResponsesMock {
    var host: String
    var address: String
    var signingAddress: String

    init(host: String, address: String, signingAddress: String) {
        self.host = host
        self.address = address
        self.signingAddress = signingAddress
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }

            if self.address == "BAD_REQ" {
                mock.statusCode = 400
                return """
                    {
                      "error": "invalid transaction format"
                    }
                    """
            } else if self.address == "UNAUTH" {
                mock.statusCode = 401
                return """
                    {
                      "error": "jwt token expired"
                    }
                    """
            } else if self.address == "NOT_FOUND" {
                mock.statusCode = 404
                return """
                    {
                      "error": "account not found"
                    }
                    """
            } else if self.signingAddress == "INVALID_SIGNER" {
                mock.statusCode = 404
                return """
                    {
                      "error": "signer not found for account"
                    }
                    """
            }

            mock.statusCode = 200
            return ""
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)/sign/\(signingAddress)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
