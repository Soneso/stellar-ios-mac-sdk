//
//  StellarSDK.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class StellarSDK: NSObject {
    
    public var horizonURL: String
    
    public var accounts: AccountService
    public var assets: AssetsService
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
    
    public override init() {
        horizonURL = "https://horizon-testnet.stellar.org"
        
        accounts = AccountService(baseURL: horizonURL)
        assets = AssetsService(baseURL: horizonURL)
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
    }
    
    public init(withHorizonUrl horizonURL:String) {
        self.horizonURL = horizonURL
        
        accounts = AccountService(baseURL: horizonURL)
        assets = AssetsService(baseURL: horizonURL)
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
    }
}
