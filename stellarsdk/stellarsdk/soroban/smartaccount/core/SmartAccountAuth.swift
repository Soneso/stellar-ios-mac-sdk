//
//  SmartAccountAuth.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Authentication utilities for Smart Account authorization entries.
///
/// Provides functions to sign authorization entries and build authentication payload hashes
/// for Smart Account transactions. These utilities handle the complex XDR encoding and
/// signature map construction required by the Soroban authorization protocol.
///
/// Key responsibilities:
/// - Building Soroban authorization payload hashes for WebAuthn challenges
/// - Signing authorization entries with Smart Account signers
/// - Managing signature expiration and map entry ordering
/// - Double XDR encoding of signature values
///
/// Example usage:
/// ```swift
/// // Build payload hash for WebAuthn signing
/// let payloadHash = try SmartAccountAuth.buildAuthPayloadHash(
///     entry: authEntry,
///     expirationLedger: currentLedger + 100,
///     networkPassphrase: Network.testnet.networkPassphrase
/// )
///
/// // Sign the entry with a WebAuthn signature
/// let signedEntry = try SmartAccountAuth.signAuthEntry(
///     entry: authEntry,
///     signer: webAuthnSigner,
///     signatureScVal: webAuthnSignatureScVal,
///     expirationLedger: currentLedger + 100,
///     networkPassphrase: Network.testnet.networkPassphrase
/// )
/// ```
public struct SmartAccountAuth: Sendable {

    private init() {}

    // MARK: - Payload Hash Building

    /// Builds the authorization payload hash for signing.
    ///
    /// Computes the hash that must be signed to authorize a Soroban operation. This hash
    /// is used as the WebAuthn challenge when collecting biometric signatures.
    ///
    /// The payload is constructed as:
    /// ```
    /// HashIdPreimage::SorobanAuthorization {
    ///   networkId: SHA256(networkPassphrase as UTF-8),
    ///   nonce: credentials.nonce,
    ///   signatureExpirationLedger: expirationLedger,
    ///   invocation: entry.rootInvocation
    /// }
    /// hash = SHA256(XDR_encode(payload))
    /// ```
    ///
    /// CRITICAL: The entry must have `.address` credentials and the expiration ledger
    /// is used in the hash computation before any signatures are added.
    ///
    /// - Parameters:
    ///   - entry: The authorization entry to build the payload hash for
    ///   - expirationLedger: The ledger number at which the signature expires
    ///   - networkPassphrase: The network passphrase (e.g., "Test SDF Network ; September 2015")
    /// - Returns: The 32-byte SHA-256 hash of the authorization payload
    /// - Throws: SmartAccountError.transactionSigningFailed if credentials is not `.address`
    ///           type or if XDR encoding fails
    ///
    /// Example:
    /// ```swift
    /// let hash = try SmartAccountAuth.buildAuthPayloadHash(
    ///     entry: authEntry,
    ///     expirationLedger: 12345678,
    ///     networkPassphrase: Network.testnet.networkPassphrase
    /// )
    /// // Use hash as WebAuthn challenge
    /// let webAuthnResponse = await navigator.credentials.get(challenge: hash)
    /// ```
    public static func buildAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) throws -> Data {
        // Validate credentials type
        guard let credentials = entry.credentials.address else {
            throw SmartAccountError.transactionSigningFailed(
                "Credentials must be of type address to build auth payload hash"
            )
        }

        // Step 1: Compute network ID (SHA-256 of network passphrase)
        let networkId = networkPassphrase.sha256Hash

        // Step 2: Build HashIDPreimage::SorobanAuthorization
        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: WrappedData32(networkId),
            nonce: credentials.nonce,
            signatureExpirationLedger: expirationLedger,
            invocation: entry.rootInvocation
        )

        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)

        // Step 3: XDR encode the preimage
        let encodedPreimage: [UInt8]
        do {
            encodedPreimage = try XDREncoder.encode(preimage)
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to XDR encode auth payload preimage",
                cause: error
            )
        }

        // Step 4: Hash the encoded preimage
        let encodedPreimageData = Data(encodedPreimage)
        return encodedPreimageData.sha256Hash
    }

    // MARK: - Entry Signing

    /// Signs an authorization entry with a Smart Account signer.
    ///
    /// Creates a new authorization entry with the provided signature added to the
    /// signature map. This function performs the following steps:
    ///
    /// 1. Clones the entry via XDR round-trip (encode then decode)
    /// 2. Sets the signature expiration ledger
    /// 3. Builds the signer key ScVal from the signer
    /// 4. Double XDR-encodes the signature value (CRITICAL)
    /// 5. Creates a map entry with key=signer, value=double-encoded-signature
    /// 6. Adds to or creates the signature map
    /// 7. Sorts map entries by XDR-encoded key bytes (lowercase hex, lexicographic)
    ///
    /// CRITICAL DETAILS:
    /// - The entry is cloned to avoid mutating the input
    /// - Expiration MUST be set BEFORE building payload hash (done externally)
    /// - Signature value uses DOUBLE XDR encoding: encode the ScVal to bytes,
    ///   then wrap those bytes in a new ScVal::Bytes
    /// - Map entries MUST be sorted by their XDR-encoded key bytes as lowercase hex
    /// - Credentials must be of type `.address`
    ///
    /// The signature map format is:
    /// ```
    /// ScVal::Vec([
    ///   ScVal::Map([
    ///     { key: signer.toScVal(), value: ScVal::Bytes(XDR_encode(signatureScVal)) },
    ///     ...
    ///   ])
    /// ])
    /// ```
    ///
    /// - Parameters:
    ///   - entry: The authorization entry to sign
    ///   - signer: The Smart Account signer (delegated or external)
    ///   - signatureScVal: The signature value as an SCVal (e.g., WebAuthn signature map)
    ///   - expirationLedger: The ledger number at which the signature expires
    ///   - networkPassphrase: The network passphrase (unused but kept for API consistency)
    /// - Returns: A new signed authorization entry
    /// - Throws: SmartAccountError.transactionSigningFailed if credentials is not `.address`
    ///           type, if XDR encoding/decoding fails, or if map construction fails
    ///
    /// Example:
    /// ```swift
    /// let webAuthnSig = WebAuthnSignature(
    ///     authenticatorData: authData,
    ///     clientData: clientData,
    ///     signature: signature
    /// )
    /// let sigScVal = try webAuthnSig.toScVal()
    ///
    /// let signedEntry = try SmartAccountAuth.signAuthEntry(
    ///     entry: unsignedEntry,
    ///     signer: externalSigner,
    ///     signatureScVal: sigScVal,
    ///     expirationLedger: currentLedger + 100,
    ///     networkPassphrase: Network.testnet.networkPassphrase
    /// )
    /// ```
    public static func signAuthEntry(
        entry: SorobanAuthorizationEntryXDR,
        signer: SmartAccountSigner,
        signatureScVal: SCValXDR,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) throws -> SorobanAuthorizationEntryXDR {
        // STEP 1: Clone entry via XDR round-trip to avoid mutating input
        let entryBytes: [UInt8]
        do {
            entryBytes = try XDREncoder.encode(entry)
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to XDR encode authorization entry for cloning",
                cause: error
            )
        }

        let entryCopy: SorobanAuthorizationEntryXDR
        do {
            entryCopy = try XDRDecoder.decode(
                SorobanAuthorizationEntryXDR.self,
                data: entryBytes
            )
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to XDR decode authorization entry after cloning",
                cause: error
            )
        }

        // STEP 2: Set expiration (BEFORE building payload - though payload is built externally)
        guard var credentials = entryCopy.credentials.address else {
            throw SmartAccountError.transactionSigningFailed(
                "Credentials must be of type address to sign auth entry"
            )
        }

        credentials.signatureExpirationLedger = expirationLedger

        // STEP 3: Build signature map entry
        // KEY: Signer identity as ScVal
        let signerKey: SCValXDR
        do {
            signerKey = try signer.toScVal()
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to convert signer to SCVal",
                cause: error
            )
        }

        // VALUE: Double XDR-encoded signature
        // Step A: signatureScVal is already a ScVal
        // Step B: XDR-encode that ScVal into raw bytes
        let sigXdrBytes: [UInt8]
        do {
            sigXdrBytes = try XDREncoder.encode(signatureScVal)
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to XDR encode signature ScVal",
                cause: error
            )
        }

        // Step C: Wrap those raw bytes in a new ScVal::Bytes
        let signatureValue = SCValXDR.bytes(Data(sigXdrBytes))

        // Create map entry
        let mapEntry = SCMapEntryXDR(key: signerKey, val: signatureValue)

        // STEP 4: Add to signatures map
        var mapEntries: [SCMapEntryXDR] = []

        // Check if credentials.signature already has a Vec with a Map
        if let existingVec = credentials.signature.vec,
           !existingVec.isEmpty,
           let existingMap = existingVec[0].map {
            // Append to existing map
            mapEntries = existingMap
            mapEntries.append(mapEntry)
        } else {
            // Create new map with this entry
            mapEntries = [mapEntry]
        }

        // STEP 5: Sort map entries by XDR-encoded key bytes (as lowercase hex, lexicographic)
        mapEntries.sort { entry1, entry2 in
            do {
                // Encode both keys to XDR bytes
                let key1Bytes = try XDREncoder.encode(entry1.key)
                let key2Bytes = try XDREncoder.encode(entry2.key)

                // Convert to lowercase hex strings
                let key1Hex = key1Bytes.map { String(format: "%02x", $0) }.joined()
                let key2Hex = key2Bytes.map { String(format: "%02x", $0) }.joined()

                // Sort lexicographically
                return key1Hex < key2Hex
            } catch {
                // If encoding fails, maintain original order (should not happen)
                return false
            }
        }

        // Build the final signature structure: ScVal::Vec([ScVal::Map([entries...])])
        let signatureMap = SCValXDR.map(mapEntries)
        credentials.signature = SCValXDR.vec([signatureMap])

        // STEP 6: Create and return the signed entry
        var signedEntry = entryCopy
        signedEntry.credentials = SorobanCredentialsXDR.address(credentials)

        return signedEntry
    }

    // MARK: - Source Account Auth

    /// Builds the authorization payload hash for source_account credentials.
    ///
    /// Similar to buildAuthPayloadHash but for converting source_account credentials to
    /// Address credentials. Used during fundWallet to enable relayer fee sponsoring.
    ///
    /// - Parameters:
    ///   - entry: The authorization entry with source_account credentials
    ///   - nonce: The nonce to use for the new Address credential
    ///   - expirationLedger: The ledger number at which the signature expires
    ///   - networkPassphrase: The network passphrase
    /// - Returns: The 32-byte SHA-256 hash of the authorization payload
    /// - Throws: SmartAccountError.transactionSigningFailed if XDR encoding fails
    public static func buildSourceAccountAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        nonce: Int64,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) throws -> Data {
        // Step 1: Compute network ID (SHA-256 of network passphrase)
        let networkId = networkPassphrase.sha256Hash

        // Step 2: Build HashIDPreimage::SorobanAuthorization
        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: WrappedData32(networkId),
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            invocation: entry.rootInvocation
        )

        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)

        // Step 3: XDR encode the preimage
        let encodedPreimage: [UInt8]
        do {
            encodedPreimage = try XDREncoder.encode(preimage)
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to XDR encode source account auth payload preimage",
                cause: error
            )
        }

        // Step 4: Hash the encoded preimage
        let encodedPreimageData = Data(encodedPreimage)
        return encodedPreimageData.sha256Hash
    }
}
