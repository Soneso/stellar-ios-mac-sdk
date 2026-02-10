//
//  EffectsStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 23/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Streams effect data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
public class EffectsStreamItem: @unchecked Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String
    let effectsFactory = EffectsFactory()

    /// Creates a new effects stream for the specified Horizon API endpoint.
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
    }

    /// Establishes the SSE connection and delivers effect responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<EffectResponse>.ResponseClosure) {
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
                    guard let effects = try self?.effectsFactory.effectFromData(data: jsonData) else { return }
                    response(.response(id: id, data: effects))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let effectUrl = self?.requestUrl ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with url \(effectUrl): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    /// Closes the event stream and releases resources.
    public func closeStream() {
        streamingHelper.close()
    }
}
