//
//  AccountDataStreamItem.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.01.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Streams account data entry updates from the Horizon API using Server-Sent Events (SSE) for real-time updates.
///
/// This stream provides live updates for a specific data entry (key-value pair) on an account.
/// Each update contains the current base64-encoded value for the specified key as it changes on the
/// Stellar network.
///
/// Accounts can store arbitrary key-value pairs (up to 64 bytes per value) using the ManageDataOperation.
/// This stream allows you to monitor changes to a specific key in real-time.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
/// let dataStream = sdk.accounts.streamAccountData(
///     accountId: "GACCOUNT...",
///     key: "user_settings"
/// )
///
/// dataStream.onReceive { response in
///     switch response {
///     case .open:
///         print("Stream connection established")
///     case .response(id: let id, data: let dataEntry):
///         // Decode base64 value
///         if let decoded = Data(base64Encoded: dataEntry.value) {
///             let value = String(data: decoded, encoding: .utf8) ?? ""
///             print("Data updated - Value: \(value)")
///         }
///     case .error(let error):
///         print("Stream error: \(error)")
///     }
/// }
///
/// // Close stream when done
/// dataStream.closeStream()
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - DataForAccountResponse for the data entry structure
/// - ManageDataOperation for setting account data
public final class AccountDataStreamItem: Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String
    /// The error every receiver is given instead of a connection. Nil on a stream that has
    /// an endpoint to connect to.
    private let failure: HorizonRequestError?

    /// Creates a new account data stream for the specified Horizon API endpoint.
    ///
    /// - Parameter requestUrl: The complete Horizon API URL for streaming the account data entry
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
        self.failure = nil
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
        self.failure = nil
    }

    /// Creates a stream that opens no connection and hands `failure` to every receiver,
    /// for a request the SDK refuses before it is sent.
    init(failure: HorizonRequestError) {
        self.streamingHelper = StreamingHelper()
        self.requestUrl = ""
        self.failure = failure
    }

    /// Establishes the SSE connection and delivers data entry responses as they arrive from Horizon.
    ///
    /// The response closure is called multiple times:
    /// - Once with .open when the connection is established
    /// - Each time with .response when the data entry is updated
    /// - With .error if any error occurs during streaming
    ///
    /// - Parameter response: Closure called with stream events. Called on a background thread.
    public func onReceive(response:@escaping StreamResponseEnum<DataForAccountResponse>.ResponseClosure) {
        if let failure = failure {
            // The SSE callbacks reach a receiver on the main queue. Handing the stored error
            // over the same way keeps a receiver that answers an error by opening another
            // stream from recursing into this call.
            DispatchQueue.main.async {
                response(.error(error: failure))
            }
            return
        }
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
                    let accountData = try jsonDecoder.decode(DataForAccountResponse.self, from: jsonData)
                    response(.response(id: id, data: accountData))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let dataUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(dataUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }

    /// Closes the event stream and releases resources.
    ///
    /// Call this method when you no longer need to receive updates for the account data entry.
    /// After closing, the stream cannot be reopened - create a new AccountDataStreamItem instead.
    public func closeStream() {
        streamingHelper.close()
    }

}
