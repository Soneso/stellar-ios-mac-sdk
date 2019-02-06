//
//  TransactionsStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 17/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum StreamResponseEnum<Data:Decodable> {
    case open
    case response(id:String, data:Data)
    case error(error:Error?)
    
    public typealias ResponseClosure = (_ response:StreamResponseEnum<Data>) -> (Void)
}


public class TransactionsStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var subpath: String
    private let jsonDecoder = JSONDecoder()
    
    public init(baseURL:String, subpath:String) {
        streamingHelper = StreamingHelper(baseURL: baseURL)
        self.subpath = subpath
        
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    public func onReceive(response:@escaping StreamResponseEnum<TransactionResponse>.ResponseClosure) {
        streamingHelper.streamFrom(path:subpath) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    guard let transactions = try self?.jsonDecoder.decode(TransactionResponse.self, from: jsonData) else { return }
                    response(.response(id: id, data: transactions))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let transactionSubpath = self?.subpath ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with path \(transactionSubpath): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    public func closeStream() {
        streamingHelper.close()
    }
}
