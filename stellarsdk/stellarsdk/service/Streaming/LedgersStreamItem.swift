//
//  LedgersStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 23/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Streams ledger data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
public class LedgersStreamItem: @unchecked Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String

    /// Creates a new ledgers stream for the specified Horizon API endpoint.
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
    }

    /// Establishes the SSE connection and delivers ledger responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<LedgerResponse>.ResponseClosure) {
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
                    let ledgers = try jsonDecoder.decode(LedgerResponse.self, from: jsonData)
                    response(.response(id: id, data: ledgers))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let ledgerUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(ledgerUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    /// Closes the event stream and releases resources.
    public func closeStream() {
        streamingHelper.close()
    }
    
}

