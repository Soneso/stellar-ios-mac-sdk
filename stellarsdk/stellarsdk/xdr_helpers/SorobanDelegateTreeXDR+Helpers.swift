import Foundation

// MARK: - Delegate descriptor

/// Descriptor for one node in a CAP-71 delegate tree.
///
/// Callers supply an address strkey, an optional pre-built signature (defaults to `.void`),
/// and an optional array of nested delegate descriptors. The SDK converts descriptors into
/// `SorobanDelegateSignatureXDR` values, sorts every array by ascending XDR-byte order,
/// and rejects within-array duplicate addresses.
public struct SorobanDelegateDescriptor {

    /// Stellar address as a strkey (`G…` for account, `C…` for contract).
    public let address: String

    /// Initial signature for this node. Defaults to `.void`.
    ///
    /// Pass `.void` when the node is unsigned at construction time and will be signed
    /// separately. Only pass a non-void value when the signature is known at construction.
    public let signature: SCValXDR

    /// Nested delegate descriptors for this node's `nestedDelegates` array.
    public let nestedDelegates: [SorobanDelegateDescriptor]

    public init(
        address: String,
        signature: SCValXDR = .void,
        nestedDelegates: [SorobanDelegateDescriptor] = []
    ) {
        self.address = address
        self.signature = signature
        self.nestedDelegates = nestedDelegates
    }
}

// MARK: - XDR-byte comparator for SCAddressXDR

/// Compares two `SCAddressXDR` values by the lexicographic order of their complete
/// XDR-encoded bytes.
///
/// CAP-71 requires delegate arrays to be sorted by the full encoded bytes of `SCAddress`,
/// not by strkey string. Strkey order places contract addresses (`C…`) before account
/// addresses (`G…`); XDR encoding places accounts first (discriminant 0) before contracts
/// (discriminant 1), so the orderings differ.
///
/// Returns `true` when `lhs` sorts strictly before `rhs`.
internal func sorobanAddressXDRLessThan(_ lhs: SCAddressXDR, _ rhs: SCAddressXDR) -> Bool {
    guard
        let lhsBytes = try? XDREncoder.encode(lhs),
        let rhsBytes = try? XDREncoder.encode(rhs)
    else {
        // Encoding failure is not expected for well-formed values; treat as equal so
        // the caller detects the situation via the duplicate check rather than silently
        // misordering.
        return false
    }
    return lhsBytes.lexicographicallyPrecedes(rhsBytes)
}

/// Returns `true` when the XDR-encoded bytes of `lhs` and `rhs` are identical.
internal func sorobanAddressXDREqual(_ lhs: SCAddressXDR, _ rhs: SCAddressXDR) -> Bool {
    guard
        let lhsBytes = try? XDREncoder.encode(lhs),
        let rhsBytes = try? XDREncoder.encode(rhs)
    else {
        return false
    }
    return lhsBytes.elementsEqual(rhsBytes)
}

// MARK: - Delegate array sorting and validation

/// Sorts `delegates` ascending by XDR-encoded bytes of each node's `address`, then
/// validates that no two adjacent (i.e. equal-address) nodes exist.
///
/// - Parameter delegates: Array to sort and validate.
/// - Returns: Sorted copy of `delegates`.
/// - Throws: `StellarSDKError.invalidArgument` when two entries share the same XDR-encoded address.
internal func sortAndValidateDelegates(
    _ delegates: [SorobanDelegateSignatureXDR]
) throws -> [SorobanDelegateSignatureXDR] {
    guard delegates.count > 1 else {
        return delegates
    }
    let sorted = delegates.sorted { sorobanAddressXDRLessThan($0.address, $1.address) }
    for i in 1..<sorted.count {
        if sorobanAddressXDREqual(sorted[i - 1].address, sorted[i].address) {
            throw StellarSDKError.invalidArgument(
                message: "Duplicate delegate address within one array: \(sorted[i].address)"
            )
        }
    }
    return sorted
}

// MARK: - Descriptor to XDR conversion

/// Converts a `SorobanDelegateDescriptor` tree into `SorobanDelegateSignatureXDR` values,
/// sorting and validating every delegate array recursively.
///
/// - Parameter descriptor: Root descriptor to convert.
/// - Returns: Converted `SorobanDelegateSignatureXDR`.
/// - Throws: `StellarSDKError.invalidArgument` or `StellarSDKError.encodingError` on failure.
internal func delegateSignatureXDR(
    from descriptor: SorobanDelegateDescriptor
) throws -> SorobanDelegateSignatureXDR {
    let scAddress = try scAddressXDR(fromStrkey: descriptor.address)
    let nested: [SorobanDelegateSignatureXDR] = try descriptor.nestedDelegates.map {
        try delegateSignatureXDR(from: $0)
    }
    let sortedNested = try sortAndValidateDelegates(nested)
    return SorobanDelegateSignatureXDR(
        address: scAddress,
        signature: descriptor.signature,
        nestedDelegates: sortedNested
    )
}

// MARK: - String strkey to SCAddressXDR

/// Converts a strkey to an `SCAddressXDR`.
///
/// Accepts G-address (account) and C-address (contract) strkeys. Throws for other prefixes.
internal func scAddressXDR(fromStrkey strkey: String) throws -> SCAddressXDR {
    if strkey.hasPrefix("G") {
        return try SCAddressXDR(accountId: strkey)
    } else if strkey.hasPrefix("C") {
        return try SCAddressXDR(contractId: strkey)
    }
    throw StellarSDKError.invalidArgument(
        message: "Unsupported strkey prefix for delegate address: \(strkey)"
    )
}

// MARK: - Delegate-tree lookup for signing

/// Depth-first search result indicating whether a matching node was found.
internal enum DelegateLookupResult {
    case notFound
    case found
}

/// Walks the delegate tree depth-first, appending `signature` to every node whose
/// XDR-encoded address matches `targetAddress`.
///
/// - Parameters:
///   - nodes: Delegate array to search (modified in place).
///   - targetAddress: XDR address to match.
///   - signature: Signature element to append.
/// - Returns: `.found` when at least one node matched, `.notFound` otherwise.
@discardableResult
internal func appendSignatureToMatchingDelegates(
    nodes: inout [SorobanDelegateSignatureXDR],
    targetAddress: SCAddressXDR,
    signature: SCValXDR
) -> DelegateLookupResult {
    var anyFound = false
    for i in nodes.indices {
        if sorobanAddressXDREqual(nodes[i].address, targetAddress) {
            nodes[i].appendSignature(signature: signature)
            anyFound = true
        }
        let result = appendSignatureToMatchingDelegates(
            nodes: &nodes[i].nestedDelegates,
            targetAddress: targetAddress,
            signature: signature
        )
        if result == .found {
            anyFound = true
        }
    }
    return anyFound ? .found : .notFound
}
