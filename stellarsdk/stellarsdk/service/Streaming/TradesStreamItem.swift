import Foundation

/// Streams trade data from the Horizon API using Server-Sent Events (SSE) for real-time updates.
public class TradesStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var requestUrl: String
    private let jsonDecoder = JSONDecoder()

    /// Creates a new trades stream for the specified Horizon API endpoint.
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl

        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }

    /// Establishes the SSE connection and delivers trade responses as they arrive from Horizon.
    public func onReceive(response:@escaping StreamResponseEnum<TradeResponse>.ResponseClosure) {
        streamingHelper.streamFrom(requestUrl:requestUrl) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    guard let trades = try self?.jsonDecoder.decode(TradeResponse.self, from: jsonData) else { return }
                    response(.response(id: id, data: trades))
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
