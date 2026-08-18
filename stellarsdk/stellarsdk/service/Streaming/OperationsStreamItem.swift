//
//  OperationsStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 23/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Streams operation data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
public final class OperationsStreamItem: Sendable {
    private let streamingHelper: StreamingHelper
    let requestUrl: String
    /// The error every receiver is given instead of a connection. Nil on a stream that has
    /// an endpoint to connect to.
    private let failure: HorizonRequestError?
    let operationsFactory = OperationsFactory()

    /// Creates a new operations stream for the specified Horizon API endpoint.
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

    /// Establishes the SSE connection and delivers operation responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<OperationResponse>.ResponseClosure) {
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
                    guard let operation = try self?.operationsFactory.operationFromData(data: jsonData) else { return }
                    response(.response(id: id, data: operation))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let operationUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(operationUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    /// Closes the event stream and releases resources.
    public func closeStream() {
        streamingHelper.close()
    }
}
