//
//  Sep30SingleIdentityResponseMock.swift
//  stellarsdk
//
//  Created by Soneso on 06.02.26.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

class Sep30SingleIdentityResponseMock: ResponsesMock {
    var host: String
    var address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // Body received - no debug output
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "owner" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
}
