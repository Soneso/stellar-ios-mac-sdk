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
}
