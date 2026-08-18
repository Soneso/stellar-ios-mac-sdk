//
//  TransactionsStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 17/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the possible responses from a Server-Sent Events (SSE) stream connection.
public enum StreamResponseEnum<Data:Decodable>: Sendable where Data: Sendable {
    /// Stream connection established successfully.
    case open
    /// Data received from the stream with an event ID and decoded payload.
    case response(id:String, data:Data)
    /// Error occurred during streaming.
    case error(error:Error?)

    /// Closure type for handling stream responses.
    public typealias ResponseClosure = @Sendable (_ response:StreamResponseEnum<Data>) -> (Void)
}

/// Streams transaction data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
public final class TransactionsStreamItem: Sendable {
    private let streamingHelper: StreamingHelper
    let requestUrl: String
    /// The error every receiver is given instead of a connection. Nil on a stream that has
    /// an endpoint to connect to.
    private let failure: HorizonRequestError?

    /// Creates a new transaction stream for the specified Horizon API endpoint.
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
    /// for a request that names no endpoint Horizon serves.
    init(failure: HorizonRequestError) {
        self.streamingHelper = StreamingHelper()
        self.requestUrl = ""
        self.failure = failure
    }

    /// Establishes the SSE connection and delivers transaction responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<TransactionResponse>.ResponseClosure) {
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
                    let transactions = try jsonDecoder.decode(TransactionResponse.self, from: jsonData)
                    response(.response(id: id, data: transactions))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let transactionUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(transactionUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    /// Closes the event stream and releases resources.
    public func closeStream() {
        streamingHelper.close()
    }
}
