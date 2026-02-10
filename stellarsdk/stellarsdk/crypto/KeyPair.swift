//
//  KeyPair.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import ed25519C

/// Holds a Stellar keypair consisting of a public key and an optional private key.
///
/// KeyPair represents an Ed25519 keypair used for signing transactions and verifying signatures
/// on the Stellar network. A keypair can be created with or without a private key:
/// - With private key: Used for signing transactions (full keypair)
/// - Without private key: Used for verification only (public key only)
///
/// The public key is encoded as a Stellar account ID starting with 'G' (or 'M' for muxed accounts).
/// The private key (seed) is encoded as a secret seed starting with 'S'.
///
/// Security considerations:
/// - Never share or expose secret seeds
/// - Store secret seeds securely using the iOS Keychain or equivalent secure storage
/// - Never commit secret seeds to version control
/// - Use KeyPair objects without private keys when only verification is needed
/// - Clear sensitive data from memory when no longer needed
///
/// Example:
/// ```swift
/// // Generate a random keypair
/// let keyPair = try KeyPair.generateRandomKeyPair()
/// print("Account ID: \(keyPair.accountId)")
/// print("Secret Seed: \(keyPair.secretSeed)")
///
/// // Create keypair from existing secret seed
/// let existingKeyPair = try KeyPair(secretSeed: "SXXX...")
///
/// // Create public-only keypair for verification
/// let publicOnlyKeyPair = try KeyPair(accountId: "GXXX...")
///
/// // Sign data
/// let signature = keyPair.sign(data)
///
/// // Verify signature
/// let isValid = try publicOnlyKeyPair.verify(signature: signature, message: data)
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
public final class KeyPair: @unchecked Sendable {
    /// The Ed25519 public key.
    public let publicKey: PublicKey

    /// The Ed25519 private key. Nil if this is a public-only keypair.
    public let privateKey: PrivateKey?

    /// The seed used to generate this keypair. Nil if created from raw keys or account ID.
    public private(set) var seed:Seed?

    /// Human readable Stellar account ID (G-address).
    ///
    /// This is the base32-encoded public key with version byte and checksum.
    public var accountId: String {
        get {
            return publicKey.accountId
        }
    }
    /// Human readable Stellar secret seed (S-address).
    ///
    /// This is the base32-encoded private key with version byte and checksum.
    /// Returns nil if this keypair was created without a seed.
    ///
    /// Warning: Keep secret seeds secure. Never expose them in logs or transmit them insecurely.
    public var secretSeed: String? {
        get {
            return seed?.secret
        }
    }

    /// Generates a new random Stellar keypair.
    ///
    /// Creates a cryptographically secure random Ed25519 keypair suitable for
    /// creating new Stellar accounts. The keypair includes both public and private keys.
    ///
    /// - Returns: A new KeyPair with randomly generated keys
    /// - Throws: An error if random key generation fails
    ///
    /// Example:
    /// ```swift
    /// let keyPair = try KeyPair.generateRandomKeyPair()
    /// print("New account: \(keyPair.accountId)")
    /// // Securely store keyPair.secretSeed
    /// ```
    ///
    /// Warning: Store the secret seed securely immediately after generation.
    public static func generateRandomKeyPair() throws -> KeyPair {
        let seed = try Seed()
        let keyPair = KeyPair(seed: seed)
        
        return keyPair
        
    }
    
    /// Creates a new KeyPair from the given public and private keys.
    ///
    /// - Parameter publicKey: The Ed25519 public key
    /// - Parameter privateKey: The Ed25519 private key. If nil, creates a public-only keypair that cannot sign.
    public init(publicKey: PublicKey, privateKey: PrivateKey?) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }

    /// Creates a new Stellar KeyPair from a Stellar account ID.
    ///
    /// Creates a public-only keypair that can be used for signature verification but
    /// cannot sign transactions. The account ID must be a valid G-address or M-address.
    ///
    /// - Parameter accountId: The Stellar account ID (G-address or M-address)
    /// - Throws: An error if the account ID is invalid
    public convenience init(accountId: String) throws {
        let publicKeyFromAccountId = try PublicKey(accountId: accountId)
        self.init(publicKey: publicKeyFromAccountId, privateKey:nil)
    }
    
    /// Creates a new Stellar keypair from a Stellar secret seed.
    ///
    /// Creates a full keypair with both public and private keys from an existing
    /// secret seed (S-address). This keypair can sign transactions.
    ///
    /// - Parameter secretSeed: The Stellar secret seed (S-address)
    /// - Throws: An error if the secret seed is invalid
    ///
    /// Warning: Handle secret seeds with care. Avoid logging or transmitting them insecurely.
    public convenience init(secretSeed: String) throws {
        let seedFromSecret = try Seed(secret:secretSeed)
        self.init(seed: seedFromSecret)
    }
    
    /// Creates a new KeyPair without a private key. Useful e.g. to simply verify a signature from a given public address
    ///
    /// - Parameter publicKey: The public key
    ///
    public convenience init(publicKey: PublicKey)
    {
        self.init(publicKey:publicKey, privateKey:nil)
    }
    
    /// Creates a new Stellar keypair from a seed object. The new KeyPair contains public and private key.
    ///
    /// - Parameter seed: the seed object
    ///
    public convenience init(seed: Seed) {

        var pubBuffer = [UInt8](repeating: 0, count: StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)
        var privBuffer = [UInt8](repeating: 0, count: StellarProtocolConstants.ED25519_PRIVATE_KEY_SIZE)

        privBuffer.withUnsafeMutableBufferPointer { priv in
            pubBuffer.withUnsafeMutableBufferPointer { pub in
                seed.bytes.withUnsafeBufferPointer { seed in
                    ed25519_create_keypair(pub.baseAddress,
                                           priv.baseAddress,
                                           seed.baseAddress)
                }
            }
        }

        self.init(publicKey: PublicKey(unchecked: pubBuffer),
                  privateKey: PrivateKey(unchecked: privBuffer))
        
        self.seed = seed
    }
    
    /// Creates a new Stellar keypair from a public key byte array and a private key byte array.
    ///
    /// - Parameter publicKey: the public key byte array. Must have a lenght of 32.
    /// - Parameter privateKey: the private key byte array. Must have a lenght of 64.
    ///
    /// - Throws Ed25519Error.invalidPublicKeyLength if the lenght of the given byte array != 32
    /// - Throws Ed25519Error.invalidPrivateKeyLength if the lenght of the given byte array != 64
    ///
    public convenience init(publicKey: [UInt8], privateKey: [UInt8]) throws {
        let pub = try PublicKey(publicKey)
        let priv = try PrivateKey(privateKey)
        self.init(publicKey: pub, privateKey: priv)
    }
    
    /// Sign the provided data with the keypair's private key.
    ///
    /// Uses the Ed25519 signature algorithm to sign the message. If this keypair
    /// does not have a private key, returns an empty signature (all zeros).
    ///
    /// - Parameter message: The data to sign
    /// - Returns: The 64-byte Ed25519 signature, or 64 zero bytes if no private key
    ///
    /// Warning: Only sign trusted data. Signatures prove you authorized specific content.
    public func sign(_ message: [UInt8]) -> [UInt8] {

        var signature = [UInt8](repeating: 0, count: StellarProtocolConstants.ED25519_SIGNATURE_SIZE)
        
        if (privateKey == nil) { return signature}
        
        signature.withUnsafeMutableBufferPointer { signature in
            privateKey?.bytes.withUnsafeBufferPointer { priv in
                publicKey.bytes.withUnsafeBufferPointer { pub in
                    message.withUnsafeBufferPointer { msg in
                        ed25519_sign(signature.baseAddress,
                                     msg.baseAddress,
                                     message.count,
                                     pub.baseAddress,
                                     priv.baseAddress)
                    }
                }
            }
        }
        
        return signature
    }
    
    /// Sign the provided data with the keypair's private key and returns the DecoratedSignatureXDR
    ///
    /// - Parameter data: data to be signed
    ///
    /// - Returns the DecoratedSignatureXDR object
    ///
    public func signDecorated(_ message: [UInt8]) -> DecoratedSignatureXDR {
        var signatureBytes = sign(message)
        let signatureData = Data(bytes: &signatureBytes, count: signatureBytes.count)
        var publicKeyData = publicKey.bytes
        let hint = Data(bytes: &publicKeyData, count: publicKeyData.count).suffix(StellarProtocolConstants.SIGNATURE_HINT_SIZE)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint) , signature: signatureData)
        
        return decoratedSignature
    }
    
    /// Sign the provided payload data for payload signer where the input is the data being signed.
    /// Per the <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#signature-hint" CAP-40 Signature spec</a>
    ///
    /// - Parameter signerPayload: payload signers raw data to sign
    ///
    /// - Returns the DecoratedSignatureXDR object
    ///
    public func signPayloadDecorated(_ signerPayload: [UInt8]) -> DecoratedSignatureXDR {

        let decoratedSignature = signDecorated(signerPayload)
        var signerPayloadData = signerPayload
        var suffix = StellarProtocolConstants.SIGNATURE_HINT_SIZE
        if (signerPayload.count < suffix) {
            suffix = signerPayload.count
        }
        
        // copy the last four bytes of the payload into the new hint
        var hint = Data(bytes: &signerPayloadData, count: signerPayload.count).suffix(suffix)
        
        //XOR the new hint with this keypair's public key hint
        hint = Data.xor(left: hint, right: decoratedSignature.hint.wrapped)
        return DecoratedSignatureXDR(hint: WrappedData4(hint) , signature: decoratedSignature.signature)
    }
    
    /// Signs payload data and returns a decorated signature with XOR-ed hint per CAP-40.
    ///
    /// Unlike signDecorated(), this method XORs the signature hint with the last 4 bytes of the payload,
    /// as required for payload signers per CAP-40 specification. The hint helps identify the signer without
    /// revealing the full public key or payload.
    ///
    /// - Parameter signerPayload: The payload data to sign
    /// - Returns: A DecoratedSignatureXDR with XOR-ed hint and Ed25519 signature
    public func signPayloadDecorated(_ signerPayload: Data) -> DecoratedSignatureXDR {
        return signPayloadDecorated([UInt8](signerPayload))
    }

    ///  Verify the provided data and signature match this keypair's public key.
    ///
    /// - Parameter signature: The signature. Byte array must have a lenght of 64.
    /// - Parameter message: The data that was signed.
    ///
    /// - Returns: True if they match, false otherwise.
    ///
    /// - Throws: Ed25519Error.invalidSignatureLength if the signature length is not 64
    ///
    public func verify(signature: [UInt8], message: [UInt8]) throws -> Bool {
        return try publicKey.verify(signature: signature, message: message)
    }

    // MARK: - SEP-53 Message Signing and Verification

    /// Calculates the SHA-256 hash of a SEP-53 prefixed message.
    ///
    /// - Parameter message: The raw message bytes.
    /// - Returns: The SHA-256 hash of the prefix concatenated with the message.
    private static func calculateMessageHash(_ message: [UInt8]) -> [UInt8] {
        let prefix: [UInt8] = Array("Stellar Signed Message:\n".utf8)
        var payload = prefix
        payload.append(contentsOf: message)
        return [UInt8](Data(payload).sha256Hash)
    }

    /// Signs a binary message according to
    /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
    ///
    /// The message is prepended with "Stellar Signed Message:\n", hashed with SHA-256,
    /// and the digest is signed with this keypair's Ed25519 private key.
    ///
    /// - Parameter message: The raw bytes of the message to sign.
    /// - Returns: A 64-byte Ed25519 signature.
    /// - Throws: `Ed25519Error.missingPrivateKey` if this keypair has no private key.
    public func signMessage(_ message: [UInt8]) throws -> [UInt8] {
        guard privateKey != nil else {
            throw Ed25519Error.missingPrivateKey
        }
        let messageHash = KeyPair.calculateMessageHash(message)
        return sign(messageHash)
    }

    /// Signs a UTF-8 string message according to
    /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
    ///
    /// - Parameter message: The string message to sign (will be UTF-8 encoded).
    /// - Returns: A 64-byte Ed25519 signature.
    /// - Throws: `Ed25519Error.missingPrivateKey` if this keypair has no private key.
    public func signMessage(_ message: String) throws -> [UInt8] {
        return try signMessage([UInt8](message.utf8))
    }

    /// Verifies a binary message signature according to
    /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
    ///
    /// - Parameters:
    ///   - message: The original message bytes.
    ///   - signature: The 64-byte Ed25519 signature to verify.
    /// - Returns: `true` if the signature is valid, `false` otherwise.
    /// - Throws: `Ed25519Error.invalidSignatureLength` if signature is not 64 bytes.
    public func verifyMessage(_ message: [UInt8], signature: [UInt8]) throws -> Bool {
        let messageHash = KeyPair.calculateMessageHash(message)
        return try verify(signature: signature, message: messageHash)
    }

    /// Verifies a UTF-8 string message signature according to
    /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
    ///
    /// - Parameters:
    ///   - message: The original string message (will be UTF-8 encoded).
    ///   - signature: The 64-byte Ed25519 signature to verify.
    /// - Returns: `true` if the signature is valid, `false` otherwise.
    /// - Throws: `Ed25519Error.invalidSignatureLength` if signature is not 64 bytes.
    public func verifyMessage(_ message: String, signature: [UInt8]) throws -> Bool {
        return try verifyMessage([UInt8](message.utf8), signature: signature)
    }
}
