//
//  Data+Hash.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 19/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import CommonCrypto

/// Extension providing SHA-256 hashing functionality for strings.
public extension String {
    /// Computes the SHA-256 hash of the string.
    var sha256Hash: Data {
        let data = self.data(using: .utf8)!
        return data.sha256Hash
    }
}

/// Extension providing SHA-256 hashing functionality for Data.
public extension Data {
    /// Computes the SHA-256 hash of the data.
    var sha256Hash: Data {
        var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = digest.withUnsafeMutableBytes { digestBytes in
            self.withUnsafeBytes { dataBytes in
                CC_SHA256(dataBytes.baseAddress, CC_LONG(self.count), digestBytes.baseAddress?.assumingMemoryBound(to: UInt8.self))
            }
        }
        return digest
    }
}

