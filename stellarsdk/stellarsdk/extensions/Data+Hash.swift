//
//  Data+Hash.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 19/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

#if XC9
import CSwiftyCommonCrypto
#else
import CommonCrypto
#endif

import Foundation

/// Extension providing SHA-256 hashing functionality for strings.
public extension String {
    /// Computes the SHA-256 hash of the string.
    ///
    /// Converts the string to UTF-8 data and computes its SHA-256 hash using CommonCrypto.
    ///
    /// Example:
    /// ```swift
    /// let message = "Hello, Stellar!"
    /// let hash = message.sha256Hash
    /// ```
    var sha256Hash: Data {
        get {
             let data = self.data(using: .utf8)!
             var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

             _ = digest.withUnsafeMutableBytes { (digestBytes) in
                 data.withUnsafeBytes { (stringBytes) in
                 CC_SHA256(stringBytes, CC_LONG(data.count), digestBytes)
             }
         }
         return digest
         }
     }
}

