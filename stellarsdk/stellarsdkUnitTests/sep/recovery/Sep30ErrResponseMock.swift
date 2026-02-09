//
//  Sep30ErrResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

class Sep30ErrResponseMock: ResponsesMock {
    var host: String
    var address: String
    var httpMethod: String

    init(host:String, address:String, httpMethod: String = "POST") {
        self.host = host
        self.address = address
        self.httpMethod = httpMethod

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in

            if "BAD_REQ" == self?.address {
                mock.statusCode = 400
                return """
                    {
                      "error": "bad request"
                    }
                    """
            } else if "UNAUTH" == self?.address {
                mock.statusCode = 401
                return """
                    {
                      "error": "unauthorized"
                    }
                    """
            } else if "NOT_FOUND" == self?.address {
                mock.statusCode = 404
                return """
                    {
                      "error": "not found"
                    }
                    """
            } else if "CONFLICT" == self?.address {
                mock.statusCode = 409
                return """
                    {
                      "error": "account already exists"
                    }
                    """
            }

            mock.statusCode = 200
            return ""
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: httpMethod,
                           mockHandler: handler)
    }
}
