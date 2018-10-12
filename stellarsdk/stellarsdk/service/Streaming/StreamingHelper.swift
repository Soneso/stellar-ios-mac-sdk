//
//  StreamingHelper.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 17/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class StreamingHelper: NSObject {
    var eventSource: EventSource!
    var baseURL: String
    
    private var closed = false
    
    init(baseURL:String) {
        self.baseURL = baseURL
    }
    
    func streamFrom(path:String, responseClosure:@escaping StreamResponseEnum<String>.ResponseClosure) {
        let streamingURL = baseURL + path
        eventSource = EventSource(url: streamingURL, headers: ["Accept" : "text/event-stream"])
        eventSource.onOpen {
            if !self.closed {
                responseClosure(.open)
            }
        }
        
        eventSource.onError { (error) in
            if !self.closed {
                responseClosure(.error(error: error))
            }
        }
        
        eventSource.onMessage { (id, event, data) in
            if !self.closed {
                responseClosure(.response(id: id ?? "", data: data ?? ""))
            }
        }
        
    }
    
    func close() {
        closed = true
        if let eventSource = eventSource {
            eventSource.close()
            self.eventSource = nil
        }
    }
    
}
