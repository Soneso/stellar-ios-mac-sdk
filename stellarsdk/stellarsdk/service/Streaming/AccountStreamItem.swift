//
//  AccountStreamItem.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.01.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Streams account data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
///
/// This stream provides live updates for a single account, delivering changes as they occur on the
/// Stellar network. Each update contains the complete current state of the account including balances,
/// signers, thresholds, and other account properties.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
/// let accountStream = sdk.accounts.streamAccount(accountId: "GACCOUNT...")
///
/// accountStream.onReceive { response in
///     switch response {
///     case .open:
///         print("Stream connection established")
///     case .response(id: let id, data: let account):
///         print("Account update received - Sequence: \(account.sequenceNumber)")
///         for balance in account.balances {
///             print("\(balance.assetCode ?? "XLM"): \(balance.balance)")
///         }
///     case .error(let error):
///         print("Stream error: \(error)")
///     }
/// }
///
/// // Close stream when done
/// accountStream.closeStream()
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountResponse for the account data structure
public class AccountStreamItem: @unchecked Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String

    /// Creates a new account stream for the specified Horizon API endpoint.
    ///
    /// - Parameter requestUrl: The complete Horizon API URL for streaming the account
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    /// Establishes the SSE connection and delivers account responses as they arrive from Horizon.
    ///
    /// The response closure is called multiple times:
    /// - Once with .open when the connection is established
    /// - Each time with .response when an account update is received
    /// - With .error if any error occurs during streaming
    ///
    /// - Parameter response: Closure called with stream events. Called on a background thread.
    public func onReceive(response:@escaping StreamResponseEnum<AccountResponse>.ResponseClosure) {
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
                    let account = try jsonDecoder.decode(AccountResponse.self, from: jsonData)
                    response(.response(id: id, data: account))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let accountUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(accountUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }

    /// Closes the event stream and releases resources.
    ///
    /// Call this method when you no longer need to receive updates for the account.
    /// After closing, the stream cannot be reopened - create a new AccountStreamItem instead.
    public func closeStream() {
        streamingHelper.close()
    }

}
