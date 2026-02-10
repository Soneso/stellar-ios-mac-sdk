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
public class TransactionsStreamItem: @unchecked Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String

    /// Creates a new transaction stream for the specified Horizon API endpoint.
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
    }

    /// Establishes the SSE connection and delivers transaction responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<TransactionResponse>.ResponseClosure) {
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
