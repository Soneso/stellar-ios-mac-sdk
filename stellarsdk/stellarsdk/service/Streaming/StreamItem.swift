//
//  TransactionsStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 17/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum StreamResponseEnum<Data:Decodable> {
    case open
    case response(id:String, data:Data)
    case error(error:Error?)
    
    public typealias ResponseClosure = (_ response:StreamResponseEnum<Data>) -> (Void)
}


public class StreamItem<Response:Decodable>: NSObject {
    private var streamingHelper: StreamingHelper
    private var subpath: String
    private let jsonDecoder = JSONDecoder()
    
    public init(baseURL:String, subpath:String) {
        streamingHelper = StreamingHelper(baseURL: baseURL)
        self.subpath = subpath
        
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    public func onReceive(response:@escaping StreamResponseEnum<Response>.ResponseClosure) {
        streamingHelper.streamFrom(path:subpath) { (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    let transactions = try self.jsonDecoder.decode(Response.self, from: jsonData)
                    response(.response(id: id, data: transactions))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                response(.error(error: HorizonRequestError.parsingResponseFailed(message: error?.localizedDescription ?? "Something went wrong")))
            }
        }
    }
    
}
