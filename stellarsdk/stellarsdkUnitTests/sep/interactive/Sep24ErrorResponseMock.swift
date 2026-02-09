//
//  Sep24ErrorResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24ErrorResponseMock: ResponsesMock {
    var address: String

    init(address:String) {
        self.address = address

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }

            // Check for language parameter to determine response type
            if let key = mock.variables["lang"] {
                switch key {
                case "bad_request":
                    mock.statusCode = 400
                    return self.badRequestError
                case "unauthorized":
                    mock.statusCode = 401
                    return self.unauthorizedError
                case "forbidden":
                    mock.statusCode = 403
                    return self.forbiddenError
                case "not_found":
                    mock.statusCode = 404
                    return self.notFoundError
                case "server_error":
                    mock.statusCode = 500
                    return self.internalServerError
                case "unavailable":
                    mock.statusCode = 503
                    return self.serviceUnavailableError
                case "invalid_json":
                    mock.statusCode = 200
                    return self.invalidJsonResponse
                case "missing_fields":
                    mock.statusCode = 200
                    return self.missingFieldsResponse
                default:
                    mock.statusCode = 200
                    return self.infoSuccess
                }
            }
            mock.statusCode = 200
            return self.infoSuccess
        }

        return RequestMock(host: address,
                           path: "/info",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let badRequestError = """
    {
      "error": "Invalid request parameters"
    }
    """

    let unauthorizedError = """
    {
      "type": "authentication_required"
    }
    """

    let forbiddenError = """
    {
      "type": "authentication_required"
    }
    """

    let notFoundError = """
    {
      "error": "Resource not found"
    }
    """

    let internalServerError = """
    {
      "error": "Internal server error"
    }
    """

    let serviceUnavailableError = """
    {
      "error": "Service temporarily unavailable"
    }
    """

    let invalidJsonResponse = """
    { this is not valid json }
    """

    let missingFieldsResponse = """
    {
      "deposit": {},
      "withdraw": {}
    }
    """

    let infoSuccess = """
    {
      "deposit": {
        "USD": {
          "enabled": true,
          "fee_fixed": 5,
          "fee_percent": 1,
          "min_amount": 0.1,
          "max_amount": 1000
        }
      },
      "withdraw": {
        "USD": {
          "enabled": true,
          "fee_minimum": 5,
          "fee_percent": 0.5,
          "min_amount": 0.1,
          "max_amount": 1000
        }
      },
      "fee": {
        "enabled": false
      },
      "features": {
        "account_creation": true,
        "claimable_balances": true
      }
    }
    """
}
