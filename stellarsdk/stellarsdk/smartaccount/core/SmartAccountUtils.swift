//
//  SmartAccountUtils.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import CommonCrypto

/// Cryptographic helpers for smart-account operations.
///
/// Provides utilities for WebAuthn signature processing, public-key extraction, and
/// contract-address derivation. All members operate on raw byte material and do not
/// depend on any platform-specific WebAuthn API.
public enum SmartAccountUtils {

    /// Parses a DER-encoded secp256r1 signature and returns its `(r, s)` components as
    /// stripped, unsigned big-endian byte arrays (each at most 32 bytes, in `[1, n-1]`).
    ///
    /// - Parameter derSignature: DER-encoded signature bytes.
    /// - Returns: `(r, s)` pair after stripping leading zero-padding.
    /// - Throws: `ValidationException.InvalidInput` when the DER structure is malformed
    ///           or `r`/`s` violate secp256r1 constraints.
    internal static func parseDerSignature(_ derSignature: Data) throws -> (r: Data, s: Data) {
        if derSignature.count < 8 || derSignature[derSignature.startIndex] != 0x30 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format"
            )
        }

        // Validate the total length field: byte 1 encodes the length of the remaining
        // contents, so the full signature must be exactly 2 + totalLength bytes.
        let totalLength = Int(derSignature[derSignature.startIndex + 1]) & 0xFF
        if 2 + totalLength != derSignature.count {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format: declared length does not match actual size"
            )
        }

        var offset = 2
        if offset + 1 >= derSignature.count
            || derSignature[derSignature.startIndex + offset] != 0x02
        {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format: missing r component marker"
            )
        }

        let rLength = Int(derSignature[derSignature.startIndex + offset + 1]) & 0xFF
        if rLength == 0 || offset + 2 + rLength > derSignature.count {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format: truncated r component"
            )
        }

        var r = derSignature.subdata(
            in: (derSignature.startIndex + offset + 2)..<(derSignature.startIndex + offset + 2 + rLength)
        )
        while r.count > 1 && r[r.startIndex] == 0x00 {
            r = r.subdata(in: (r.startIndex + 1)..<r.endIndex)
        }

        offset = offset + 2 + rLength
        if offset + 1 >= derSignature.count
            || derSignature[derSignature.startIndex + offset] != 0x02
        {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format: missing s component marker"
            )
        }

        let sLength = Int(derSignature[derSignature.startIndex + offset + 1]) & 0xFF
        if sLength == 0 || offset + 2 + sLength > derSignature.count {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format: truncated s component"
            )
        }

        var s = derSignature.subdata(
            in: (derSignature.startIndex + offset + 2)..<(derSignature.startIndex + offset + 2 + sLength)
        )
        while s.count > 1 && s[s.startIndex] == 0x00 {
            s = s.subdata(in: (s.startIndex + 1)..<s.endIndex)
        }

        let endOffset = offset + 2 + sLength
        if endOffset != derSignature.count {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature format: trailing bytes after s component"
            )
        }

        if r.count > 32 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature: r component exceeds 32 bytes after stripping (\(r.count) bytes)"
            )
        }
        if s.count > 32 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature: s component exceeds 32 bytes after stripping (\(s.count) bytes)"
            )
        }

        if r.count == 1 && r[r.startIndex] == 0x00 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature: r component is zero (invalid ECDSA value)"
            )
        }
        if s.count == 1 && s[s.startIndex] == 0x00 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature: s component is zero (invalid ECDSA value)"
            )
        }

        if compareUnsignedBigEndian(r, curveOrderBytes) >= 0 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature: r component exceeds curve order"
            )
        }
        if compareUnsignedBigEndian(s, curveOrderBytes) >= 0 {
            throw ValidationException.invalidInput(
                field: "derSignature",
                reason: "Invalid DER signature: s component exceeds curve order"
            )
        }

        return (r, s)
    }

    /// Normalises a DER-encoded secp256r1 signature to compact format with low-S
    /// normalisation.
    ///
    /// Steps:
    /// 1. Parse the DER format via `parseDerSignature`.
    /// 2. Normalise `s` to its low-S form (`s = n - s`) when `s > n/2`.
    /// 3. Pad both `r` and `s` to exactly 32 bytes.
    /// 4. Return concatenated `r || s` (64 bytes total).
    ///
    /// Low-S normalisation ensures that signatures with `s` values greater than half the
    /// curve order are converted to their complement, which the Stellar/Soroban verifier
    /// requires.
    ///
    /// - Parameter derSignature: DER-encoded signature bytes.
    /// - Returns: 64-byte compact signature `r || s`.
    /// - Throws: `ValidationException.InvalidInput` when the DER format is invalid.
    public static func normalizeSignature(_ derSignature: Data) throws -> Data {
        let parsed = try parseDerSignature(derSignature)
        let r = parsed.r
        var s = parsed.s

        // If `s > halfOrder`, normalise: `s = n - s`.
        if compareUnsignedBigEndian(s, halfCurveOrderBytes) > 0 {
            s = subtractUnsignedBigEndian(curveOrderBytes, s)
        }

        let rPadded = leftPadUnsignedBigEndian(r, length: 32)
        let sPadded = leftPadUnsignedBigEndian(s, length: 32)

        var result = Data(capacity: 64)
        result.append(rPadded)
        result.append(sPadded)
        return result
    }

    /// Extracts the secp256r1 public key from a WebAuthn registration response.
    ///
    /// Tries `publicKey`, `authenticatorData`, and `attestationObject` in order; at least
    /// one must be non-nil. Compressed keys (`0x02`/`0x03` prefix) throw immediately.
    ///
    /// - Parameters:
    ///   - publicKey: Optional direct public key bytes (last 65 bytes used when longer,
    ///                handling COSE/SPKI-wrapped keys).
    ///   - authenticatorData: Optional raw authenticator data from registration.
    ///   - attestationObject: Optional raw attestation object from registration.
    /// - Returns: 65-byte uncompressed public key (`0x04` prefix + `X` + `Y`).
    /// - Throws: `ValidationException.InvalidInput` when a compressed key is detected,
    ///           when no source is provided, or when all strategies fail.
    public static func extractPublicKeyFromRegistration(
        publicKey: Data? = nil,
        authenticatorData: Data? = nil,
        attestationObject: Data? = nil
    ) throws -> Data {
        // Strategy 1: try direct public key.
        if let publicKey = publicKey, !publicKey.isEmpty {
            let candidate: Data
            if publicKey.count > SmartAccountConstants.secp256r1PublicKeySize {
                candidate = publicKey.suffix(SmartAccountConstants.secp256r1PublicKeySize)
            } else {
                candidate = publicKey
            }

            // Route the 0x04-prefixed case through extractPublicKeyFromSpki, which checks
            // that the last 65 bytes start with 0x04 — identical to the previous
            // suffix(65)-plus-0x04-check, making extractPublicKeyFromSpki live.
            if let spkiKey = WebAuthnCborParser.extractPublicKeyFromSpki(publicKey) {
                let xRange = (spkiKey.startIndex + 1)..<(spkiKey.startIndex + 33)
                let yRange = (spkiKey.startIndex + 33)..<(spkiKey.startIndex + 65)
                try validatePointOnCurve(
                    x: spkiKey.subdata(in: xRange),
                    y: spkiKey.subdata(in: yRange)
                )
                return Data(spkiKey)
            }

            // Compressed point formats (0x02 even-Y, 0x03 odd-Y) are not supported. Soroban
            // expects uncompressed keys and WebAuthn platforms must provide them. Throw
            // immediately rather than silently fall through to other strategies.
            let firstByte = candidate[candidate.startIndex]
            if firstByte == 0x02 || firstByte == 0x03 {
                let prefixHex = String(format: "%02x", firstByte)
                throw ValidationException.invalidInput(
                    field: "publicKey",
                    reason: "Compressed secp256r1 key format (prefix 0x\(prefixHex)) is not supported; the platform must provide an uncompressed key (0x04 prefix)"
                )
            }
            // Non-key data (for example CBOR/attestation bytes) falls through to the next
            // strategy.
        }

        // Strategy 2: try authenticator data parsing.
        if let authenticatorData = authenticatorData {
            if let extracted = try extractPublicKeyFromAuthenticatorData(authenticatorData) {
                return extracted
            }
        }

        // Strategy 3: try attestation object pattern matching.
        if let attestationObject = attestationObject {
            return try extractPublicKeyFromAttestationObject(attestationObject)
        }

        throw ValidationException.invalidInput(
            field: "registration",
            reason: "Could not extract public key from attestation response: no valid publicKey, authenticatorData, or attestationObject provided"
        )
    }

    /// Extracts the secp256r1 public key from WebAuthn authenticator data.
    ///
    /// Parses the attested credential data structure defined by the WebAuthn specification
    /// to locate and extract the COSE public key. Structural decisions (prefix presence,
    /// buffer length) are made here; X/Y parsing is delegated to `WebAuthnCborParser`
    /// and curve validation is applied to the result.
    ///
    /// Authenticator data layout:
    /// ```
    /// [0..31]   rpIdHash          (32 bytes)
    /// [32]      flags             (1 byte)
    /// [33..36]  signCount         (4 bytes, big-endian)
    /// [37..52]  aaguid            (16 bytes) -- if AT flag set
    /// [53..54]  credentialIdLen   (2 bytes, big-endian) -- if AT flag set
    /// [55..55+N-1] credentialId   (N bytes) -- if AT flag set
    /// [55+N..]  COSE public key   (variable) -- if AT flag set
    /// ```
    ///
    /// Disposition:
    /// - Returns `nil` when the data is too short, the AT flag is absent, the COSE prefix
    ///   does not match, or the buffer is too short for a complete key (allowing the caller
    ///   to fall through to the next source).
    /// - Throws `ValidationException.InvalidInput` when the COSE prefix is present, the
    ///   buffer is long enough for a complete key, but the parsed structure is malformed
    ///   (e.g. corrupted Y-coordinate separator) or the extracted point is not on the
    ///   secp256r1 curve.
    internal static func extractPublicKeyFromAuthenticatorData(
        _ authenticatorData: Data
    ) throws -> Data? {
        // Gate 1: minimum fixed header size (rpIdHash + flags + signCount + aaguid + credIdLen).
        if authenticatorData.count < 55 {
            return nil
        }

        let start = authenticatorData.startIndex

        // Gate 2: check the AT (attested credential data) flag (bit 6 of the flags byte).
        let flags = Int(authenticatorData[start + 32]) & 0xFF
        if flags & 0x40 == 0 {
            return nil
        }

        // Read credential ID length from bytes 53-54 (big-endian uint16).
        let credentialIdLength =
            (Int(authenticatorData[start + 53]) & 0xFF) << 8
            | (Int(authenticatorData[start + 54]) & 0xFF)

        // COSE key starts at offset 55 + credentialIdLength.
        let coseKeyStart = 55 + credentialIdLength

        // Gate 3: ensure the 10-byte COSE prefix is in range before inspecting it.
        if authenticatorData.count < coseKeyStart + 10 {
            return nil
        }

        // Gate 4: verify the 10-byte ES256 COSE prefix. The prefix
        // [0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20] encodes the CBOR
        // map header and the kty, alg, and crv parameters for an ES256 P-256 key.
        let expectedCosePrefix: [UInt8] = [
            0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20
        ]
        let actualPrefix = authenticatorData.subdata(
            in: (start + coseKeyStart)..<(start + coseKeyStart + 10)
        )
        if !actualPrefix.elementsEqual(expectedCosePrefix) {
            return nil
        }

        // Gate 5: full-key length check. Returns nil (not throw) so the public method falls
        // through to the attestation-object strategy when the buffer is truncated after the
        // prefix but before the complete key.
        let fullKeyRequiredLength = coseKeyStart + 10 + 32 + 3 + 32
        if authenticatorData.count < fullKeyRequiredLength {
            return nil
        }

        // All structural gates passed — delegate parsing to WebAuthnCborParser. The parser
        // handles both CBOR map-iteration (order-tolerant) and pattern-matching fallback
        // (strict: validates the [0x22, 0x58, 0x20] Y-coordinate separator).
        let coseKeySlice = authenticatorData.subdata(in: (start + coseKeyStart)..<authenticatorData.endIndex)
        guard let key = WebAuthnCborParser.extractPublicKeyFromCoseKey(coseKeySlice) else {
            // Prefix and length are both valid, but the parser could not extract coordinates
            // (e.g. corrupted separator). Treat as malformed rather than falling through.
            throw ValidationException.invalidInput(
                field: "authenticatorData",
                reason: "COSE key structure is invalid: could not extract secp256r1 coordinates from authenticator data"
            )
        }

        let x = key.subdata(in: (key.startIndex + 1)..<(key.startIndex + 33))
        let y = key.subdata(in: (key.startIndex + 33)..<(key.startIndex + 65))
        try validatePointOnCurve(x: x, y: y)
        return key
    }

    /// Extracts the secp256r1 public key from a raw WebAuthn attestation object.
    ///
    /// Probes for the 10-byte ES256 COSE prefix to confirm the key is present, then
    /// delegates parsing to `WebAuthnCborParser` and applies curve validation to the
    /// result.
    ///
    /// - Parameter attestationObject: Raw attestation object bytes.
    /// - Returns: 65-byte uncompressed public key.
    /// - Throws: `ValidationException.InvalidInput` when the COSE prefix is not found,
    ///           the parsed structure is malformed, or the extracted point is not on the
    ///           secp256r1 curve.
    internal static func extractPublicKeyFromAttestationObject(
        _ attestationObject: Data
    ) throws -> Data {
        let prefix = Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        let prefixIndex = findSubarray(array: attestationObject, subarray: prefix)
        if prefixIndex < 0 {
            throw ValidationException.invalidInput(
                field: "attestationObject",
                reason: "COSE key prefix not found in attestation"
            )
        }

        // Prefix is present; delegate full parsing to WebAuthnCborParser. The parser's
        // pattern-matching fallback locates the prefix and strictly validates the
        // [0x22, 0x58, 0x20] Y-coordinate separator.
        guard let key = WebAuthnCborParser.extractPublicKeyFromCoseKey(attestationObject) else {
            throw ValidationException.invalidInput(
                field: "attestationObject",
                reason: "COSE key structure is malformed: could not extract secp256r1 coordinates from attestation object"
            )
        }

        let x = key.subdata(in: (key.startIndex + 1)..<(key.startIndex + 33))
        let y = key.subdata(in: (key.startIndex + 33)..<(key.startIndex + 65))
        try validatePointOnCurve(x: x, y: y)
        return key
    }

    /// Computes the contract salt from a WebAuthn credential ID.
    ///
    /// The salt is used during contract-address derivation so each credential ID maps to a
    /// unique smart-account contract address. The salt is the SHA-256 hash of the
    /// credential ID.
    ///
    /// - Parameter credentialId: WebAuthn credential ID.
    /// - Returns: 32-byte SHA-256 digest of the credential ID.
    public static func getContractSalt(credentialId: Data) -> Data {
        return credentialId.sha256Hash
    }

    /// Derives the smart-account contract address from a credential ID and deployer.
    ///
    /// Computes the deterministic contract address that will be created when deploying a
    /// smart-account contract with the given credential ID from the specified deployer
    /// account on the specified network.
    ///
    /// Algorithm:
    /// ```
    /// salt = SHA-256(credentialId)
    /// deployerAddress = SCAddress::Account(deployerPublicKey)
    /// networkId = SHA-256(networkPassphrase as UTF-8)
    /// preimage = HashIDPreimage::ContractID {
    ///   networkId,
    ///   contractIDPreimage: ContractIDPreimage::FromAddress {
    ///     address: deployerAddress, salt: Uint256(salt)
    ///   }
    /// }
    /// contractIdBytes = SHA-256(XDR_encode(preimage))
    /// contractId = StrKey.encodeContractId(contractIdBytes)
    /// ```
    ///
    /// - Parameters:
    ///   - credentialId: WebAuthn credential ID used to generate the salt.
    ///   - deployerPublicKey: Stellar account ID (`G…` strkey) of the deployer.
    ///   - networkPassphrase: Network passphrase.
    /// - Returns: Contract address as a `C…` strkey.
    /// - Throws: `ValidationException.InvalidAddress` when the deployer key is invalid,
    ///           `ValidationException.InvalidInput` when contract-ID encoding fails, or
    ///           `TransactionException.SigningFailed` when XDR encoding fails.
    public static func deriveContractAddress(
        credentialId: Data,
        deployerPublicKey: String,
        networkPassphrase: String
    ) throws -> String {
        let contractSalt = getContractSalt(credentialId: credentialId)

        let deployerAddress: SCAddressXDR
        do {
            deployerAddress = try SCAddressXDR(accountId: deployerPublicKey)
        } catch {
            throw ValidationException.invalidAddress(
                address: deployerPublicKey,
                cause: error
            )
        }

        let networkIdBytes = networkPassphrase.sha256Hash

        let fromAddress = ContractIDPreimageFromAddressXDR(
            address: deployerAddress,
            salt: Uint256XDR(contractSalt)
        )
        let contractIdPreimage = ContractIDPreimageXDR.fromAddress(fromAddress)
        let hashIdPreimageContractId = HashIDPreimageContractIDXDR(
            networkID: HashXDR(networkIdBytes),
            contractIDPreimage: contractIdPreimage
        )
        let preimage = HashIDPreimageXDR.contractID(hashIdPreimageContractId)

        let encodedPreimage: Data
        do {
            encodedPreimage = Data(try XDREncoder.encode(preimage))
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to XDR encode contract ID preimage",
                cause: error
            )
        }

        let contractIdBytes = encodedPreimage.sha256Hash

        do {
            return try contractIdBytes.encodeContractId()
        } catch {
            throw ValidationException.invalidInput(
                field: "contractId",
                reason: "Failed to encode contract ID: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Finds the first occurrence of `subarray` within `array` using a sliding-window scan.
    ///
    /// Returns `-1` when not found, when `subarray` is empty, or when `array` is shorter
    /// than `subarray`. Exposed as `internal` so tests can exercise it directly.
    ///
    /// - Parameters:
    ///   - array: Bytes to search in.
    ///   - subarray: Bytes to search for.
    /// - Returns: Index of the first match, or `-1` when not found.
    internal static func findSubarray(array: Data, subarray: Data) -> Int {
        if subarray.isEmpty || array.count < subarray.count {
            return -1
        }
        let arrayStart = array.startIndex
        let subStart = subarray.startIndex
        let maxStart = array.count - subarray.count
        for i in 0...maxStart {
            var found = true
            for j in 0..<subarray.count {
                if array[arrayStart + i + j] != subarray[subStart + j] {
                    found = false
                    break
                }
            }
            if found {
                return i
            }
        }
        return -1
    }

    /// secp256r1 curve order `n` as a 32-byte unsigned big-endian integer.
    /// Hex: ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551.
    fileprivate static let curveOrderBytes = Data([
        0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84,
        0xF3, 0xB9, 0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x51
    ])

    /// Half of the secp256r1 curve order, used for low-S normalisation.
    /// Hex: 7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a8.
    fileprivate static let halfCurveOrderBytes = Data([
        0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0x00, 0x00, 0x00,
        0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xDE, 0x73, 0x7D, 0x56, 0xD3, 0x8B, 0xCF, 0x42,
        0x79, 0xDC, 0xE5, 0x61, 0x7E, 0x31, 0x92, 0xA8
    ])

    /// secp256r1 field prime `p` (FIPS 186-4 / SEC 2).
    /// Hex: ffffffff00000001000000000000000000000000ffffffffffffffffffffffff.
    fileprivate static let curvePBytes = Data([
        0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    ])

    /// secp256r1 curve coefficient `a = p - 3`.
    /// Hex: ffffffff00000001000000000000000000000000fffffffffffffffffffffffc.
    fileprivate static let curveABytes = Data([
        0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFC
    ])

    /// secp256r1 curve coefficient `b`.
    /// Hex: 5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b.
    fileprivate static let curveBBytes = Data([
        0x5A, 0xC6, 0x35, 0xD8, 0xAA, 0x3A, 0x93, 0xE7,
        0xB3, 0xEB, 0xBD, 0x55, 0x76, 0x98, 0x86, 0xBC,
        0x65, 0x1D, 0x06, 0xB0, 0xCC, 0x53, 0xB0, 0xF6,
        0x3B, 0xCE, 0x3C, 0x3E, 0x27, 0xD2, 0x60, 0x4B
    ])

    /// Validates that the point `(x, y)` lies on the secp256r1 curve.
    ///
    /// Verifies the short Weierstrass equation `y^2 ≡ x^3 + a·x + b (mod p)` and rejects
    /// coordinates with a zero component or coordinates outside the field prime. Used to
    /// guard against accepting garbage byte sequences that happen to follow a COSE-prefix
    /// pattern.
    fileprivate static func validatePointOnCurve(x: Data, y: Data) throws {
        // Reject the point at infinity and trivially invalid coordinates.
        if isAllZero(x) || isAllZero(y) {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Extracted secp256r1 coordinates contain a zero component; the point is not a valid curve point"
            )
        }

        // Coordinates must be strictly less than the field prime. Values >= p are not valid
        // field elements; accepting them would silently reduce them mod p and could admit
        // multiple encodings of the same logical point.
        if compareUnsignedBigEndian(x, curvePBytes) >= 0
            || compareUnsignedBigEndian(y, curvePBytes) >= 0
        {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Extracted secp256r1 coordinates exceed the field prime"
            )
        }

        let p = curvePBytes
        let lhs = mulMod(y, y, p)
        let xSquared = mulMod(x, x, p)
        let xCubed = mulMod(xSquared, x, p)
        let ax = mulMod(curveABytes, x, p)
        let sum1 = addMod(xCubed, ax, p)
        let rhs = addMod(sum1, curveBBytes, p)

        if compareUnsignedBigEndian(lhs, rhs) != 0 {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Extracted secp256r1 public key coordinates are not on the P-256 curve; the attestation data may be malformed or corrupted"
            )
        }
    }

    /// Returns `true` when every byte in `bytes` is zero.
    private static func isAllZero(_ bytes: Data) -> Bool {
        for byte in bytes where byte != 0 {
            return false
        }
        return true
    }

    /// Compares two unsigned big-endian byte sequences as integers. Returns a negative
    /// value when `a < b`, zero when `a == b`, and a positive value when `a > b`.
    private static func compareUnsignedBigEndian(_ a: Data, _ b: Data) -> Int {
        // Strip leading zeros from both sides so length comparisons reflect magnitude.
        let aStripped = stripLeadingZeros(a)
        let bStripped = stripLeadingZeros(b)
        if aStripped.count != bStripped.count {
            return aStripped.count - bStripped.count
        }
        for i in 0..<aStripped.count {
            let av = Int(aStripped[aStripped.startIndex + i])
            let bv = Int(bStripped[bStripped.startIndex + i])
            if av != bv {
                return av - bv
            }
        }
        return 0
    }

    /// Returns `bytes` with any leading zero bytes removed.
    private static func stripLeadingZeros(_ bytes: Data) -> Data {
        var index = bytes.startIndex
        while index < bytes.endIndex - 1 && bytes[index] == 0 {
            index = bytes.index(after: index)
        }
        if index == bytes.startIndex {
            return bytes
        }
        return bytes.subdata(in: index..<bytes.endIndex)
    }

    /// Left-pads an unsigned big-endian byte sequence to exactly `length` bytes.
    fileprivate static func leftPadUnsignedBigEndian(_ bytes: Data, length: Int) -> Data {
        precondition(length >= 0, "Length must be non-negative")
        if bytes.count == length {
            return Data(bytes)
        }
        if bytes.count < length {
            var result = Data(count: length)
            let offset = length - bytes.count
            result.replaceSubrange(offset..<length, with: bytes)
            return result
        }
        // Strip leading zeros if exactly equal length is achievable; otherwise truncating
        // would lose information. The callers in this file only invoke us after enforcing
        // bounds (R/S strictly less than the curve order, both at most 32 bytes after
        // stripping), so this path indicates a programming error.
        let stripped = stripLeadingZeros(bytes)
        precondition(
            stripped.count <= length,
            "Value requires \(stripped.count) bytes, exceeds target size of \(length)"
        )
        return leftPadUnsignedBigEndian(stripped, length: length)
    }

    /// Subtracts `b` from `a` as unsigned big-endian integers; precondition `a >= b`.
    fileprivate static func subtractUnsignedBigEndian(_ a: Data, _ b: Data) -> Data {
        precondition(compareUnsignedBigEndian(a, b) >= 0, "subtract requires a >= b")
        let length = a.count
        let bPadded = leftPadUnsignedBigEndian(b, length: length)
        var result = Data(count: length)
        var borrow: Int = 0
        for i in stride(from: length - 1, through: 0, by: -1) {
            let av = Int(a[a.startIndex + i])
            let bv = Int(bPadded[bPadded.startIndex + i])
            var diff = av - bv - borrow
            if diff < 0 {
                diff += 256
                borrow = 1
            } else {
                borrow = 0
            }
            result[i] = UInt8(diff)
        }
        return stripLeadingZeros(result)
    }

    /// Adds two unsigned big-endian byte sequences modulo `m`.
    private static func addMod(_ a: Data, _ b: Data, _ m: Data) -> Data {
        let sum = addUnsignedBigEndian(a, b)
        return modUnsignedBigEndian(sum, m)
    }

    /// Multiplies two unsigned big-endian byte sequences modulo `m` using O(n^2)
    /// schoolbook multiplication; the input sizes are bounded by 32 bytes so the constant
    /// factor is small and the operation runs in well under a millisecond.
    private static func mulMod(_ a: Data, _ b: Data, _ m: Data) -> Data {
        let aReduced = modUnsignedBigEndian(a, m)
        let bReduced = modUnsignedBigEndian(b, m)
        let product = mulUnsignedBigEndian(aReduced, bReduced)
        return modUnsignedBigEndian(product, m)
    }

    /// Adds two unsigned big-endian byte sequences. The result is at most one byte longer
    /// than the longer input.
    private static func addUnsignedBigEndian(_ a: Data, _ b: Data) -> Data {
        let length = max(a.count, b.count) + 1
        let aPadded = leftPadUnsignedBigEndian(a, length: length)
        let bPadded = leftPadUnsignedBigEndian(b, length: length)
        var result = Data(count: length)
        var carry: Int = 0
        for i in stride(from: length - 1, through: 0, by: -1) {
            let sum = Int(aPadded[aPadded.startIndex + i])
                + Int(bPadded[bPadded.startIndex + i])
                + carry
            result[i] = UInt8(sum & 0xFF)
            carry = sum >> 8
        }
        return stripLeadingZeros(result)
    }

    /// Multiplies two unsigned big-endian byte sequences using schoolbook multiplication.
    private static func mulUnsignedBigEndian(_ a: Data, _ b: Data) -> Data {
        let aBytes = stripLeadingZeros(a)
        let bBytes = stripLeadingZeros(b)
        if aBytes.count == 1 && aBytes[aBytes.startIndex] == 0 { return Data([0]) }
        if bBytes.count == 1 && bBytes[bBytes.startIndex] == 0 { return Data([0]) }
        let resultLength = aBytes.count + bBytes.count
        var result = Array(repeating: 0, count: resultLength)
        for i in stride(from: aBytes.count - 1, through: 0, by: -1) {
            let av = Int(aBytes[aBytes.startIndex + i])
            if av == 0 { continue }
            var carry = 0
            for j in stride(from: bBytes.count - 1, through: 0, by: -1) {
                let bv = Int(bBytes[bBytes.startIndex + j])
                let position = i + j + 1
                let sum = result[position] + av * bv + carry
                result[position] = sum & 0xFF
                carry = sum >> 8
            }
            result[i] = result[i] + carry
        }
        return stripLeadingZeros(Data(result.map { UInt8($0 & 0xFF) }))
    }

    /// Reduces an unsigned big-endian byte sequence modulo `m` using restoring division.
    private static func modUnsignedBigEndian(_ a: Data, _ m: Data) -> Data {
        let modulus = stripLeadingZeros(m)
        if modulus.count == 1 && modulus[modulus.startIndex] == 0 {
            // Division by zero is undefined; the algorithms in this file never call us
            // with a zero modulus, so this path indicates a programming error.
            preconditionFailure("Modulus must be non-zero")
        }
        var remainder = Data([0])
        for byte in a {
            remainder = shiftLeft8(remainder)
            remainder = addByte(remainder, byte)
            // Reduce until remainder < modulus. At most 256 reductions per byte are
            // required; in practice the loop runs at most twice because remainder fits in
            // (modulus.count + 1) bytes after the shift.
            while compareUnsignedBigEndian(remainder, modulus) >= 0 {
                remainder = subtractUnsignedBigEndian(remainder, modulus)
            }
        }
        return stripLeadingZeros(remainder)
    }

    /// Shifts an unsigned big-endian byte sequence left by 8 bits (appends a zero byte).
    private static func shiftLeft8(_ value: Data) -> Data {
        if value.count == 1 && value[value.startIndex] == 0 {
            return value
        }
        var result = Data(value)
        result.append(0)
        return result
    }

    /// Adds a single byte to an unsigned big-endian byte sequence.
    private static func addByte(_ value: Data, _ byte: UInt8) -> Data {
        var result = Data(value)
        var carry = Int(byte)
        for i in stride(from: result.count - 1, through: 0, by: -1) {
            let sum = Int(result[i]) + carry
            result[i] = UInt8(sum & 0xFF)
            carry = sum >> 8
            if carry == 0 { break }
        }
        if carry > 0 {
            var prefix = Data([UInt8(carry & 0xFF)])
            prefix.append(result)
            return prefix
        }
        return result
    }
}
