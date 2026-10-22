//
//  ContractAddressGuard.swift
//  stellarsdk
//
//  Created by Soneso on 22.10.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// The host rule for contract addresses, checked before any decoding or request: an entry that
/// takes a contract refuses every other address kind, and a contract data key holds no muxed
/// address.
internal enum ContractAddressGuard {

    /// The text refusing `contractId` where an entry takes only a contract, opening with
    /// `subject` and naming the kind of address given; nil for a "C..." strkey and for the 64
    /// character hex of the 32 byte id, the strings `SCAddressXDR(contractId:)` reads. A secret
    /// seed is never echoed; any other string of no known kind is echoed through `XdrJson.preview(_:)`.
    internal static func contractIdRefusal(_ contractId: String, subject: String) -> String? {
        let isHexId = contractId.count == 2 * StellarProtocolConstants.SHA256_HASH_SIZE
            && contractId.allSatisfy { $0.isASCII && $0.isHexDigit }
        if contractId.isValidContractId() || isHexId {
            return nil
        }
        let refusal = "\(subject) must be a contract (C...) address"
        if contractId.isValidEd25519SecretSeed() {
            return "\(refusal), got a secret seed (S...) instead of an address"
        }
        guard let kind = kindName(ofStrKey: contractId) else {
            return "\(refusal): \(XdrJson.preview(contractId))"
        }
        let hint = contractId.isValidMuxedContractId() ? "; use its base contract (C...) address" : ""
        return "\(refusal), got \(kind) address: \(contractId)\(hint)"
    }

    /// The kind of address `strKey` is, with its article as refusal texts name it, e.g.
    /// "a muxed contract (W...)"; nil for a contract (C...) strkey and for any other string.
    private static func kindName(ofStrKey strKey: String) -> String? {
        if strKey.isValidEd25519PublicKey() { return "an account (G...)" }
        if strKey.isValidMed25519PublicKey() { return "a muxed account (M...)" }
        if strKey.isValidMuxedContractId() { return "a muxed contract (W...)" }
        if strKey.isValidClaimableBalanceId() { return "a claimable balance (B...)" }
        if strKey.isValidLiquidityPoolId() { return "a liquidity pool (L...)" }
        return nil
    }

    /// True when `value` is a muxed account (M...) or muxed contract (W...) address or holds one
    /// in a vector or map entry at any depth; the host refuses such a value in a contract data key.
    internal static func containsMuxedAddress(_ value: SCValXDR) -> Bool {
        switch value {
        case .address(.muxedAccount), .address(.muxedContract):
            return true
        case .vec(let values):
            return values?.contains { containsMuxedAddress($0) } ?? false
        case .map(let entries):
            return entries?.contains { containsMuxedAddress($0.key) || containsMuxedAddress($0.val) } ?? false
        default:
            return false
        }
    }
}
