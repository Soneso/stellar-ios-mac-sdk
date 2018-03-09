//
//  LedgersStreamItem.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 23/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class LedgersStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var subpath: String
    private let jsonDecoder = JSONDecoder()
    
    public init(baseURL:String, subpath:String) {
        streamingHelper = StreamingHelper(baseURL: baseURL)
        self.subpath = subpath
        
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    public func onReceive(response:@escaping StreamResponseEnum<LedgerResponse>.ResponseClosure) {
        streamingHelper.streamFrom(path:subpath) { (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    let ledgers = try self.jsonDecoder.decode(LedgerResponse.self, from: jsonData)
                    response(.response(id: id, data: ledgers))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with path \(self.subpath): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
}

