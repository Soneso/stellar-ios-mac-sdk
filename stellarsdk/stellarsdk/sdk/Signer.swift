//
//  Signer.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/27/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Utility class for creating signer keys used in multi-signature account configurations.
/// Supports ED25519 public keys, SHA256 hashes, pre-authorized transactions, and signed payloads.
public final class Signer: Sendable {

    /// Creates an ED25519 public key signer from a key pair.
    /// - Parameter keyPair: The key pair containing the public key to use as a signer.
    /// - Returns: A signer key representing the ED25519 public key.
    public static func ed25519PublicKey(keyPair:KeyPair) -> SignerKeyXDR {
        return SignerKeyXDR.ed25519(keyPair.publicKey.wrappedData32())
    }
    
    /// Creates an ED25519 public key signer from an account ID.
    /// - Parameter accountId: The Stellar account ID to use as a signer.
    /// - Returns: A signer key representing the ED25519 public key.
    public static func ed25519PublicKey(accountId:String) throws -> SignerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        return SignerKeyXDR.ed25519(pk.wrappedData32())
    }
    
    /// Creates a SHA256 hash signer for hash-based authorization.
    /// - Parameter hash: The SHA256 hash value to use as a signer.
    /// - Returns: A signer key representing the hash.
    public static func sha256Hash(hash:Data) -> SignerKeyXDR {
        let data = WrappedData32(hash)
        return SignerKeyXDR.hashX(data)
    }
    
    /// Creates a pre-authorized transaction signer that authorizes a specific transaction.
    /// - Parameters:
    ///   - transaction: The transaction to pre-authorize.
    ///   - network: The network on which the transaction will be submitted.
    /// - Returns: A signer key representing the pre-authorized transaction hash.
    public static func preAuthTx(transaction: Transaction, network: Network) throws -> SignerKeyXDR {
        let data = try transaction.getTransactionHashData(network: network)
        return SignerKeyXDR.preAuthTx(WrappedData32(data))
    }
    
    /// Creates a signed payload signer that combines an account ID with custom payload data (CAP-40).
    /// - Parameters:
    ///   - accountId: The Stellar account ID to use as the signer.
    ///   - payload: The custom payload data (max 64 bytes).
    /// - Returns: A signer key representing the signed payload.
    public static func signedPayload(accountId: String, payload: Data) throws -> SignerKeyXDR {
        if payload.count > StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD {
            throw StellarSDKError.invalidArgument(message: "invalid payload length, must be less than \(StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD)")
        }
        let pk = try PublicKey(accountId: accountId)
        return SignerKeyXDR.signedPayload(Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: payload))
    }
}
