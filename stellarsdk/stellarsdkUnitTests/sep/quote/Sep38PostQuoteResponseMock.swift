//
//  Sep38PostQuoteResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38PostQuoteResponseMock: ResponsesMock {
    var host: String

    init(host:String) {
        self.host = host

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            // Check for error triggers based on Authorization header suffix
            if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
               authHeader.hasSuffix("_error_bad") {
                mock.statusCode = 400
                return """
                {
                  "error": "sell_asset is not a supported asset"
                }
                """
            } else if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
                      authHeader.hasSuffix("_error_forbidden") {
                mock.statusCode = 403
                return """
                {
                  "error": "User not authorized for this operation"
                }
                """
            } else if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
                      authHeader.hasSuffix("_error_server") {
                mock.statusCode = 500
                return """
                {
                  "error": "Internal server error"
                }
                """
            } else if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
                      authHeader.hasSuffix("_error_malformed") {
                mock.statusCode = 200
                return """
                {
                  "id": "malformed",
                  "total_price": "1.00"
                }
                """
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/quote",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    func minimalRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "id": "minimal-quote-id",
              "expires_at": "2024-12-31T23:59:59Z",
              "total_price": "1.00",
              "price": "1.00",
              "sell_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
              "sell_amount": "100",
              "buy_asset": "iso4217:USD",
              "buy_amount": "100",
              "fee": {
                "total": "0",
                "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote_minimal",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    func fullParamsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "id": "full-params-quote-id",
              "expires_at": "2025-06-15T12:00:00Z",
              "total_price": "5.50",
              "price": "5.00",
              "sell_asset": "iso4217:BRL",
              "sell_amount": "550",
              "buy_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
              "buy_amount": "100",
              "fee": {
                "total": "50.00",
                "asset": "iso4217:BRL",
                "details": [
                  {
                    "name": "Service fee",
                    "amount": "25.00"
                  },
                  {
                    "name": "PIX fee",
                    "description": "Fee for PIX transaction processing",
                    "amount": "15.00"
                  },
                  {
                    "name": "Tax",
                    "description": "Brazilian IOF tax",
                    "amount": "10.00"
                  }
                ]
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote_full",
                           httpMethod: "POST",
                           mockHandler: handler)
    }


    func expiredQuoteMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "id": "expired-quote-id",
              "expires_at": "2020-01-01T00:00:00Z",
              "total_price": "1.00",
              "price": "1.00",
              "sell_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
              "sell_amount": "100",
              "buy_asset": "iso4217:USD",
              "buy_amount": "100",
              "fee": {
                "total": "0",
                "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote_expired",
                           httpMethod: "POST",
                           mockHandler: handler)
    }


    let success = """
    {
      "id": "de762cda-a193-4961-861e-57b31fed6eb3",
      "expires_at": "2021-04-30T07:42:23",
      "total_price": "5.42",
      "price": "5.00",
      "sell_asset": "iso4217:BRL",
      "sell_amount": "542",
      "buy_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
      "buy_amount": "100",
      "fee": {
        "total": "42.00",
        "asset": "iso4217:BRL",
        "details": [
          {
            "name": "PIX fee",
            "description": "Fee charged in order to process the outgoing PIX transaction.",
            "amount": "12.00"
          },
          {
            "name": "Brazilian conciliation fee",
            "description": "Fee charged in order to process conciliation costs with intermediary banks.",
            "amount": "15.00"
          },
          {
            "name": "Service fee",
            "amount": "15.00"
          }
        ]
      }
    }
    """

}
