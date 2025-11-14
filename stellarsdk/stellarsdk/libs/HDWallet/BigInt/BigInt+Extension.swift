//
//  BigInt+Extension.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/01/24.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

import Foundation

extension BInt {

    /// Converts the big integer to binary data representation.
    ///
    /// Encodes the big integer as big-endian bytes. Used in BIP-32 key derivation
    /// to convert derived key factors into binary format.
    ///
    /// - Returns: Big-endian byte representation of the integer
    var data: Data {
        let count = limbs.count
        var data = Data(count: count * 8)
        data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) -> Void in
            var p = pointer
            for i in (0..<count).reversed() {
                for j in (0..<8).reversed() {
                    p.pointee = UInt8((limbs[i] >> UInt64(j * 8)) & 0xff)
                    p += 1
                }
            }
        }
        
        return data
    }

    /// Creates a big integer from a hexadecimal string.
    ///
    /// - Parameter hex: A hexadecimal string (without "0x" prefix)
    ///
    /// - Returns: A BInt if the hex string is valid, nil otherwise
    init?(hex: String) {
        self.init(number: hex.lowercased(), withBase: 16)
    }

    /// Creates a big integer from binary data.
    ///
    /// Interprets the data as a big-endian unsigned integer. Used in BIP-32 key
    /// derivation to convert HMAC output into big integer form for cryptographic operations.
    ///
    /// - Parameter data: Binary data to interpret as a big-endian integer
    init(data: Data) {
        let n = data.count
        guard n > 0 else {
            self.init(0)
            return
        }
        
        let m = (n + 7) / 8
        var limbs = Limbs(repeating: 0, count: m)
        data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Void in
            var p = ptr
            let r = n % 8
            let k = r == 0 ? 8 : r
            for j in (0..<k).reversed() {
                limbs[m - 1] += UInt64(p.pointee) << UInt64(j * 8)
                p += 1
            }
            guard m > 1 else { return }
            for i in (0..<(m - 1)).reversed() {
                for j in (0..<8).reversed() {
                    limbs[i] += UInt64(p.pointee) << UInt64(j * 8)
                    p += 1
                }
            }
        }
        
        self.init(limbs: limbs)
    }
}
