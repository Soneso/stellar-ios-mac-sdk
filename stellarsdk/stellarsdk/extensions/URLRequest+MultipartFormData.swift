//
//  URLRequest+MultipartFormData.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension URLRequest {
    
    /**
     Configures the URL request for `multipart/form-data`. The request's `httpBody` is set, and a value is set for the HTTP header field `Content-Type`.
     
     - Parameter parameters: The form data to set.
     - Parameter encoding: The encoding to use for the keys and values.
     
     - Throws: `EncodingError` if any keys or values in `parameters` are not entirely in `encoding`.
     
     - Note: The default `httpMethod` is `GET`, and `GET` requests do not typically have a response body. Remember to set the `httpMethod` to e.g. `POST` before sending the request.
     */
    mutating func setMultipartFormData(_ parameters: [String: Data], encoding: String.Encoding) throws {
        let boundary = String(format: "------------------------%08X%08X", arc4random(), arc4random())
        
        let contentType: String = try {
            guard let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)) else {
                throw EncodingError(what: "charset")
            }
            return "multipart/form-data; charset=\(charset); boundary=\(boundary)"
            }()
        addValue(contentType, forHTTPHeaderField: "Content-Type")
        
        httpBody = try {
            var body = Data()
            
            for (rawName, rawValue) in parameters {
                if !body.isEmpty {
                    body.append("\r\n".data(using: .utf8)!)
                }
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                
                guard
                    rawName.canBeConverted(to: encoding),
                    let disposition = "Content-Disposition: form-data; name=\"\(rawName)\"\r\n".data(using: .utf8) else {
                        throw EncodingError(what: "name")
                }
                body.append(disposition)
                body.append("\r\n".data(using: .utf8)!)
                body.append(rawValue)
            }
            
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            return body
            }()
    }
}

struct EncodingError: Error {
    let what: String
}
