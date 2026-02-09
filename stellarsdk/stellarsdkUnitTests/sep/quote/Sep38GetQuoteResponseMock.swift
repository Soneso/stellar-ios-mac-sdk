//
//  Sep38GetQuoteResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38GetQuoteResponseMock: ResponsesMock {
    var host: String

    init(host:String) {
        self.host = host

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/quote/de762cda-a193-4961-861e-57b31fed6eb3",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func notFoundRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "error": "Quote not found"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote/notfound",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func badRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {
              "error": "Invalid quote ID format"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote/invalid-format",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func forbiddenRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {
              "error": "Not authorized to access this quote"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote/forbidden-id",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func expiredQuoteMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "id": "expired-id",
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
                           path: "/quote/expired-id",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func noFeeDetailsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "id": "no-fee-details-id",
              "expires_at": "2030-12-31T23:59:59Z",
              "total_price": "1.02",
              "price": "1.00",
              "sell_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
              "sell_amount": "102",
              "buy_asset": "iso4217:EUR",
              "buy_amount": "100",
              "fee": {
                "total": "2.00",
                "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote/no-fee-details-id",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func malformedResponseMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "id": "malformed",
              "price": "1.00"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/quote/malformed",
                           httpMethod: "GET",
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
