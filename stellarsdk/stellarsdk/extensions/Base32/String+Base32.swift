//
//  String+Base32.swift
//  stellarsdk
//
//  Created by Андрей Катюшин on 16.04.2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension String {
    // base32
    public var base32DecodedData: Data? {
        return base32DecodeToData(self)
    }
    
    public var base32EncodedString: String {
        return utf8CString.withUnsafeBufferPointer {
            base32encode($0.baseAddress!, $0.count - 1, alphabetEncodeTable)
        }
    }
    
    public func base32DecodedString(_ encoding: String.Encoding = .utf8) -> String? {
        return base32DecodedData.flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
    
    // base32Hex
    public var base32HexDecodedData: Data? {
        return base32HexDecodeToData(self)
    }
    
    public var base32HexEncodedString: String {
        return utf8CString.withUnsafeBufferPointer {
            base32encode($0.baseAddress!, $0.count - 1, extendedHexAlphabetEncodeTable)
        }
    }
    
    public func base32HexDecodedString(_ encoding: String.Encoding = .utf8) -> String? {
        return base32HexDecodedData.flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
}
