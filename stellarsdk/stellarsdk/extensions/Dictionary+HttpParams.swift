//
//  Dictionary+HTTPParams.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing HTTP query parameter conversion for Dictionary.
extension Dictionary {

    /// Builds a URL query string from dictionary key-value pairs.
    ///
    /// Converts a dictionary into a URL-encoded query string in the format "key1=value1&key2=value2".
    /// Percent encodes values in compliance with RFC 3986.
    ///
    /// - Returns: URL-encoded query string, or nil if conversion fails
    ///
    /// Example:
    /// ```swift
    /// let params = ["limit": "10", "order": "desc"]
    /// let query = params.stringFromHttpParameters() // "limit=10&order=desc"
    /// ```
    ///
    /// See: [RFC 3986](http://www.ietf.org/rfc/rfc3986.txt) for URL encoding specification.
    func stringFromHttpParameters() -> String? {
        let parameterArray = map { key, value -> String in
            guard let key = key as? String else { return "" }
            guard let value = value as? String else { return "" }
            return "\(key)=\(value)"
        }
        return parameterArray.filter{$0.count > 0}.joined(separator: "&").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
}
