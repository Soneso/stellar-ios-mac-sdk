//
//  ClaimableBalancesResponsesMock.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

class ClaimableBalancesResponsesMock: ResponsesMock {
    var claimableBalancesResponses = [String: String]()
    var claimableBalanceDetailsResponses = [String: String]()

    private var detailMock: RequestMock?
    private var listMock: RequestMock?

    override init() {
        super.init()

        // Register detail mock for /claimable_balances/{id}
        let detailHandler: MockHandler = { [weak self] mock, request in
            if let balanceId = mock.variables["balance_id"],
               let response = self?.claimableBalanceDetailsResponses[balanceId] {
                return response
            }
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        detailMock = RequestMock(host: "horizon-testnet.stellar.org",
                                 path: "/claimable_balances/${balance_id}",
                                 httpMethod: "GET",
                                 mockHandler: detailHandler)
        ServerMock.add(mock: detailMock!)

        // Register list mock for /claimable_balances?...
        let listHandler: MockHandler = { [weak self] mock, request in
            // Check for claimant filter
            if let claimant = mock.variables["claimant"],
               let response = self?.claimableBalancesResponses[claimant] {
                return response
            }
            // Check for asset filter
            if let asset = mock.variables["asset"],
               let response = self?.claimableBalancesResponses[asset] {
                return response
            }
            // Check for sponsor filter
            if let sponsor = mock.variables["sponsor"],
               let response = self?.claimableBalancesResponses[sponsor] {
                return response
            }
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        listMock = RequestMock(host: "horizon-testnet.stellar.org",
                               path: "/claimable_balances",
                               httpMethod: "GET",
                               mockHandler: listHandler)
        ServerMock.add(mock: listMock!)
    }

    deinit {
        if let mock = detailMock {
            ServerMock.remove(mock: mock)
        }
        if let mock = listMock {
            ServerMock.remove(mock: mock)
        }
    }

    func addClaimableBalances(key: String, response: String) {
        claimableBalancesResponses[key] = response
    }

    func addClaimableBalance(balanceId: String, response: String) {
        claimableBalanceDetailsResponses[balanceId] = response
    }

    override func requestMock() -> RequestMock {
        // Return a dummy mock - actual mocks are registered in init()
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/claimable_balances_dummy",
                          httpMethod: "GET",
                          mockHandler: handler)
    }
}
