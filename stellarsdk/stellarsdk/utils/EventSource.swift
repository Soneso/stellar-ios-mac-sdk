//
//  EventSource.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 17/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// The connection state of an EventSource instance.
///
/// Tracks the lifecycle of the Server-Sent Events connection from initial connection
/// through active streaming to final closure.
public enum EventSourceState {
    /// Initial state when establishing connection to the server.
    case connecting
    /// Connection is established and ready to receive events.
    case open
    /// Connection is closed and no longer receiving events.
    case closed
}

/// Implementation of the W3C Server-Sent Events (SSE) protocol for streaming data from Horizon.
///
/// This class implements a client for the Server-Sent Events protocol, which enables
/// servers to push real-time updates to clients over HTTP. The implementation is used
/// throughout the SDK to stream live data from Stellar Horizon servers, including
/// ledgers, transactions, operations, effects, and account changes.
///
/// ## Protocol Overview
///
/// Server-Sent Events provide a unidirectional channel from server to client over HTTP.
/// The connection remains open, and the server pushes updates as formatted text messages.
/// Key features include:
///
/// - Automatic reconnection with configurable retry intervals
/// - Event identification for resuming from last received message
/// - Named events for routing different message types
/// - Long-lived connections with appropriate timeouts
///
/// ## Usage Example
///
/// ```swift
/// // Stream ledger updates from Horizon
/// let url = "https://horizon.stellar.org/ledgers?cursor=now"
/// let eventSource = EventSource(url: url)
///
/// eventSource.onOpen { response in
///     print("Connection opened, status: \(response?.statusCode ?? 0)")
/// }
///
/// eventSource.onMessage { id, event, data in
///     print("Received message - ID: \(id ?? "none"), Event: \(event ?? "none")")
///     // Parse data as JSON ledger response
///     if let ledgerData = data?.data(using: .utf8) {
///         // Process ledger data
///     }
/// }
///
/// eventSource.onError { error in
///     print("Connection error: \(error?.localizedDescription ?? "unknown")")
/// }
///
/// // Close when done
/// eventSource.close()
/// ```
///
/// ## Event Handlers
///
/// The EventSource supports three types of callbacks:
///
/// - `onOpen`: Called when connection is established
/// - `onMessage`: Called for each message received
/// - `onError`: Called when errors occur
///
/// Additionally, named event listeners can be registered for specific event types:
///
/// ```swift
/// eventSource.addEventListener("ledger-update") { id, event, data in
///     // Handle ledger-specific events
/// }
/// ```
///
/// ## Automatic Reconnection
///
/// The implementation automatically reconnects on connection failures using an
/// exponential backoff strategy. The retry interval can be set by the server
/// using the `retry:` field in the event stream, defaulting to 3000 milliseconds.
///
/// ## Last Event ID
///
/// To support reliable streaming, the last received event ID is persisted and
/// sent with reconnection requests using the `Last-Event-Id` header. This allows
/// the server to resume streaming from where it left off.
///
/// See also:
/// - [W3C Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [StreamingHelper] for simplified Horizon streaming integration
open class EventSource: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    static let DefaultsKey = "com.soneso.eventSource.lastEventId"
    
    let url: URL
    fileprivate let lastEventIDKey: String
    fileprivate let receivedString: String?
    fileprivate var onOpenCallback: ((HTTPURLResponse?) -> Void)?
    fileprivate var onErrorCallback: ((NSError?) -> Void)?
    fileprivate var onMessageCallback: (@Sendable (_ id: String?, _ event: String?, _ data: String?) -> Void)?

    /// Current connection state (connecting, open, or closed) of the Server-Sent Events stream.
    open internal(set) var readyState: EventSourceState
    /// Milliseconds to wait before attempting reconnection after connection failure.
    open fileprivate(set) var retryTime = 3000
    fileprivate var eventListeners = Dictionary<String, @Sendable (_ id: String?, _ event: String?, _ data: String?) -> Void>()
    fileprivate var headers: Dictionary<String, String>
    internal var urlSession: Foundation.URLSession?
    internal var task: URLSessionDataTask?
    fileprivate var operationQueue: OperationQueue
    fileprivate var errorBeforeSetErrorCallBack: NSError?
    internal var receivedDataBuffer: Data
    fileprivate let uniqueIdentifier: String
    fileprivate let validNewlineCharacters = ["\r\n", "\n", "\r"]
    
    var event = Dictionary<String, String>()
    var defaults = Dictionary<String, String>()

    /// Creates a new EventSource instance and establishes connection to the specified URL.
    ///
    /// The initializer creates an EventSource that immediately begins connecting to the
    /// server. Custom headers can be provided for authentication or other purposes.
    ///
    /// - Parameters:
    ///   - url: The URL string of the Server-Sent Events endpoint. Must be a valid URL.
    ///   - headers: Optional dictionary of HTTP headers to include in the request.
    ///                Useful for adding authentication tokens or custom headers.
    ///
    /// - Note: The connection starts automatically after initialization. Use `onOpen`,
    ///         `onMessage`, and `onError` callbacks to handle connection lifecycle events.
    public init(url: String, headers: [String : String] = [:]) {
        
        self.url = URL(string: url)!
        self.headers = headers
        self.readyState = EventSourceState.closed
        self.operationQueue = OperationQueue()
        self.receivedString = nil
        self.receivedDataBuffer = Data()
        
        let port = String(self.url.port ?? 80)
        let relativePath = self.url.relativePath
        let host = self.url.host ?? ""
        let scheme = self.url.scheme ?? ""
        
        self.uniqueIdentifier = "\(scheme).\(host).\(port).\(relativePath)"
        self.lastEventIDKey = "\(EventSource.DefaultsKey).\(self.uniqueIdentifier)"
        
        super.init()
        self.connect()
    }
    
    /// Establishes connection to the Server-Sent Events endpoint.
    func connect() {
        var additionalHeaders = self.headers
        if let eventID = self.lastEventID {
            additionalHeaders["Last-Event-Id"] = eventID
        }
        
        additionalHeaders["Accept"] = "text/event-stream"
        additionalHeaders["Cache-Control"] = "no-cache"
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        configuration.httpAdditionalHeaders = additionalHeaders
        
        self.readyState = EventSourceState.connecting
        self.urlSession = newSession(configuration)
        self.task = urlSession?.dataTask(with: self.url)

        self.resumeSession()
    }

    internal func resumeSession() {
        self.task?.resume()
    }
    
    internal func newSession(_ configuration: URLSessionConfiguration) -> Foundation.URLSession {
        return Foundation.URLSession(configuration: configuration,
                                     delegate: self,
                                     delegateQueue: operationQueue)
    }
    
    /// Closes the Server-Sent Events connection and prevents automatic reconnection.
    open func close() {
        self.readyState = EventSourceState.closed
        self.urlSession?.invalidateAndCancel()
        self.urlSession = nil
    }

    fileprivate func receivedMessageToClose(_ httpResponse: HTTPURLResponse?) -> Bool {
        guard let response = httpResponse  else {
            return false
        }
        
        if response.statusCode == 204 {
            self.close()
            return true
        }
        return false
    }
    
    /// Registers a callback to be invoked when the connection opens.
    ///
    /// The callback is called on the main thread when the Server-Sent Events connection
    /// is successfully established and transitions to the `open` state.
    ///
    /// - Parameter onOpenCallback: Closure called when connection opens.
    ///   - Parameter response: The HTTP response received from the server, or nil if unavailable.
    ///                        Contains status code and headers from the initial connection.
    ///
    /// ## Example
    ///
    /// ```swift
    /// eventSource.onOpen { response in
    ///     if let statusCode = response?.statusCode {
    ///         print("Connected with status: \(statusCode)")
    ///     }
    /// }
    /// ```
    open func onOpen(_ onOpenCallback: @escaping (HTTPURLResponse?) -> Void) {
        self.onOpenCallback = onOpenCallback
    }

    /// Registers a callback to be invoked when an error occurs.
    ///
    /// The callback is called on the main thread when connection errors occur, including
    /// network failures, timeouts, or server errors. If an error occurred before this
    /// callback was registered, it will be immediately invoked with that error.
    ///
    /// - Parameter onErrorCallback: Closure called when errors occur.
    ///   - Parameter error: The NSError describing the failure, or nil if unavailable.
    ///                     Common error codes include network connectivity issues,
    ///                     timeouts, and HTTP errors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// eventSource.onError { error in
    ///     print("Connection error: \(error?.localizedDescription ?? "unknown")")
    ///     // Handle reconnection or cleanup
    /// }
    /// ```
    ///
    /// - Note: The EventSource automatically attempts to reconnect after errors
    ///         unless explicitly closed.
    open func onError(_ onErrorCallback: @escaping (NSError?) -> Void) {
        self.onErrorCallback = onErrorCallback

        if let errorBeforeSet = self.errorBeforeSetErrorCallBack {
            DispatchQueue.main.async {
                self.onErrorCallback?(errorBeforeSet)
            }
            self.errorBeforeSetErrorCallBack = nil
        }
    }

    /// Registers a callback to be invoked when a message is received.
    ///
    /// The callback is called on the main thread for each Server-Sent Event message
    /// received from the server. Messages without an explicit event type are dispatched
    /// to this handler with event type "message".
    ///
    /// - Parameter onMessageCallback: Closure called when messages are received.
    ///   - Parameter id: The event ID from the message, or nil if not specified.
    ///                  Used for tracking and resuming streams.
    ///   - Parameter event: The event type, typically "message" for default events.
    ///   - Parameter data: The message payload as a string. Usually contains JSON data
    ///                    from Horizon that should be parsed by the caller.
    ///
    /// ## Example
    ///
    /// ```swift
    /// eventSource.onMessage { id, event, data in
    ///     guard let jsonData = data?.data(using: .utf8),
    ///           let ledger = try? JSONDecoder().decode(LedgerResponse.self, from: jsonData) else {
    ///         return
    ///     }
    ///     print("Received ledger: \(ledger.sequence)")
    /// }
    /// ```
    open func onMessage(_ onMessageCallback: @escaping @Sendable (_ id: String?, _ event: String?, _ data: String?) -> Void) {
        self.onMessageCallback = onMessageCallback
    }

    /// Registers a handler for messages with a specific event type.
    ///
    /// Allows routing of different event types to specific handlers. The Server-Sent Events
    /// protocol supports named events, enabling the server to send different types of messages
    /// that can be handled separately.
    ///
    /// - Parameters:
    ///   - event: The event type name to listen for. Must match the `event:` field in the
    ///           server's message stream.
    ///   - handler: Closure called when a message with the specified event type is received.
    ///     - Parameter id: The event ID from the message, or nil if not specified.
    ///     - Parameter event: The event type name that was matched.
    ///     - Parameter data: The message payload as a string.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Register handler for specific event types
    /// eventSource.addEventListener("create") { id, event, data in
    ///     print("Create event received")
    /// }
    ///
    /// eventSource.addEventListener("update") { id, event, data in
    ///     print("Update event received")
    /// }
    /// ```
    ///
    /// - Note: Only one handler can be registered per event type. Registering a new handler
    ///         for an event type will replace any existing handler for that type.
    open func addEventListener(_ event: String, handler: @escaping @Sendable (_ id: String?, _ event: String?, _ data: String?) -> Void) {
        self.eventListeners[event] = handler
    }

    /// Removes the handler for a specific event type.
    ///
    /// After removal, messages with the specified event type will no longer be dispatched
    /// to a handler.
    ///
    /// - Parameter event: The event type name to stop listening for.
    open func removeEventListener(_ event: String) -> Void {
        self.eventListeners.removeValue(forKey: event)
    }

    /// Returns an array of all registered event type names.
    ///
    /// - Returns: Array of event type names that currently have registered handlers.
    ///           Does not include the default "message" event type handled by `onMessage`.
    open func events() -> Array<String> {
        return Array(self.eventListeners.keys)
    }

    /// URLSessionDataDelegate method called when data is received from the stream.
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if self.receivedMessageToClose(dataTask.response as? HTTPURLResponse) {
            return
        }
        
        if self.readyState != EventSourceState.open {
            return
        }
        
        self.receivedDataBuffer.append(data)
        let eventStream = extractEventsFromBuffer()
        self.parseEventStream(eventStream)
    }

    /// URLSessionDataDelegate method called when the initial response is received from the server.
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(URLSession.ResponseDisposition.allow)
        
        if self.receivedMessageToClose(dataTask.response as? HTTPURLResponse) {
            return
        }
        
        self.readyState = EventSourceState.open
        DispatchQueue.main.async { [weak self] in
            self?.onOpenCallback?(response as? HTTPURLResponse)
        }
    }

    /// URLSessionDelegate method called when the connection completes or encounters an error.
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.readyState = EventSourceState.closed
        
        if self.receivedMessageToClose(task.response as? HTTPURLResponse) {
            return
        }

        if let nsError = error as NSError?, nsError.code == -999 {
            // User cancelled (-999), don't reconnect
        } else {
            // For all other errors or nil error, attempt reconnection
            let nanoseconds = Double(self.retryTime) / 1000.0 * Double(NSEC_PER_SEC)
            let delayTime = DispatchTime.now() + Double(Int64(nanoseconds)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                self?.close()
                self?.connect()
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            if let errorCallback = self?.onErrorCallback {
                errorCallback(error as NSError?)
            } else {
                self?.errorBeforeSetErrorCallBack = error as NSError?
            }
        }
    }
    
    /// Extracts complete events from the received data buffer.
    fileprivate func extractEventsFromBuffer() -> [String] {
        var events = [String]()

        var searchRange = receivedDataBuffer.startIndex..<receivedDataBuffer.endIndex
        while let foundRange = searchForEventInRange(searchRange) {
            if foundRange.lowerBound > searchRange.lowerBound {
                let dataChunk = receivedDataBuffer[searchRange.lowerBound..<foundRange.lowerBound]

                if let text = String(bytes: dataChunk, encoding: .utf8) {
                    events.append(text)
                }
            }
            let nextStart = foundRange.upperBound
            searchRange = nextStart..<receivedDataBuffer.endIndex
        }

        self.receivedDataBuffer.removeSubrange(receivedDataBuffer.startIndex..<searchRange.lowerBound)

        return events
    }
    
    fileprivate func searchForEventInRange(_ searchRange: Range<Data.Index>) -> Range<Data.Index>? {
        let delimiters = validNewlineCharacters.map { "\($0)\($0)".data(using: String.Encoding.utf8)! }

        for delimiter in delimiters {
            if let range = receivedDataBuffer.range(of: delimiter, options: [], in: searchRange) {
                return range
            }
        }

        return nil
    }
    
    fileprivate func parseEventStream(_ events: [String]) {
        var parsedEvents: [(id: String?, event: String?, data: String?)] = Array()
        
        for event in events {
            if event.isEmpty {
                continue
            }
            
            if event.hasPrefix(":") {
                continue
            }
            
            if event.contains("retry:") {
                if let reconnectTime = parseRetryTime(event) {
                    self.retryTime = reconnectTime
                }
                continue
            }
            
            parsedEvents.append(parseEvent(event))
        }
        
        for parsedEvent in parsedEvents {
            DispatchQueue.main.async { [weak self] in
                self?.lastEventID = parsedEvent.id
            }
              
            if parsedEvent.event == nil {
                if let data = parsedEvent.data, let onMessage = self.onMessageCallback {
                    DispatchQueue.main.async { [weak self] in
                        onMessage(self?.lastEventID, "message", data)
                    }
                }
            }
            
            if let event = parsedEvent.event, let data = parsedEvent.data, let eventHandler = self.eventListeners[event] {
                let handler = eventHandler
                DispatchQueue.main.async { [weak self] in
                    handler(self?.lastEventID, event, data)
                }
            }
        }
    }
    
    internal var lastEventID: String? {
        set {
            if let lastEventID = newValue {
                defaults[lastEventIDKey] = lastEventID
            }
        }
        
        get {
            
            if let lastEventID = defaults[lastEventIDKey] {
                return lastEventID
            }
            return nil
        }
    }
    
    fileprivate func parseEvent(_ eventString: String) -> (id: String?, event: String?, data: String?) {
        var event = Dictionary<String, String>()
        
        for line in eventString.components(separatedBy: CharacterSet.newlines) as [String] {
            autoreleasepool {
                let (k, value) = self.parseKeyValuePair(line)
                guard let key = k else { return }
                
                if let value = value {
                    if event[key] != nil {
                        event[key] = "\(event[key]!)\n\(value)"
                    } else {
                        event[key] = value
                    }
                } else if value == nil {
                    event[key] = ""
                }
            }
        }
        
        return (event["id"], event["event"], event["data"])
    }
    
    fileprivate func parseKeyValuePair(_ line: String) -> (String?, String?) {
        let scanner = Scanner(string: line)
        let key = scanner.scanUpToString(":")
        _ = scanner.scanString(":")

        var value: String?
        for newline in validNewlineCharacters {
            if let scannedValue = scanner.scanUpToString(newline) {
                value = scannedValue
                break
            }
        }

        return (key, value)
    }
    
    fileprivate func parseRetryTime(_ eventString: String) -> Int? {
        var reconnectTime: Int?
        let separators = CharacterSet(charactersIn: ":")
        if let milli = eventString.components(separatedBy: separators).last {
            let milliseconds = trim(milli)
            
            if let intMiliseconds = Int(milliseconds) {
                reconnectTime = intMiliseconds
            }
        }
        return reconnectTime
    }
    
    fileprivate func trim(_ string: String) -> String {
        return string.trimmingCharacters(in: CharacterSet.whitespaces)
    }

    /// Creates an AsyncStream for receiving Server-Sent Events.
    ///
    /// This method provides a modern async/await alternative to the callback-based API.
    /// Use this when you prefer structured concurrency over callbacks.
    ///
    /// - Returns: An AsyncStream that yields tuples of (id, event, data) for each message
    ///
    /// Example:
    /// ```swift
    /// let eventSource = EventSource(url: "https://horizon.stellar.org/ledgers?cursor=now")
    /// let stream = eventSource.eventStream()
    ///
    /// for await (id, event, data) in stream {
    ///     print("Event: \(event ?? "message")")
    ///     if let ledgerData = data?.data(using: .utf8) {
    ///         // Process ledger data
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The stream will continue until the EventSource is closed or an error occurs.
    ///         Only one AsyncStream should be active per EventSource instance.
    open func eventStream() -> AsyncStream<(id: String?, event: String?, data: String?)> {
        AsyncStream { continuation in
            self.onMessage { id, event, data in
                continuation.yield((id: id, event: event, data: data))
            }

            self.onError { error in
                continuation.finish()
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                DispatchQueue.main.async {
                    self?.close()
                }
            }
        }
    }

    /// Generates a Basic Authentication header value from username and password.
    ///
    /// - Parameter username: The username for authentication
    /// - Parameter password: The password for authentication
    /// - Returns: A properly formatted "Basic {base64}" authentication header value
    class open func basicAuth(_ username: String, password: String) -> String {
        let authString = "\(username):\(password)"
        guard let authData = authString.data(using: String.Encoding.utf8) else {
            return "Basic "
        }
        let base64String = authData.base64EncodedString(options: [])

        return "Basic \(base64String)"
    }
}
