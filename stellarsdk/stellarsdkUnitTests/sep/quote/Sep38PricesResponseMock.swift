//
//  Sep38PricesResponseMock.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep38PricesResponseMock: ResponsesMock {
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
                  "error": "sell_asset is required"
                }
                """
            } else if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
                      authHeader.hasSuffix("_error_forbidden") {
                mock.statusCode = 403
                return """
                {
                  "error": "JWT token expired"
                }
                """
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/prices",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func minimalParamsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "buy_assets": [
                {
                  "asset": "iso4217:BRL",
                  "price": "0.18",
                  "decimals": 2
                }
              ]
            }
            """
        }

        return RequestMock(host: host,
                           path: "/prices_minimal",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func emptyBuyAssetsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "buy_assets": []
            }
            """
        }

        return RequestMock(host: host,
                           path: "/prices_empty",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func multipleBuyAssetsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "buy_assets": [
                {
                  "asset": "iso4217:BRL",
                  "price": "0.18",
                  "decimals": 2
                },
                {
                  "asset": "iso4217:USD",
                  "price": "1.00",
                  "decimals": 2
                },
                {
                  "asset": "stellar:EURC:GDHU6WRG4IEQXM5NZ4BMPKOXHW76MZM4Y2IEMFDVXBSDP6SJY4ITNPP2",
                  "price": "0.92",
                  "decimals": 7
                }
              ]
            }
            """
        }

        return RequestMock(host: host,
                           path: "/prices_multi",
                           httpMethod: "GET",
                           mockHandler: handler)
    }


    func largeDecimalsRequestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "buy_assets": [
                {
                  "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                  "price": "0.000000001234567890123456789",
                  "decimals": 18
                }
              ]
            }
            """
        }

        return RequestMock(host: host,
                           path: "/prices_large",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let success = """
    {
      "buy_assets": [
        {
          "asset": "iso4217:BRL",
          "price": "0.18",
          "decimals": 2
        }
      ]
    }
    """
}
