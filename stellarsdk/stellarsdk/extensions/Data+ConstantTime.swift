//
//  Data+ConstantTime.swift
//  stellarsdk
//
//  Copyright © Soneso. All rights reserved.
//

import Foundation

/// Extension providing constant-time byte comparison for `Data`.
///
/// Constant-time comparison is important wherever byte sequences represent secret material
/// such as cryptographic keys, signatures, or authentication codes. A naive equality check
/// may return early on the first differing byte, leaking information about how many leading
/// bytes match through measurable differences in execution time.
public extension Data {

    /// Compares two byte sequences in constant time.
    ///
    /// Always inspects every byte of both sequences regardless of where the first mismatch
    /// occurs, preventing an attacker from inferring partial match length by measuring
    /// execution time. The length-difference indicator is stored as a Boolean flag (0 or 1)
    /// rather than a narrowed XOR of the lengths, keeping the implementation trap-free for
    /// any input sizes and avoiding the edge case where two different-length inputs could
    /// produce a zero-difference accumulator through integer overflow truncation.
    ///
    /// - Parameter other: The byte sequence to compare against.
    /// - Returns: `true` when both sequences have identical length and byte contents.
    func constantTimeEquals(_ other: Data) -> Bool {
        var diff: UInt8 = (self.count == other.count) ? 0 : 1
        let length = Swift.min(self.count, other.count)
        let aStart = self.startIndex
        let bStart = other.startIndex
        for i in 0..<length {
            diff |= self[aStart + i] ^ other[bStart + i]
        }
        return diff == 0
    }
}
