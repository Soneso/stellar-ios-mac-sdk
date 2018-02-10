//
//  Dictionary+HTTPParams.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// - returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String? {
        let parameterArray = map { key, value -> String in
            guard let key = key as? String else { return "" }
            guard let value = value as? String else { return "" }
            return "\(key)=\(value)"
        }
        return parameterArray.filter{$0.count > 0}.joined(separator: "&").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
}
