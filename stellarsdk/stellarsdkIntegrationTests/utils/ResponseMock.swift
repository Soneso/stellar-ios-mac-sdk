//
//  ResponseMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

// Workaround for the issues described here: https://github.com/kylef/Mockingjay/issues/32
extension InputStream {
    func readfully() -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        
        open()
        
        var amount = 0
        repeat {
            amount = read(&buffer, maxLength: buffer.count)
            if amount > 0 {
                result.append(buffer, count: amount)
            }
        } while amount > 0
        
        close()
        
        return result
    }
}

class ResponsesMock {
    
    init() {
        ServerMock.add(mock: requestMock())
    }

    deinit {
        ServerMock.removeAll()
    }
    
    /// override this
    func requestMock() -> RequestMock {
        
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/path/${variable}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
    
    func resourceMissingResponse() -> String {
        return """
        {
            "type": "https://stellar.org/horizon-errors/not_found",
            "title": "Resource Missing",
            "status": 404,
            "detail": "The resource at the url requested was not found.  This is usually occurs for one of two reasons:  The url requested is not valid, or no data in our databas could be found with the parameters provided.",
            "instance": "horizon-testnet-001/6VNfUsVQkZ-28076890"
        }
        """
    }
}
