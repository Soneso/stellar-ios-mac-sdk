//
//  StellarSDK.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class StellarSDK: NSObject {
    
    public static let publicNetUrl = "https://horizon.stellar.org"
    public static let testNetUrl = "https://horizon-testnet.stellar.org"
    public static let futureNetUrl = "https://horizon-futurenet.stellar.org"
    
    public var horizonURL: String
    
    public var accounts: AccountService
    public var assets: AssetsService
    public var feeStats: FeeStatsService
    public var effects: EffectsService
    public var ledgers: LedgersService
    public var operations: OperationsService
    public var payments: PaymentsService
    public var transactions: TransactionsService
    public var trades: TradesService
    public var tradeAggregations: TradeAggregationsService
    public var offers: OffersService
    public var orderbooks: OrderbookService
    public var paymentPaths: PaymentPathsService
    public var claimableBalances: ClaimableBalancesService
    public var liquidityPools: LiquidityPoolsService
    
    public override init() {
        horizonURL = StellarSDK.testNetUrl
        
        accounts = AccountService(baseURL: horizonURL)
        assets = AssetsService(baseURL: horizonURL)
        feeStats = FeeStatsService(baseURL: horizonURL)
        effects = EffectsService(baseURL: horizonURL)
        ledgers = LedgersService(baseURL: horizonURL)
        operations = OperationsService(baseURL: horizonURL)
        payments = PaymentsService(baseURL: horizonURL)
        transactions = TransactionsService(baseURL: horizonURL)
        trades = TradesService(baseURL: horizonURL)
        tradeAggregations = TradeAggregationsService(baseURL: horizonURL)
        offers = OffersService(baseURL: horizonURL)
        orderbooks = OrderbookService(baseURL: horizonURL)
        paymentPaths = PaymentPathsService(baseURL: horizonURL)
        claimableBalances = ClaimableBalancesService(baseURL: horizonURL)
        liquidityPools = LiquidityPoolsService(baseURL: horizonURL)
    }
    
    public init(withHorizonUrl horizonURL:String) {
        self.horizonURL = horizonURL
        
        accounts = AccountService(baseURL: horizonURL)
        assets = AssetsService(baseURL: horizonURL)
        feeStats = FeeStatsService(baseURL: horizonURL)
        effects = EffectsService(baseURL: horizonURL)
        ledgers = LedgersService(baseURL: horizonURL)
        operations = OperationsService(baseURL: horizonURL)
        payments = PaymentsService(baseURL: horizonURL)
        transactions = TransactionsService(baseURL: horizonURL)
        trades = TradesService(baseURL: horizonURL)
        tradeAggregations = TradeAggregationsService(baseURL: horizonURL)
        offers = OffersService(baseURL: horizonURL)
        orderbooks = OrderbookService(baseURL: horizonURL)
        paymentPaths = PaymentPathsService(baseURL: horizonURL)
        claimableBalances = ClaimableBalancesService(baseURL: horizonURL)
        liquidityPools = LiquidityPoolsService(baseURL: horizonURL)
    }
    
    public static func publicNet() -> StellarSDK {
        return StellarSDK(withHorizonUrl: StellarSDK.publicNetUrl)
    }
    
    public static func testNet() -> StellarSDK {
        return StellarSDK(withHorizonUrl: StellarSDK.testNetUrl)
    }
    
    public static func futureNet() -> StellarSDK {
        return StellarSDK(withHorizonUrl: StellarSDK.futureNetUrl)
    }
}
