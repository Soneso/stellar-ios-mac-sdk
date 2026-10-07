//
//  ScValHostOrder.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Orders two `SCValXDR` values the way the Soroban host orders ScMap keys.
///
/// The host stores and validates ScMap keys in this order and rejects a contract argument
/// map whose keys are out of order with `InvalidInput`.
///
/// Ordering (rs-soroban-env `Compare<ScVal>`):
/// - Values of different types compare by their `SCValType` discriminant.
/// - `I32`, `I64` and `LedgerKeyNonce` compare numerically as signed values; `I128` and
///   `I256` compare the signed high part first, then the unsigned lower parts.
/// - `Vec` compares element-wise (recursively); the shorter vec sorts first on a prefix tie.
/// - `Map` compares entry-wise (key, then value, recursively); the map with fewer entries
///   sorts first on a prefix tie.
/// - `Bytes`, `String`, `Symbol`, and `ExecutableTag` compare by content, byte for byte
///   (unsigned); the shorter value sorts first on a prefix tie.
/// - `ContractInstance` compares by executable (type, then payload; an external reference by
///   owner, then tag content), then by storage; absent storage sorts first.
/// - All remaining types (`Bool`, `Void`, `Error`, the unsigned integers, `Timepoint`,
///   `Duration`, `Address`, `LedgerKeyContractInstance`) consist of non-negative big-endian
///   fields in XDR field order, so their XDR encodings compare in host order.
///
/// - Parameters:
///   - a: The first value to compare.
///   - b: The second value to compare.
/// - Returns: A negative value when `a` sorts before `b`, zero when the two values are
///   equal under the host order, and a positive value when `a` sorts after `b`.
public func compareScValHostOrder(_ a: SCValXDR, _ b: SCValXDR) -> Int {
    let typeA = a.type()
    let typeB = b.type()
    if typeA != typeB {
        return typeA < typeB ? -1 : 1
    }

    switch (a, b) {
    case (.i32(let valueA), .i32(let valueB)):
        return compareValues(valueA, valueB)
    case (.i64(let valueA), .i64(let valueB)):
        return compareValues(valueA, valueB)
    case (.i128(let partsA), .i128(let partsB)):
        return firstNonZero(compareValues(partsA.hi, partsB.hi), compareValues(partsA.lo, partsB.lo))
    case (.i256(let partsA), .i256(let partsB)):
        return firstNonZero(
            compareValues(partsA.hiHi, partsB.hiHi),
            compareValues(partsA.hiLo, partsB.hiLo),
            compareValues(partsA.loHi, partsB.loHi),
            compareValues(partsA.loLo, partsB.loLo)
        )
    case (.ledgerKeyNonce(let nonceA), .ledgerKeyNonce(let nonceB)):
        return compareValues(nonceA.nonce, nonceB.nonce)
    case (.vec(let optionalElementsA), .vec(let optionalElementsB)):
        let elementsA = optionalElementsA ?? []
        let elementsB = optionalElementsB ?? []
        let shared = min(elementsA.count, elementsB.count)
        for i in 0..<shared {
            let cmp = compareScValHostOrder(elementsA[i], elementsB[i])
            if cmp != 0 { return cmp }
        }
        return compareValues(elementsA.count, elementsB.count)
    case (.map(let optionalEntriesA), .map(let optionalEntriesB)):
        return compareMapEntries(optionalEntriesA ?? [], optionalEntriesB ?? [])
    case (.bytes(let bytesA), .bytes(let bytesB)):
        return compareBytesUnsigned([UInt8](bytesA), [UInt8](bytesB))
    case (.string(let stringA), .string(let stringB)):
        return compareBytesUnsigned([UInt8](stringA.utf8), [UInt8](stringB.utf8))
    case (.symbol(let symbolA), .symbol(let symbolB)):
        return compareBytesUnsigned([UInt8](symbolA.utf8), [UInt8](symbolB.utf8))
    case (.executableTag(let tagA), .executableTag(let tagB)):
        return compareBytesUnsigned([UInt8](tagA), [UInt8](tagB))
    case (.contractInstance(let instanceA), .contractInstance(let instanceB)):
        let executableCmp = compareExecutables(instanceA.executable, instanceB.executable)
        if executableCmp != 0 { return executableCmp }
        switch (instanceA.storage, instanceB.storage) {
        case (nil, nil):
            return 0
        case (nil, _):
            return -1
        case (_, nil):
            return 1
        case (let storageA?, let storageB?):
            return compareMapEntries(storageA, storageB)
        }
    default:
        return compareBytesUnsigned(xdrBytesForOrder(a), xdrBytesForOrder(b))
    }
}

extension SCValXDR {

    /// Builds an `SCV_MAP` value whose entries are sorted by key into the Soroban host's
    /// ScMap key order (see `compareScValHostOrder`).
    ///
    /// Use this builder to sort caller-supplied entries and reject duplicate keys. Decoding
    /// XDR preserves map order.
    ///
    /// - Parameter entries: Map entries in any order.
    /// - Returns: An `SCV_MAP` value with the entries in ascending host key order.
    /// - Throws: `StellarSDKError.invalidArgument` when two keys are equal under the host
    ///   order.
    public static func sortedMap(_ entries: [SCMapEntryXDR]) throws -> SCValXDR {
        let sorted = entries.sorted { compareScValHostOrder($0.key, $1.key) < 0 }
        for (previous, next) in zip(sorted, sorted.dropFirst())
        where compareScValHostOrder(previous.key, next.key) == 0 {
            let key = (try? next.key.toXdrJson()) ?? String(describing: next.key)
            throw StellarSDKError.invalidArgument(message: "Duplicate ScMap key: \(key)")
        }
        return .map(sorted)
    }
}

/// Compares two ScMap entry lists entry-wise (key, then value); on a prefix tie the list
/// with fewer entries is smaller.
private func compareMapEntries(_ a: [SCMapEntryXDR], _ b: [SCMapEntryXDR]) -> Int {
    let shared = min(a.count, b.count)
    for i in 0..<shared {
        let keyCmp = compareScValHostOrder(a[i].key, b[i].key)
        if keyCmp != 0 { return keyCmp }
        let valCmp = compareScValHostOrder(a[i].val, b[i].val)
        if valCmp != 0 { return valCmp }
    }
    return compareValues(a.count, b.count)
}

/// Compares two contract executables by type, then payload. An external reference compares
/// by owner address, then by tag content; the other payloads are fixed-width, so their XDR
/// encodings compare in host order.
private func compareExecutables(_ a: ContractExecutableXDR, _ b: ContractExecutableXDR) -> Int {
    if case .externalRef(let refA) = a, case .externalRef(let refB) = b {
        return firstNonZero(
            compareBytesUnsigned(xdrBytesForOrder(refA.executableOwner), xdrBytesForOrder(refB.executableOwner)),
            compareBytesUnsigned([UInt8](refA.tag), [UInt8](refB.tag))
        )
    }
    return compareBytesUnsigned(xdrBytesForOrder(a), xdrBytesForOrder(b))
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
    return compareValues(a.count, b.count)
}

/// Three-way comparison: negative, zero, or positive as `a` is less than, equal to, or
/// greater than `b`.
private func compareValues<T: Comparable>(_ a: T, _ b: T) -> Int {
    if a == b { return 0 }
    return a < b ? -1 : 1
}

/// The first non-zero result of a field-by-field comparison, or zero when all fields are
/// equal.
private func firstNonZero(_ comparisons: Int...) -> Int {
    return comparisons.first { $0 != 0 } ?? 0
}

/// Encodes a value to its raw XDR bytes for the fixed-width fallback comparison.
private func xdrBytesForOrder(_ value: XDREncodable) -> [UInt8] {
    do {
        return try XDREncoder.encode(value)
    } catch {
        // Encoding failure indicates a malformed value. Comparison requires the complete
        // encoded bytes.
        preconditionFailure("XDR encoding must not fail: \(error)")
    }
}
