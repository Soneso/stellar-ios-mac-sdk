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
    public var orderbooks: OrderbooksService
    
    public override init() {
        self.horizonURL = "https://horizon-testnet.stellar.org"
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
        orderbooks = OrderbooksService(baseURL: horizonURL)
    }
    
    public init(withHorizonUrl horizonURL:String) {
        
        self.horizonURL = horizonURL
        self.accounts = AccountService(baseURL: self.horizonURL)
        self.assets = AssetsService(baseURL: self.horizonURL)
        self.effects = EffectsService(baseURL: self.horizonURL)
        self.ledgers = LedgersService(baseURL: self.horizonURL)
        self.operations = OperationsService(baseURL: self.horizonURL)
        self.payments = PaymentsService(baseURL: self.horizonURL)
        self.transactions = TransactionsService(baseURL: self.horizonURL)
        self.trades = TradesService(baseURL: self.horizonURL)
        self.tradeAggregations = TradeAggregationsService(baseURL: self.horizonURL)
        self.offers = OffersService(baseURL: self.horizonURL)
        self.orderbooks = OrderbooksService(baseURL: self.horizonURL)
    }
    
}
