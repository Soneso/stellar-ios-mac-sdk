//
//  String+Base32.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public extension String {
    public var base32EncodedString: String? {
        get {
            if let data = (self as NSString).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                return Base32Encode(data: data)
            } else {
                return nil
            }
        }
    }
    
    public var base32DecodedData: Data? {
        get {
            return Base32Decode(data: self)
        }
    }
    
    func base32DecodedString(encoding: String.Encoding = String.Encoding.utf8) -> String? {
        if let data = self.base32DecodedData {
            return String(data: data, encoding: encoding)
        } else {
            return nil
        }
    }
}

