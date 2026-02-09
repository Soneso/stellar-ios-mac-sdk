//
//  OperationsServiceResponseMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class OperationsServiceResponseMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let url = request.url else {
                mock.statusCode = 404
                return self?.resourceMissingResponse()
            }

            let path = url.path
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            // Extract query parameters
            var params: [String: String] = [:]
            for item in queryItems {
                params[item.name] = item.value ?? ""
            }

            let limit = params["limit"]
            let cursor = params["cursor"]
            let order = params["order"]

            // Check for invalid IDs or bad requests
            if path.contains("invalid") || path.contains("INVALID") {
                mock.statusCode = 404
                return self?.resourceMissingResponse()
            }

            if path.contains("malformed") {
                mock.statusCode = 200
                return "{invalid_json::"
            }

            if let limitValue = limit, let limitInt = Int(limitValue), limitInt > 200 {
                mock.statusCode = 400
                return self?.badRequestResponse()
            }

            // Handle operation details endpoint
            if path.hasPrefix("/operations/") && !path.contains("/accounts/") &&
               !path.contains("/ledgers/") && !path.contains("/transactions/") &&
               !path.contains("/claimable_balances/") && !path.contains("/liquidity_pools/") {

                if path.contains("999999999999") || path.contains("invalid") {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
                }

                return self?.operationDetailsResponse()
            }

            // Handle empty results for specific test cases
            if path.contains("GDUMMY") || path.contains("/ledgers/1/") {
                return self?.emptyPageResponse()
            }

            // Return operations page response
            return self?.operationsPageResponse(limit: limit, cursor: cursor, order: order)
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    private func operationsPageResponse(limit: String?, cursor: String?, order: String?) -> String {
        let limitValue = limit ?? "10"
        let orderValue = order ?? "desc"
        let cursorValue = cursor ?? ""

        return """
        {
          "_links": {
            "self": {
              "href": "https://\(address)/operations?order=\(orderValue)&limit=\(limitValue)&cursor=\(cursorValue)"
            },
            "next": {
              "href": "https://\(address)/operations?order=\(orderValue)&limit=\(limitValue)&cursor=123456790"
            },
            "prev": {
              "href": "https://\(address)/operations?order=asc&limit=\(limitValue)&cursor=123456788"
            }
          },
          "_embedded": {
            "records": [
              {
                "_links": {
                  "self": {
                    "href": "https://\(address)/operations/123456789"
                  },
                  "transaction": {
                    "href": "https://\(address)/transactions/6b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
                  },
                  "effects": {
                    "href": "https://\(address)/operations/123456789/effects"
                  },
                  "succeeds": {
                    "href": "https://\(address)/operations?order=desc&cursor=123456789"
                  },
                  "precedes": {
                    "href": "https://\(address)/operations?order=asc&cursor=123456789"
                  }
                },
                "id": "123456789",
                "paging_token": "123456789",
                "transaction_successful": true,
                "source_account": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "type": "payment",
                "type_i": 1,
                "created_at": "2023-01-01T00:00:00Z",
                "transaction_hash": "6b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a",
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG",
                "from": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "to": "GBTKSLJLC2E5SZCNUKNB34GXMXVR3LHJQFSAID64RDQQEZ3IQPBXZHZ6",
                "amount": "100.0000000"
              },
              {
                "_links": {
                  "self": {
                    "href": "https://\(address)/operations/123456788"
                  },
                  "transaction": {
                    "href": "https://\(address)/transactions/5b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
                  },
                  "effects": {
                    "href": "https://\(address)/operations/123456788/effects"
                  },
                  "succeeds": {
                    "href": "https://\(address)/operations?order=desc&cursor=123456788"
                  },
                  "precedes": {
                    "href": "https://\(address)/operations?order=asc&cursor=123456788"
                  }
                },
                "id": "123456788",
                "paging_token": "123456788",
                "transaction_successful": true,
                "source_account": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "type": "create_account",
                "type_i": 0,
                "created_at": "2023-01-01T00:00:01Z",
                "transaction_hash": "5b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a",
                "account": "GBTKSLJLC2E5SZCNUKNB34GXMXVR3LHJQFSAID64RDQQEZ3IQPBXZHZ6",
                "funder": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "starting_balance": "1000.0000000"
              },
              {
                "_links": {
                  "self": {
                    "href": "https://\(address)/operations/123456787"
                  },
                  "transaction": {
                    "href": "https://\(address)/transactions/4b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
                  },
                  "effects": {
                    "href": "https://\(address)/operations/123456787/effects"
                  },
                  "succeeds": {
                    "href": "https://\(address)/operations?order=desc&cursor=123456787"
                  },
                  "precedes": {
                    "href": "https://\(address)/operations?order=asc&cursor=123456787"
                  }
                },
                "id": "123456787",
                "paging_token": "123456787",
                "transaction_successful": true,
                "source_account": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "type": "manage_sell_offer",
                "type_i": 3,
                "created_at": "2023-01-01T00:00:02Z",
                "transaction_hash": "4b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a",
                "offer_id": "12345",
                "amount": "500.0000000",
                "price": "2.5000000",
                "price_r": {
                  "n": 5,
                  "d": 2
                },
                "buying_asset_type": "credit_alphanum4",
                "buying_asset_code": "USD",
                "buying_asset_issuer": "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG",
                "selling_asset_type": "native"
              },
              {
                "_links": {
                  "self": {
                    "href": "https://\(address)/operations/123456786"
                  },
                  "transaction": {
                    "href": "https://\(address)/transactions/3b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
                  },
                  "effects": {
                    "href": "https://\(address)/operations/123456786/effects"
                  },
                  "succeeds": {
                    "href": "https://\(address)/operations?order=desc&cursor=123456786"
                  },
                  "precedes": {
                    "href": "https://\(address)/operations?order=asc&cursor=123456786"
                  }
                },
                "id": "123456786",
                "paging_token": "123456786",
                "transaction_successful": true,
                "source_account": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "type": "manage_buy_offer",
                "type_i": 12,
                "created_at": "2023-01-01T00:00:03Z",
                "transaction_hash": "3b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a",
                "offer_id": "12346",
                "amount": "200.0000000",
                "price": "1.5000000",
                "price_r": {
                  "n": 3,
                  "d": 2
                },
                "buying_asset_type": "native",
                "selling_asset_type": "credit_alphanum4",
                "selling_asset_code": "EUR",
                "selling_asset_issuer": "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
              },
              {
                "_links": {
                  "self": {
                    "href": "https://\(address)/operations/123456785"
                  },
                  "transaction": {
                    "href": "https://\(address)/transactions/2b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
                  },
                  "effects": {
                    "href": "https://\(address)/operations/123456785/effects"
                  },
                  "succeeds": {
                    "href": "https://\(address)/operations?order=desc&cursor=123456785"
                  },
                  "precedes": {
                    "href": "https://\(address)/operations?order=asc&cursor=123456785"
                  }
                },
                "id": "123456785",
                "paging_token": "123456785",
                "transaction_successful": true,
                "source_account": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
                "type": "set_options",
                "type_i": 5,
                "created_at": "2023-01-01T00:00:04Z",
                "transaction_hash": "2b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a",
                "home_domain": "example.com",
                "inflation_dest": "GBTKSLJLC2E5SZCNUKNB34GXMXVR3LHJQFSAID64RDQQEZ3IQPBXZHZ6"
              }
            ]
          }
        }
        """
    }

    private func operationDetailsResponse() -> String {
        return """
        {
          "_links": {
            "self": {
              "href": "https://\(address)/operations/123456789"
            },
            "transaction": {
              "href": "https://\(address)/transactions/6b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
            },
            "effects": {
              "href": "https://\(address)/operations/123456789/effects"
            },
            "succeeds": {
              "href": "https://\(address)/operations?order=desc&cursor=123456789"
            },
            "precedes": {
              "href": "https://\(address)/operations?order=asc&cursor=123456789"
            }
          },
          "id": "123456789",
          "paging_token": "123456789",
          "transaction_successful": true,
          "source_account": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
          "type": "payment",
          "type_i": 1,
          "created_at": "2023-01-01T00:00:00Z",
          "transaction_hash": "6b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a",
          "asset_type": "credit_alphanum4",
          "asset_code": "USD",
          "asset_issuer": "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG",
          "from": "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
          "to": "GBTKSLJLC2E5SZCNUKNB34GXMXVR3LHJQFSAID64RDQQEZ3IQPBXZHZ6",
          "amount": "100.0000000"
        }
        """
    }

    private func emptyPageResponse() -> String {
        return """
        {
          "_links": {
            "self": {
              "href": "https://\(address)/operations"
            },
            "next": {
              "href": "https://\(address)/operations?cursor=0"
            },
            "prev": {
              "href": "https://\(address)/operations?cursor=0"
            }
          },
          "_embedded": {
            "records": []
          }
        }
        """
    }

    private func badRequestResponse() -> String {
        return """
        {
          "type": "https://stellar.org/horizon-errors/bad_request",
          "title": "Bad Request",
          "status": 400,
          "detail": "The request you sent was invalid in some way.",
          "instance": "horizon-testnet-001/bad-request-001"
        }
        """
    }
}
