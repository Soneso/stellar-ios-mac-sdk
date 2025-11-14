//
//  StreamingHelper.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 17/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Helper class for managing Server-Sent Events streaming from Horizon endpoints.
///
/// This class wraps the `EventSource` implementation to provide a simplified interface
/// for streaming data from Stellar Horizon servers. It handles the connection lifecycle,
/// error states, and message dispatching through a unified response closure.
///
/// The StreamingHelper is used internally by various SDK service classes to enable
/// real-time streaming of ledgers, transactions, operations, effects, and other
/// Horizon resources.
///
/// ## Usage Example
///
/// ```swift
/// let helper = StreamingHelper()
///
/// helper.streamFrom(requestUrl: "https://horizon.stellar.org/ledgers?cursor=now") { response in
///     switch response {
///     case .open:
///         print("Stream connection opened")
///     case .response(let id, let data):
///         print("Received data: \(data)")
///         // Parse JSON data
///     case .error(let error):
///         print("Stream error: \(error)")
///     }
/// }
///
/// // Close when done
/// helper.close()
/// ```
///
/// ## Response Types
///
/// The `responseClosure` receives three types of responses:
///
/// - `.open`: Connection established successfully
/// - `.response(id, data)`: Message received with event ID and JSON data
/// - `.error(error)`: Error occurred during streaming
///
/// See also:
/// - [EventSource] for the underlying SSE implementation
/// - [Stellar developer docs](https://developers.stellar.org)
public class StreamingHelper: NSObject {
    var eventSource: EventSource!
    private var closed = false

    /// Initiates streaming from a Horizon endpoint URL.
    ///
    /// This method creates an EventSource connection to the specified Horizon streaming
    /// endpoint and routes all events through the provided response closure. The closure
    /// will be called on the main thread for connection open, message receipt, and errors.
    ///
    /// - Parameters:
    ///   - requestUrl: The full URL of the Horizon streaming endpoint. Should include
    ///                any query parameters such as cursor position (e.g., `cursor=now`
    ///                for real-time streaming or `cursor=12345` to resume from a specific point).
    ///   - responseClosure: Closure called for all streaming events. Receives a
    ///                     `StreamResponseEnum<String>` which can be:
    ///     - `.open`: Called when the connection is established. Check for HTTP 404
    ///               errors which indicate the resource was not found.
    ///     - `.response(id, data)`: Called for each message received. The `id` parameter
    ///                             contains the event ID for tracking, and `data` contains
    ///                             the JSON response string from Horizon.
    ///     - `.error(error)`: Called when connection or network errors occur. The error
    ///                       may be an `NSError` for system-level issues or a
    ///                       `HorizonRequestError` for Horizon-specific errors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let helper = StreamingHelper()
    ///
    /// helper.streamFrom(
    ///     requestUrl: "https://horizon.stellar.org/transactions?cursor=now"
    /// ) { response in
    ///     switch response {
    ///     case .open:
    ///         print("Streaming transactions...")
    ///     case .response(let id, let data):
    ///         if let jsonData = data.data(using: .utf8),
    ///            let tx = try? JSONDecoder().decode(TransactionResponse.self, from: jsonData) {
    ///             print("Transaction: \(tx.id)")
    ///         }
    ///     case .error(let error):
    ///         print("Error: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The streaming connection remains active until `close()` is called or an
    ///         unrecoverable error occurs. The EventSource will automatically attempt to
    ///         reconnect on transient network failures.
    func streamFrom(requestUrl:String, responseClosure:@escaping StreamResponseEnum<String>.ResponseClosure) {
        eventSource = EventSource(url: requestUrl, headers: ["Accept" : "text/event-stream"])
        eventSource.onOpen { [weak self] httpResponse in
            if httpResponse?.statusCode == 404 {
                let error = HorizonRequestError.notFound(message: "Horizon object missing", horizonErrorResponse: nil)
                responseClosure(.error(error: error))
            } else if let self = self, !self.closed {
                responseClosure(.open)
            }
        }
        
        eventSource.onError { [weak self] error in
            if let self = self, !self.closed {
                responseClosure(.error(error: error))
            }
        }
        
        eventSource.onMessage { [weak self] (id, event, data) in
            if let self = self, !self.closed {
                responseClosure(.response(id: id ?? "", data: data ?? ""))
            }
        }
    }

    /// Closes the streaming connection and releases resources.
    ///
    /// This method terminates the EventSource connection and marks the helper as closed.
    /// After calling this method, no further events will be dispatched to the response
    /// closure, even if messages are still being received.
    ///
    /// - Note: This method is safe to call multiple times. Once closed, a StreamingHelper
    ///         instance should not be reused. Create a new instance to start streaming again.
    func close() {
        closed = true
        if let eventSource = eventSource {
            eventSource.close()
            self.eventSource = nil
        }
    }
}
