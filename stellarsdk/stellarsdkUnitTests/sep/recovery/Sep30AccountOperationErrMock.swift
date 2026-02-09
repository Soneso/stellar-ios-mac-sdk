//
//  Sep30AccountOperationErrMock.swift
//  stellarsdk
//
//  Created by Soneso on 06.02.26.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep30AccountOperationErrMock: ResponsesMock {
    var host: String
    var address: String
    var httpMethod: String
    var statusCode: Int
    var errorMessage: String

    init(host: String, address: String, httpMethod: String, statusCode: Int, errorMessage: String) {
        self.host = host
        self.address = address
        self.httpMethod = httpMethod
        self.statusCode = statusCode
        self.errorMessage = errorMessage
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }
            mock.statusCode = self.statusCode
            return """
                {
                  "error": "\(self.errorMessage)"
                }
                """
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: httpMethod,
                           mockHandler: handler)
    }
}
