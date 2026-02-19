import Foundation

/// Streams offer data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
public final class OffersStreamItem: Sendable {
    private let streamingHelper: StreamingHelper
    private let requestUrl: String

    /// Creates a new offers stream for the specified Horizon API endpoint.
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
    }

    init(requestUrl: String, streamingHelper: StreamingHelper) {
        self.streamingHelper = streamingHelper
        self.requestUrl = requestUrl
    }

    /// Establishes the SSE connection and delivers offer responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<OfferResponse>.ResponseClosure) {
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
                    let offers = try jsonDecoder.decode(OfferResponse.self, from: jsonData)
                    response(.response(id: id, data: offers))
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
