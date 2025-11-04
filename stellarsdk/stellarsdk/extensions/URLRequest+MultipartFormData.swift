//
//  URLRequest+MultipartFormData.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing multipart form data support for URLRequest.
extension URLRequest {

    /// Configures the URL request for multipart/form-data encoding.
    ///
    /// Sets the request's httpBody and Content-Type header for multipart form data submission.
    /// This is commonly used for file uploads and form submissions that include binary data.
    ///
    /// - Parameter parameters: Dictionary of form field names to data values
    /// - Parameter encoding: Text encoding to use for field names
    /// - Throws: EncodingError if field names cannot be encoded properly
    ///
    /// Example:
    /// ```swift
    /// var request = URLRequest(url: uploadURL)
    /// request.httpMethod = "POST"
    /// try request.setMultipartFormData([
    ///     "file": fileData,
    ///     "description": descriptionData
    /// ], encoding: .utf8)
    /// ```
    ///
    /// - Note: Remember to set httpMethod to POST before sending the request.
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

/// Error that occurs when encoding multipart form data fails.
struct EncodingError: Error {
    /// Description of what failed to encode (e.g., "charset", "name").
    let what: String
}
