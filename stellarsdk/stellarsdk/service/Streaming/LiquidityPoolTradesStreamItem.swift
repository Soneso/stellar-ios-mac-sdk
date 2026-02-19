//
//  LiquidityPoolTradesStreamItem.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.01.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Streams liquidity pool trade data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
///
/// This stream provides live updates for trades involving a specific liquidity pool, delivering new trade
/// events as they occur on the Stellar network. Each update contains complete trade details including
/// traded assets, amounts, prices, and participating accounts or liquidity pools.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
/// let poolId = "L..." // Liquidity pool ID (L-address or hex format)
/// let tradesStream = sdk.liquidityPools.streamTrades(forPoolId: poolId)
///
/// tradesStream.onReceive { response in
///     switch response {
///     case .open:
///         print("Stream connection established")
///     case .response(id: let id, data: let trade):
///         print("Trade received - Type: \(trade.tradeType)")
///         print("Base: \(trade.baseAmount) \(trade.baseAssetCode ?? "XLM")")
///         print("Counter: \(trade.counterAmount) \(trade.counterAssetCode ?? "XLM")")
///         print("Price: \(trade.price.n)/\(trade.price.d)")
///     case .error(let error):
///         print("Stream error: \(error)")
///     }
/// }
///
/// // Close stream when done
/// tradesStream.closeStream()
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TradeResponse for the trade data structure
/// - LiquidityPoolsService for related liquidity pool operations
public final class LiquidityPoolTradesStreamItem: Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String

    /// Creates a new liquidity pool trades stream for the specified Horizon API endpoint.
    ///
    /// - Parameter requestUrl: The complete Horizon API URL for streaming liquidity pool trades
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
    }

    /// Establishes the SSE connection and delivers trade responses as they arrive from Horizon.
    ///
    /// The response closure is called multiple times:
    /// - Once with .open when the connection is established
    /// - Each time with .response when a new trade is received
    /// - With .error if any error occurs during streaming
    ///
    /// - Parameter response: Closure called with stream events. Called on a background thread.
    public func onReceive(response:@escaping StreamResponseEnum<TradeResponse>.ResponseClosure) {
        streamingHelper.streamFrom(requestUrl:requestUrl) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    guard let jsonData = data.data(using: .utf8) else {
                        response(.error(error: HorizonRequestError.parsingResponseFailed(message: "Failed to convert response data to UTF8")))
                        return
                    }
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
                    let trade = try jsonDecoder.decode(TradeResponse.self, from: jsonData)
                    response(.response(id: id, data: trade))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let tradesUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(tradesUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }

    /// Closes the event stream and releases resources.
    ///
    /// Call this method when you no longer need to receive trade updates for the liquidity pool.
    /// After closing, the stream cannot be reopened - create a new LiquidityPoolTradesStreamItem instead.
    public func closeStream() {
        streamingHelper.close()
    }

}
