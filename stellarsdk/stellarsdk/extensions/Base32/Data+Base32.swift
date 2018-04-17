//
//  Data+Base32.swift
//  stellarsdk
//
//  Created by Андрей Катюшин on 16.04.2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension Data {
    // base32
    public var base32EncodedString: String {
        return base32Encode(self)
    }
    
    public var base32EncodedData: Data {
        return base32EncodedString.dataUsingUTF8StringEncoding
    }
    
    public var base32DecodedData: Data? {
        return String(data: self, encoding: .utf8).flatMap(base32DecodeToData)
    }
    
    // base32Hex
    public var base32HexEncodedString: String {
        return base32HexEncode(self)
    }
    
    public var base32HexEncodedData: Data {
        return base32HexEncodedString.dataUsingUTF8StringEncoding
    }
    
    public var base32HexDecodedData: Data? {
        return String(data: self, encoding: .utf8).flatMap(base32HexDecodeToData)
    }
}
