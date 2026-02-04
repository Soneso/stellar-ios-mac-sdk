//
//  ClaimableBalancesLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class ClaimableBalancesLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var responsesMock: ClaimableBalancesResponsesMock?
    var mockRegistered = false

    override func setUp() {
        super.setUp()

        ServerMock.removeAll()
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }

        responsesMock = ClaimableBalancesResponsesMock()
    }

    override func tearDown() {
        responsesMock = nil
        super.tearDown()
    }

    func testGetClaimableBalance() async {
        let balanceId = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
            }
          },
          "id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632370,
          "last_modified_time": "2021-08-04T20:01:24Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "unconditional": true
              }
            }
          ],
          "paging_token": "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.balanceId, balanceId)
            XCTAssertEqual(balance.amount, "10.0000000")
            XCTAssertTrue(balance.asset.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(balance.sponsor, "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL")
            XCTAssertEqual(balance.lastModifiedLedger, 632370)
            XCTAssertEqual(balance.lastModifiedTime, "2021-08-04T20:01:24Z")
            XCTAssertEqual(balance.claimants.count, 1)
            XCTAssertEqual(balance.claimants[0].destination, "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML")
            XCTAssertEqual(balance.pagingToken, "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetClaimableBalance()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testGetClaimableBalances() async {
        let claimantAccountId = "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML"
        let balancesJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances?claimant=GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML&cursor=&limit=10&order=asc"
            },
            "next": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances?claimant=GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML&cursor=632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072&limit=10&order=asc"
            },
            "prev": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances?claimant=GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML&cursor=632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072&limit=10&order=desc"
            }
          },
          "_embedded": {
            "records": [
              {
                "_links": {
                  "self": {
                    "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
                  }
                },
                "id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
                "asset": "native",
                "amount": "10.0000000",
                "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
                "last_modified_ledger": 632370,
                "last_modified_time": "2021-08-04T20:01:24Z",
                "claimants": [
                  {
                    "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
                    "predicate": {
                      "unconditional": true
                    }
                  }
                ],
                "paging_token": "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
              },
              {
                "_links": {
                  "self": {
                    "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
                  }
                },
                "id": "00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9",
                "asset": "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "amount": "100.0000000",
                "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
                "last_modified_ledger": 632371,
                "last_modified_time": "2021-08-04T20:01:30Z",
                "claimants": [
                  {
                    "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
                    "predicate": {
                      "and": [
                        {
                          "abs_before": "2024-12-31T23:59:59Z"
                        },
                        {
                          "not": {
                            "unconditional": true
                          }
                        }
                      ]
                    }
                  }
                ],
                "paging_token": "632371-00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
              }
            ]
          }
        }
        """

        responsesMock?.addClaimableBalances(key: claimantAccountId, response: balancesJson)

        let response = await sdk.claimableBalances.getClaimableBalances(claimantAccountId: claimantAccountId)
        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
            XCTAssertEqual(page.records.count, 2)

            let firstBalance = page.records[0]
            XCTAssertEqual(firstBalance.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
            XCTAssertTrue(firstBalance.asset.type == AssetType.ASSET_TYPE_NATIVE)
            XCTAssertEqual(firstBalance.amount, "10.0000000")

            let secondBalance = page.records[1]
            XCTAssertEqual(secondBalance.balanceId, "00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9")
            XCTAssertTrue(secondBalance.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(secondBalance.amount, "100.0000000")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetClaimableBalances()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimableBalanceResponse() async {
        let balanceId = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
            }
          },
          "id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
          "asset": "EUR:GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL",
          "amount": "250.5000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632370,
          "last_modified_time": "2021-08-04T20:01:24Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "unconditional": true
              }
            }
          ],
          "paging_token": "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertNotNil(balance.links)
            XCTAssertEqual(balance.balanceId, balanceId)
            XCTAssertTrue(balance.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertEqual(balance.asset.code, "EUR")
            XCTAssertEqual(balance.asset.issuer?.accountId, "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL")
            XCTAssertEqual(balance.amount, "250.5000000")
            XCTAssertEqual(balance.sponsor, "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL")
            XCTAssertEqual(balance.lastModifiedLedger, 632370)
            XCTAssertEqual(balance.lastModifiedTime, "2021-08-04T20:01:24Z")
            XCTAssertEqual(balance.pagingToken, "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimableBalanceResponse()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimantPredicateUnconditional() async {
        let balanceId = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
            }
          },
          "id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632370,
          "last_modified_time": "2021-08-04T20:01:24Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "unconditional": true
              }
            }
          ],
          "paging_token": "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.claimants.count, 1)
            let predicate = balance.claimants[0].predicate
            XCTAssertNotNil(predicate.unconditional)
            XCTAssertTrue(predicate.unconditional!)
            XCTAssertNil(predicate.and)
            XCTAssertNil(predicate.or)
            XCTAssertNil(predicate.not)
            XCTAssertNil(predicate.beforeAbsoluteTime)
            XCTAssertNil(predicate.beforeRelativeTime)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimantPredicateUnconditional()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimantPredicateAnd() async {
        let balanceId = "00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
            }
          },
          "id": "00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632371,
          "last_modified_time": "2021-08-04T20:01:30Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "and": [
                  {
                    "abs_before": "2024-12-31T23:59:59Z"
                  },
                  {
                    "rel_before": "3600"
                  }
                ]
              }
            }
          ],
          "paging_token": "632371-00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.claimants.count, 1)
            let predicate = balance.claimants[0].predicate
            XCTAssertNotNil(predicate.and)
            XCTAssertEqual(predicate.and?.count, 2)
            XCTAssertEqual(predicate.and?[0].beforeAbsoluteTime, "2024-12-31T23:59:59Z")
            XCTAssertEqual(predicate.and?[1].beforeRelativeTime, "3600")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimantPredicateAnd()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimantPredicateOr() async {
        let balanceId = "00000000aa8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000aa8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
            }
          },
          "id": "00000000aa8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632372,
          "last_modified_time": "2021-08-04T20:01:35Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "or": [
                  {
                    "abs_before": "2024-12-31T23:59:59Z"
                  },
                  {
                    "unconditional": true
                  }
                ]
              }
            }
          ],
          "paging_token": "632372-00000000aa8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.claimants.count, 1)
            let predicate = balance.claimants[0].predicate
            XCTAssertNotNil(predicate.or)
            XCTAssertEqual(predicate.or?.count, 2)
            XCTAssertEqual(predicate.or?[0].beforeAbsoluteTime, "2024-12-31T23:59:59Z")
            XCTAssertEqual(predicate.or?[1].unconditional, true)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimantPredicateOr()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimantPredicateNot() async {
        let balanceId = "00000000bb8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000bb8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
            }
          },
          "id": "00000000bb8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632373,
          "last_modified_time": "2021-08-04T20:01:40Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "not": {
                  "abs_before": "2024-12-31T23:59:59Z"
                }
              }
            }
          ],
          "paging_token": "632373-00000000bb8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.claimants.count, 1)
            let predicate = balance.claimants[0].predicate
            XCTAssertNotNil(predicate.not)
            XCTAssertEqual(predicate.not?.beforeAbsoluteTime, "2024-12-31T23:59:59Z")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimantPredicateNot()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimantPredicateBeforeAbsoluteTime() async {
        let balanceId = "00000000cc8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000cc8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
            }
          },
          "id": "00000000cc8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632374,
          "last_modified_time": "2021-08-04T20:01:45Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "abs_before": "2025-01-01T00:00:00Z"
              }
            }
          ],
          "paging_token": "632374-00000000cc8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.claimants.count, 1)
            let predicate = balance.claimants[0].predicate
            XCTAssertNotNil(predicate.beforeAbsoluteTime)
            XCTAssertEqual(predicate.beforeAbsoluteTime, "2025-01-01T00:00:00Z")
            XCTAssertNil(predicate.unconditional)
            XCTAssertNil(predicate.and)
            XCTAssertNil(predicate.or)
            XCTAssertNil(predicate.not)
            XCTAssertNil(predicate.beforeRelativeTime)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimantPredicateBeforeAbsoluteTime()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testClaimantPredicateBeforeRelativeTime() async {
        let balanceId = "00000000dd8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000dd8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
            }
          },
          "id": "00000000dd8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9",
          "asset": "native",
          "amount": "10.0000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632375,
          "last_modified_time": "2021-08-04T20:01:50Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "rel_before": "86400"
              }
            }
          ],
          "paging_token": "632375-00000000dd8826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9"
        }
        """

        responsesMock?.addClaimableBalance(balanceId: balanceId, response: balanceJson)

        let response = await sdk.claimableBalances.getClaimableBalance(balanceId: balanceId)
        switch response {
        case .success(let balance):
            XCTAssertEqual(balance.claimants.count, 1)
            let predicate = balance.claimants[0].predicate
            XCTAssertNotNil(predicate.beforeRelativeTime)
            XCTAssertEqual(predicate.beforeRelativeTime, "86400")
            XCTAssertNil(predicate.unconditional)
            XCTAssertNil(predicate.and)
            XCTAssertNil(predicate.or)
            XCTAssertNil(predicate.not)
            XCTAssertNil(predicate.beforeAbsoluteTime)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testClaimantPredicateBeforeRelativeTime()", horizonRequestError: error)
            XCTFail("Expected success but got failure: \(error)")
        }
    }
}
