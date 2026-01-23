//
//  SmartAccountUtils.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Utility functions for Smart Account operations.
///
/// Provides cryptographic utilities for WebAuthn signature processing,
/// public key extraction, and contract address derivation.
public struct SmartAccountUtils: Sendable {

    private init() {}

    // MARK: - Signature Normalization

    /// Normalizes a DER-encoded secp256r1 signature to compact format with low-S normalization.
    ///
    /// This function performs the following steps:
    /// 1. Parses DER format: `0x30 [total_len] 0x02 [r_len] [r_bytes] 0x02 [s_len] [s_bytes]`
    /// 2. Extracts r and s components (stripping leading 0x00 padding if present)
    /// 3. Converts s to BigInteger and normalizes to low-S form if needed
    /// 4. Pads both r and s to exactly 32 bytes
    /// 5. Returns concatenated r || s (64 bytes total)
    ///
    /// Low-S normalization ensures that s values greater than half the curve order
    /// are converted to their complements (n - s), which is required for Stellar/Soroban
    /// signature verification.
    ///
    /// - Parameter derSignature: DER-encoded signature bytes
    /// - Returns: Compact 64-byte signature (32-byte r || 32-byte s)
    /// - Throws: SmartAccountError.signerInvalid if the DER format is invalid
    ///
    /// Example:
    /// ```swift
    /// let derSig = Data(...)  // DER-encoded signature from WebAuthn
    /// let compactSig = try SmartAccountUtils.normalizeSignature(derSig)
    /// // compactSig is now 64 bytes: r (32 bytes) || s (32 bytes)
    /// ```
    public static func normalizeSignature(_ derSignature: Data) throws -> Data {
        // Validate DER signature header
        guard derSignature.count >= 8,
              derSignature[0] == 0x30 else {
            throw SmartAccountError.signerInvalid("Invalid DER signature format")
        }

        // Parse r component
        var offset = 2
        guard offset + 1 < derSignature.count,
              derSignature[offset] == 0x02 else {
            throw SmartAccountError.signerInvalid("Invalid DER signature format: missing r component marker")
        }

        let rLength = Int(derSignature[offset + 1])
        guard offset + 2 + rLength <= derSignature.count else {
            throw SmartAccountError.signerInvalid("Invalid DER signature format: truncated r component")
        }

        var r = derSignature.subdata(in: (offset + 2)..<(offset + 2 + rLength))

        // Strip leading 0x00 padding from r if present
        while r.count > 1 && r.first == 0x00 {
            r = Data(r.dropFirst())
        }

        // Parse s component
        offset = offset + 2 + rLength
        guard offset + 1 < derSignature.count,
              derSignature[offset] == 0x02 else {
            throw SmartAccountError.signerInvalid("Invalid DER signature format: missing s component marker")
        }

        let sLength = Int(derSignature[offset + 1])
        guard offset + 2 + sLength <= derSignature.count else {
            throw SmartAccountError.signerInvalid("Invalid DER signature format: truncated s component")
        }

        var s = derSignature.subdata(in: (offset + 2)..<(offset + 2 + sLength))

        // Strip leading 0x00 padding from s if present
        while s.count > 1 && s.first == 0x00 {
            s = Data(s.dropFirst())
        }

        // Convert r and s to BInt for low-S normalization
        let rBigInt = BInt(data: r)
        var sBigInt = BInt(data: s)

        // Normalize s to low-S form
        // secp256r1 curve order: 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551
        // Reference: https://github.com/stellar/stellar-protocol/discussions/1435#discussioncomment-8809175
        guard let curveOrder = BInt(number: "ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551", withBase: 16) else {
            throw SmartAccountError.signerInvalid("Failed to initialize secp256r1 curve order")
        }

        let halfCurveOrder = curveOrder / 2

        // If s > halfOrder, normalize: s = n - s
        if sBigInt > halfCurveOrder {
            sBigInt = curveOrder - sBigInt
        }

        // Convert back to hex strings and pad to 64 characters (32 bytes)
        let rPadded = rBigInt.asString(withBase: 16).leftPadded(toLength: 64, withPad: "0")
        let sPadded = sBigInt.asString(withBase: 16).leftPadded(toLength: 64, withPad: "0")

        // Convert hex strings back to Data
        guard let rBytes = try? Data(base16Encoded: rPadded),
              let sBytes = try? Data(base16Encoded: sPadded) else {
            throw SmartAccountError.signerInvalid("Failed to convert normalized signature components to bytes")
        }

        // Concatenate r || s (64 bytes total)
        var result = Data()
        result.append(rBytes)
        result.append(sBytes)

        return result
    }

    // MARK: - Public Key Extraction

    /// Extracts the secp256r1 public key from WebAuthn attestation data.
    ///
    /// Searches for the COSE key structure in raw attestation data and extracts
    /// the X and Y coordinates of the public key. The result is formatted as an
    /// uncompressed public key with the 0x04 prefix.
    ///
    /// COSE key structure:
    /// ```
    /// Prefix: [0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]
    /// X coordinate: next 32 bytes
    /// Skip: 3 bytes (0x22, 0x58, 0x20)
    /// Y coordinate: next 32 bytes
    /// Result: 0x04 || X (32 bytes) || Y (32 bytes) = 65 bytes total
    /// ```
    ///
    /// - Parameter attestationData: Raw attestation object data from WebAuthn registration
    /// - Returns: Uncompressed secp256r1 public key (65 bytes: 0x04 prefix + X + Y)
    /// - Throws: SmartAccountError.invalidInput if the COSE key structure is not found
    ///           or if there is insufficient data after the prefix
    ///
    /// Example:
    /// ```swift
    /// let attestationData = ... // from WebAuthn registration
    /// let publicKey = try SmartAccountUtils.extractPublicKey(fromAttestationObject: attestationData)
    /// print("Public key: \(publicKey.hexEncodedString())")
    /// ```
    public static func extractPublicKey(fromAttestationObject attestationData: Data) throws -> Data {
        // COSE key prefix for secp256r1 public keys in WebAuthn attestation
        let publicKeyPrefixSlice = Data([0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])

        guard let range = attestationData.range(of: publicKeyPrefixSlice) else {
            throw SmartAccountError.invalidInput("COSE key prefix not found in attestation data")
        }

        let startIndex = range.upperBound

        // Ensure we have enough data for X (32 bytes) + separator (3 bytes) + Y (32 bytes)
        let requiredLength = startIndex + 32 + 3 + 32
        guard attestationData.count >= requiredLength else {
            throw SmartAccountError.invalidInput("Insufficient data after COSE key prefix")
        }

        // Extract X coordinate (32 bytes after prefix)
        let x = attestationData.subdata(in: startIndex ..< startIndex + 32)

        // Skip 3 bytes (0x22, 0x58, 0x20) and extract Y coordinate (32 bytes)
        let yStartIndex = startIndex + 32 + 3
        let y = attestationData.subdata(in: yStartIndex ..< yStartIndex + 32)

        // Construct uncompressed public key: 0x04 || X || Y
        var publicKey = Data([SmartAccountConstants.UNCOMPRESSED_PUBKEY_PREFIX])
        publicKey.append(x)
        publicKey.append(y)

        return publicKey
    }

    /// Extracts the secp256r1 public key from WebAuthn authenticator data.
    ///
    /// Alternative extraction method that parses authenticator data directly
    /// rather than searching through attestation object structure.
    ///
    /// Authenticator data structure:
    /// ```
    /// Bytes 53-54: Credential ID length (big-endian UInt16)
    /// After credential ID + offset:
    ///   X coordinate: 32 bytes
    ///   Y coordinate: 32 bytes (after 3-byte separator)
    /// Result: 0x04 || X || Y = 65 bytes
    /// ```
    ///
    /// - Parameter authData: Authenticator data from WebAuthn registration
    /// - Returns: Uncompressed secp256r1 public key (65 bytes: 0x04 prefix + X + Y)
    /// - Throws: SmartAccountError.invalidInput if authenticator data is too short
    ///           or malformed
    ///
    /// Example:
    /// ```swift
    /// let authData = ... // from WebAuthn registration
    /// let publicKey = try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(authData)
    /// ```
    public static func extractPublicKeyFromAuthenticatorData(_ authData: Data) throws -> Data {
        // Minimum size: RP ID hash (32) + flags (1) + counter (4) + AAGUID (16) + credID length (2)
        guard authData.count >= 55 else {
            throw SmartAccountError.invalidInput("Authenticator data too short")
        }

        // Extract credential ID length from bytes 53-54 (big-endian UInt16)
        let credentialIdLength = Int((UInt16(authData[53]) << 8) | UInt16(authData[54]))

        // Calculate positions for X and Y coordinates
        let xStartIndex = 55 + credentialIdLength + 10 // 55 base + credID + 10 offset to X
        let yStartIndex = xStartIndex + 32 + 3 // X (32) + separator (3)

        guard authData.count >= yStartIndex + 32 else {
            throw SmartAccountError.invalidInput("Insufficient data for public key extraction")
        }

        // Extract X coordinate (32 bytes)
        let x = authData.subdata(in: xStartIndex ..< xStartIndex + 32)

        // Extract Y coordinate (32 bytes)
        let y = authData.subdata(in: yStartIndex ..< yStartIndex + 32)

        // Construct uncompressed public key: 0x04 || X || Y
        var publicKey = Data([SmartAccountConstants.UNCOMPRESSED_PUBKEY_PREFIX])
        publicKey.append(x)
        publicKey.append(y)

        return publicKey
    }

    // MARK: - Contract Salt

    /// Computes the contract salt from a WebAuthn credential ID.
    ///
    /// The salt is used as part of the contract address derivation process to ensure
    /// each credential ID results in a unique contract address. This is computed as
    /// the SHA-256 hash of the credential ID.
    ///
    /// - Parameter credentialId: WebAuthn credential ID
    /// - Returns: SHA-256 hash of the credential ID (32 bytes)
    ///
    /// Example:
    /// ```swift
    /// let credentialId = ... // from WebAuthn registration
    /// let salt = SmartAccountUtils.getContractSalt(credentialId: credentialId)
    /// ```
    public static func getContractSalt(credentialId: Data) -> Data {
        return credentialId.sha256Hash
    }

    // MARK: - Contract Address Derivation

    /// Derives the smart account contract address from a credential ID and deployer.
    ///
    /// Computes the deterministic contract address that will be created when deploying
    /// a smart account contract with the given credential ID from the specified deployer
    /// account on the specified network.
    ///
    /// Algorithm:
    /// ```
    /// salt = SHA256(credentialId)
    /// deployerAddress = SCAddress::Account(deployerPublicKey)
    /// networkId = SHA256(networkPassphrase as UTF-8)
    ///
    /// preimage = HashIdPreimage::ContractId {
    ///   networkId: networkId,
    ///   contractIdPreimage: ContractIdPreimage::FromAddress {
    ///     address: deployerAddress,
    ///     salt: Uint256(salt)
    ///   }
    /// }
    ///
    /// contractIdBytes = SHA256(XDR_encode(preimage))
    /// contractId = StrKey.encodeContractId(contractIdBytes)
    /// ```
    ///
    /// - Parameters:
    ///   - credentialId: WebAuthn credential ID used to generate the salt
    ///   - deployerPublicKey: Stellar account ID (G-address) of the deployer
    ///   - networkPassphrase: Network passphrase (e.g., "Test SDF Network ; September 2015")
    /// - Returns: Contract address as a C-address (StrKey encoded)
    /// - Throws: SmartAccountError.invalidAddress if the deployer public key is invalid
    ///           SmartAccountError.transactionSigningFailed if XDR encoding fails
    ///
    /// Example:
    /// ```swift
    /// let credentialId = ... // from WebAuthn registration
    /// let deployerKey = "GBXYZ..." // deployer G-address
    /// let network = Network.testnet
    /// let contractAddress = try SmartAccountUtils.deriveContractAddress(
    ///     credentialId: credentialId,
    ///     deployerPublicKey: deployerKey,
    ///     networkPassphrase: network.networkPassphrase
    /// )
    /// print("Contract will be deployed at: \(contractAddress)")
    /// ```
    public static func deriveContractAddress(
        credentialId: Data,
        deployerPublicKey: String,
        networkPassphrase: String
    ) throws -> String {
        // Step 1: Compute contract salt from credential ID
        let contractSalt = getContractSalt(credentialId: credentialId)

        // Step 2: Create deployer SCAddress from public key
        let deployerAddress: SCAddressXDR
        do {
            deployerAddress = try SCAddressXDR(accountId: deployerPublicKey)
        } catch {
            throw SmartAccountError.invalidAddress(
                "Invalid deployer public key: \(deployerPublicKey)",
                cause: error
            )
        }

        // Step 3: Compute network ID (SHA-256 of network passphrase)
        let networkId = networkPassphrase.sha256Hash

        // Step 4: Construct ContractIDPreimage::FromAddress
        let contractIDPreimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(
                address: deployerAddress,
                salt: WrappedData32(contractSalt)
            )
        )

        // Step 5: Construct HashIDPreimage::ContractID
        let hashIDPreimageContractID = HashIDPreimageContractIDXDR(
            networkID: WrappedData32(networkId),
            contractIDPreimage: contractIDPreimage
        )

        let preimage = HashIDPreimageXDR.contractID(hashIDPreimageContractID)

        // Step 6: XDR encode the preimage
        let encodedPreimage: [UInt8]
        do {
            encodedPreimage = try XDREncoder.encode(preimage)
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to XDR encode contract ID preimage",
                cause: error
            )
        }

        // Step 7: Hash the encoded preimage
        let encodedPreimageData = Data(encodedPreimage)
        let contractIdBytes = encodedPreimageData.sha256Hash

        // Step 8: Encode as StrKey contract ID (C-address)
        do {
            return try contractIdBytes.encodeContractId()
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to encode contract ID",
                cause: error
            )
        }
    }
}

// MARK: - String Extension

private extension String {
    /// Pads the string on the left to reach the specified length.
    ///
    /// If the string is already longer than the target length, returns the suffix
    /// of the specified length.
    ///
    /// - Parameters:
    ///   - toLength: The target length of the string
    ///   - character: The character to use for padding
    /// - Returns: The padded string
    func leftPadded(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
}
