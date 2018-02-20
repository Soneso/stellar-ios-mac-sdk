//
//  EffectsResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class EffectsResponsesMock : ResponsesMock {
    var effectsResponses = [String: String]()
    
    func addEffectsResponse(key: String, response: String) {
        effectsResponses[key] = response
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let assetsResponse = self?.effectsResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return assetsResponse
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/effects?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
