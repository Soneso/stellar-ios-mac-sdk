import Foundation

public class OffersStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var requestUrl: String
    private let jsonDecoder = JSONDecoder()
    
    public init(requestUrl:String) {
        streamingHelper = StreamingHelper()
        self.requestUrl = requestUrl
        
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    public func onReceive(response:@escaping StreamResponseEnum<OfferResponse>.ResponseClosure) {
        streamingHelper.streamFrom(requestUrl:requestUrl) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    guard let offers = try self?.jsonDecoder.decode(OfferResponse.self, from: jsonData) else { return }
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
    
    public func closeStream() {
        streamingHelper.close()
    }
}
