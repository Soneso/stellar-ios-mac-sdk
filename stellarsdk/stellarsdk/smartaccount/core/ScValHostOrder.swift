//
//  ScValHostOrder.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Orders two `SCValXDR` ScMap keys the way the Soroban host does.
///
/// The host stores and validates ScMap keys in a semantic order and rejects a map whose
/// keys are not in that order when it materializes the map from an `SCVal` contract
/// argument. Sorting by the XDR-encoded key bytes instead is length-major — the four-byte
/// length prefix of a variable-length payload is compared before its content — which
/// diverges from the host whenever two keys' variable-length fields differ in length, and
/// the host then rejects the map with `InvalidInput`.
///
/// Ordering:
/// - Values of different types compare by their `SCValType` discriminant.
/// - `Vec` compares element-wise (recursively); the shorter vec sorts first on a prefix tie.
/// - `Map` compares entry-wise (key, then value, recursively); the map with fewer entries
///   sorts first on a prefix tie.
/// - `Bytes`, `String`, and `Symbol` compare by content, byte for byte (unsigned); the
///   shorter value sorts first on a prefix tie (length is the tiebreaker, never the primary
///   key).
/// - All remaining values compare by their XDR encoding. For the fixed-width types that can
///   appear in smart-account map keys (addresses, unsigned scalars) this equals a content
///   comparison. Signed integer scalars would compare by their two's-complement bytes rather
///   than numerically; they cannot appear as smart-account map keys.
///
/// - Parameters:
///   - a: The first value to compare.
///   - b: The second value to compare.
/// - Returns: A negative value when `a` sorts before `b`, zero when the two values are
///   equal under the host order, and a positive value when `a` sorts after `b`.
internal func compareScValHostOrder(_ a: SCValXDR, _ b: SCValXDR) -> Int {
    let typeA = a.type()
    let typeB = b.type()
    if typeA != typeB {
        return typeA < typeB ? -1 : 1
    }

    switch (a, b) {
    case (.vec(let optionalElementsA), .vec(let optionalElementsB)):
        let elementsA = optionalElementsA ?? []
        let elementsB = optionalElementsB ?? []
        let shared = min(elementsA.count, elementsB.count)
        for i in 0..<shared {
            let cmp = compareScValHostOrder(elementsA[i], elementsB[i])
            if cmp != 0 { return cmp }
        }
        return compareInts(elementsA.count, elementsB.count)
    case (.map(let optionalEntriesA), .map(let optionalEntriesB)):
        let entriesA = optionalEntriesA ?? []
        let entriesB = optionalEntriesB ?? []
        let shared = min(entriesA.count, entriesB.count)
        for i in 0..<shared {
            let keyCmp = compareScValHostOrder(entriesA[i].key, entriesB[i].key)
            if keyCmp != 0 { return keyCmp }
            let valCmp = compareScValHostOrder(entriesA[i].val, entriesB[i].val)
            if valCmp != 0 { return valCmp }
        }
        return compareInts(entriesA.count, entriesB.count)
    case (.bytes(let bytesA), .bytes(let bytesB)):
        return compareBytesUnsigned([UInt8](bytesA), [UInt8](bytesB))
    case (.string(let stringA), .string(let stringB)):
        return compareBytesUnsigned([UInt8](stringA.utf8), [UInt8](stringB.utf8))
    case (.symbol(let symbolA), .symbol(let symbolB)):
        return compareBytesUnsigned([UInt8](symbolA.utf8), [UInt8](symbolB.utf8))
    default:
        return compareBytesUnsigned(scValToXdrBytesForOrder(a), scValToXdrBytesForOrder(b))
    }
}

/// Compares two byte arrays element-wise as unsigned bytes; on a prefix tie the shorter
/// array is smaller. This matches the Soroban host's ordering of `Bytes`/`String`/`Symbol`
/// content (Rust slice `Ord`).
private func compareBytesUnsigned(_ a: [UInt8], _ b: [UInt8]) -> Int {
    let shared = min(a.count, b.count)
    for i in 0..<shared {
        if a[i] != b[i] {
            return a[i] < b[i] ? -1 : 1
        }
    }
    return compareInts(a.count, b.count)
}

/// Three-way integer comparison: negative, zero, or positive as `a` is less than, equal
/// to, or greater than `b`.
private func compareInts(_ a: Int, _ b: Int) -> Int {
    if a == b { return 0 }
    return a < b ? -1 : 1
}

/// Encodes a value to its raw XDR bytes for the fixed-width fallback comparison.
private func scValToXdrBytesForOrder(_ value: SCValXDR) -> [UInt8] {
    do {
        return try XDREncoder.encode(value)
    } catch {
        // why: every `SCValXDR` is serializable by construction, so a failure here
        // signals a malformed value produced upstream. Trap rather than return empty
        // bytes, which would collapse distinct values onto equal sort keys.
        preconditionFailure("SCValXDR encoding must not fail: \(error)")
    }
}
