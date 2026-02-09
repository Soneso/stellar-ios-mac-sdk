//
//  Sep30MultipleSignersResponseMock.swift
//  stellarsdk
//
//  Created by Soneso on 06.02.26.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep30MultipleSignersResponseMock: ResponsesMock {
    var host: String
    var address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "owner", "authenticated": true },
        { "role": "sender" },
        { "role": "receiver" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" },
        { "key": "GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY" },
        { "key": "GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN" }
      ]
    }
    """
}
