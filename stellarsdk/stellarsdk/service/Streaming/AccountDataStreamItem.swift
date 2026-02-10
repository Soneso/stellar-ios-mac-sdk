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
public class AccountDataStreamItem: @unchecked Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String

    /// Creates a new account data stream for the specified Horizon API endpoint.
    ///
    /// - Parameter requestUrl: The complete Horizon API URL for streaming the account data entry
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
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
