//
//  Sep38PriceResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38PriceResponseMock: ResponsesMock {
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
                  "error": "sell_asset and buy_asset are required"
                }
                """
            } else if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
                      authHeader.hasSuffix("_error_forbidden") {
                mock.statusCode = 403
                return """
                {
                  "error": "Invalid JWT signature"
                }
                """
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/price",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func sep6ContextRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "total_price": "1.05",
              "price": "1.00",
              "sell_amount": "105",
              "buy_amount": "100",
              "fee": {
                "total": "5.00",
                "asset": "iso4217:USD"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/price_sep6",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func sellAmountRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "total_price": "0.20",
              "price": "0.18",
              "sell_amount": "100",
              "buy_amount": "500",
              "fee": {
                "total": "10.00",
                "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/price_sell",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func noFeeDetailsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "total_price": "1.02",
              "price": "1.00",
              "sell_amount": "102",
              "buy_amount": "100",
              "fee": {
                "total": "2.00",
                "asset": "iso4217:EUR"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/price_nofee",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func emptyFeeDetailsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "total_price": "1.03",
              "price": "1.00",
              "sell_amount": "103",
              "buy_amount": "100",
              "fee": {
                "total": "3.00",
                "asset": "iso4217:GBP",
                "details": []
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/price_emptyfee",
                           httpMethod: "GET",
                           mockHandler: handler)
    }


    func largeValuesRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "total_price": "999999999999.999999999999",
              "price": "999999999999.000000000000",
              "sell_amount": "999999999999999999",
              "buy_amount": "1",
              "fee": {
                "total": "0.999999999999",
                "asset": "stellar:XLM"
              }
            }
            """
        }

        return RequestMock(host: host,
                           path: "/price_large",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let success = """
    {
      "total_price": "0.20",
      "price": "0.18",
      "sell_amount": "100",
      "buy_amount": "500",
      "fee": {
        "total": "10.00",
        "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
        "details": [
          {
            "name": "Service fee",
            "amount": "5.00"
          },
          {
            "name": "PIX fee",
            "description": "Fee charged in order to process the outgoing BRL PIX transaction.",
            "amount": "5.00"
          }
        ]
      }
    }
    """
}
