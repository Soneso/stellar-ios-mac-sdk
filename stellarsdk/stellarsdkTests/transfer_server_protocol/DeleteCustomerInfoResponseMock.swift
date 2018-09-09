//
//  DeleteCustomerInfoResponseMock.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

class DeleteCustomerInfoResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            if mock.variables["variable"] == "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI" {
                mock.statusCode = 200
            } else if mock.variables["variable"] == "GBTMF7Y4S7S3ZMYLIU5MLVEECJETO7FYIZ5OH3GBDD7W3Z4A6556RTMC" {
                mock.statusCode = 401
            } else if mock.variables["variable"] == "GBYLNNAUUJQ7YJSGIATU432IJP2QYTTPKIY5AFWT7LFZAIT76QYVLTAG" {
                mock.statusCode = 404
            }
            
            return nil
        }
        
        return RequestMock(host: address,
                           path: "/customer/${variable}",
                           httpMethod: "DELETE",
                           mockHandler: handler)
    }
}
