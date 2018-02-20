//
//  Data+Base32.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public extension Data {
    public var base32EncodedString: String? {
        get {
            return Base32Encode(data: self)
        }
    }
    
    func base32DecodedString(encoding: String.Encoding = String.Encoding.utf8) -> String? {
        return String(data: self, encoding: encoding)
    }
}
