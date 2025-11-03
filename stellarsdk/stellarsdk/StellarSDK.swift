//
//  StellarSDK.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// The main entry point for interacting with the Stellar network via the Horizon API.
///
/// StellarSDK provides access to all Horizon API services including accounts, transactions,
/// operations, payments, assets, and more. Create an instance configured for your target
/// network (public, testnet, or futurenet) or connect to a custom Horizon server.
///
/// The SDK uses the Horizon REST API to query network state and submit transactions. Each
/// instance maintains a connection to a single Horizon server and provides access to
/// specialized service objects for different resource types.
///
/// Example:
/// ```swift
/// // Connect to testnet (default)
/// let sdk = StellarSDK()
///
/// // Connect to public network
/// let publicSdk = StellarSDK.publicNet()
///
/// // Connect to futurenet
/// let futureSdk = StellarSDK.futureNet()
///
/// // Connect to custom Horizon URL
/// let customSdk = StellarSDK(withHorizonUrl: "https://custom-horizon.example.com")
///
/// // Query account information
/// sdk.accounts.getAccountDetails(accountId: "GACCOUNT...") { response in
///     switch response {
///     case .success(let account):
///         print("Balances: \(account.balances)")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
///
/// // Stream payment events
/// sdk.payments.stream(for: .paymentsForAccount(account: "GACCOUNT...", cursor: nil))
///     .onReceive { payment in
///         print("Payment received: \(payment)")
///     }
/// ```
///
/// See also:
/// - [Network] for network passphrase configuration
/// - [Horizon API Documentation](https://developers.stellar.org/docs/data/horizon)
/// - Individual service classes for specific operations
public class StellarSDK: NSObject {
    
    /// Default Horizon URL for Stellar's public network.
    public static let publicNetUrl = "https://horizon.stellar.org"

    /// Default Horizon URL for Stellar's test network.
    public static let testNetUrl = "https://horizon-testnet.stellar.org"

    /// Default Horizon URL for Stellar's future network.
    public static let futureNetUrl = "https://horizon-futurenet.stellar.org"

    /// The Horizon server URL this SDK instance is connected to.
    public var horizonURL: String

    /// Service for querying and managing account information.
    public var accounts: AccountService

    /// Service for querying asset information and statistics.
    public var assets: AssetsService

    /// Service for querying network fee statistics.
    public var feeStats: FeeStatsService

    /// Service for querying effects (results of operations).
    public var effects: EffectsService

    /// Service for checking Horizon server health status.
    public var health: HealthService

    /// Service for querying ledger information.
    public var ledgers: LedgersService

    /// Service for querying operations.
    public var operations: OperationsService

    /// Service for querying payments and payment paths.
    public var payments: PaymentsService

    /// Service for querying and submitting transactions.
    public var transactions: TransactionsService

    /// Service for querying individual trades.
    public var trades: TradesService

    /// Service for querying aggregated trade data (OHLC).
    public var tradeAggregations: TradeAggregationsService

    /// Service for querying offers on the decentralized exchange.
    public var offers: OffersService

    /// Service for querying orderbook data.
    public var orderbooks: OrderbookService

    /// Service for finding payment paths between assets.
    public var paymentPaths: PaymentPathsService

    /// Service for querying claimable balances.
    public var claimableBalances: ClaimableBalancesService

    /// Service for querying liquidity pools.
    public var liquidityPools: LiquidityPoolsService

    /// Creates a new SDK instance connected to the test network.
    ///
    /// This is the default initializer and connects to Stellar's test network
    /// at https://horizon-testnet.stellar.org.
    public override init() {
        horizonURL = StellarSDK.testNetUrl

        accounts = AccountService(baseURL: horizonURL)
        assets = AssetsService(baseURL: horizonURL)
        feeStats = FeeStatsService(baseURL: horizonURL)
        effects = EffectsService(baseURL: horizonURL)
        health = HealthService(baseURL: horizonURL)
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

    /// Creates a new SDK instance connected to a custom Horizon server.
    ///
    /// Use this initializer when connecting to a custom Horizon server such as
    /// a private network or a local development instance.
    ///
    /// - Parameter horizonURL: The base URL of the Horizon server (e.g., "https://horizon.example.com")
    public init(withHorizonUrl horizonURL:String) {
        self.horizonURL = horizonURL

        accounts = AccountService(baseURL: horizonURL)
        assets = AssetsService(baseURL: horizonURL)
        feeStats = FeeStatsService(baseURL: horizonURL)
        effects = EffectsService(baseURL: horizonURL)
        health = HealthService(baseURL: horizonURL)
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

    /// Creates a new SDK instance connected to Stellar's public network.
    ///
    /// - Returns: An SDK instance configured for the public network at https://horizon.stellar.org
    public static func publicNet() -> StellarSDK {
        return StellarSDK(withHorizonUrl: StellarSDK.publicNetUrl)
    }

    /// Creates a new SDK instance connected to Stellar's test network.
    ///
    /// - Returns: An SDK instance configured for the test network at https://horizon-testnet.stellar.org
    public static func testNet() -> StellarSDK {
        return StellarSDK(withHorizonUrl: StellarSDK.testNetUrl)
    }

    /// Creates a new SDK instance connected to Stellar's future network.
    ///
    /// The future network is used for testing upcoming protocol changes before they
    /// are deployed to testnet or the public network.
    ///
    /// - Returns: An SDK instance configured for the future network at https://horizon-futurenet.stellar.org
    public static func futureNet() -> StellarSDK {
        return StellarSDK(withHorizonUrl: StellarSDK.futureNetUrl)
    }
}
