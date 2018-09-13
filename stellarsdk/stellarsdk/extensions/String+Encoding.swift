//
//  String+Encoding.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 21/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public extension String {
    var urlEncoded: String? {
        var allowedQueryParamAndKey = NSMutableCharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey)
    }
    
    var urlDecoded: String? {
        return self.removingPercentEncoding
    }
    
    var isFullyQualifiedDomainName: Bool {
        let sRegex = "(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-).)+[a-zA-Z]{2,63}.?$)"
        return NSPredicate(format: "SELF MATCHES[c] %@", sRegex).evaluate(with: self)
    }
}
