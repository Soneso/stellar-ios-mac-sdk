//
//  LiquidityPoolsResponsesMock.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

class LiquidityPoolsResponsesMock: ResponsesMock {
    var liquidityPoolsResponses = [String: String]()
    var liquidityPoolDetailsResponses = [String: String]()
    var liquidityPoolTradesResponses = [String: String]()

    private var detailMock: RequestMock?
    private var listMock: RequestMock?
    private var tradesMock: RequestMock?

    override init() {
        super.init()

        // Register detail mock for /liquidity_pools/{id}
        let detailHandler: MockHandler = { [weak self] mock, request in
            if let poolId = mock.variables["pool_id"],
               let response = self?.liquidityPoolDetailsResponses[poolId] {
                return response
            }
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        detailMock = RequestMock(host: "horizon-testnet.stellar.org",
                                 path: "/liquidity_pools/${pool_id}",
                                 httpMethod: "GET",
                                 mockHandler: detailHandler)
        ServerMock.add(mock: detailMock!)

        // Register trades mock for /liquidity_pools/{id}/trades
        let tradesHandler: MockHandler = { [weak self] mock, request in
            if let poolId = mock.variables["pool_id"],
               let response = self?.liquidityPoolTradesResponses[poolId] {
                return response
            }
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        tradesMock = RequestMock(host: "horizon-testnet.stellar.org",
                                 path: "/liquidity_pools/${pool_id}/trades",
                                 httpMethod: "GET",
                                 mockHandler: tradesHandler)
        ServerMock.add(mock: tradesMock!)

        // Register list mock for /liquidity_pools?...
        let listHandler: MockHandler = { [weak self] mock, request in
            // Check for account filter
            if let account = mock.variables["account"],
               let response = self?.liquidityPoolsResponses[account] {
                return response
            }
            // Check for reserves filter
            if let reserves = mock.variables["reserves"],
               let response = self?.liquidityPoolsResponses[reserves] {
                return response
            }
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        listMock = RequestMock(host: "horizon-testnet.stellar.org",
                               path: "/liquidity_pools",
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
        if let mock = tradesMock {
            ServerMock.remove(mock: mock)
        }
    }

    func addLiquidityPools(key: String, response: String) {
        liquidityPoolsResponses[key] = response
    }

    func addLiquidityPool(poolId: String, response: String) {
        liquidityPoolDetailsResponses[poolId] = response
    }

    func addLiquidityPoolTrades(poolId: String, response: String) {
        liquidityPoolTradesResponses[poolId] = response
    }

    override func requestMock() -> RequestMock {
        // Return a dummy mock - actual mocks are registered in init()
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/liquidity_pools_dummy",
                          httpMethod: "GET",
                          mockHandler: handler)
    }
}
