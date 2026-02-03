//
//  AssetsResponsesMock.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class AssetsResponsesMock : ResponsesMock {
    var assetsResponses = [String: String]()
    
    func addAssetsResponse(key: String, assetsResponse: String) {
        assetsResponses[key] = assetsResponse
    }
    
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let assetsResponse = self?.assetsResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }
            
            return assetsResponse
        }
        
        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/assets?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
