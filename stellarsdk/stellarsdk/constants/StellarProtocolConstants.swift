//
//  StellarProtocolConstants.swift
//  stellarsdk
//
//  Created on 30.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Constants defined by the Stellar protocol specification.
/// These values represent core protocol limits, sizes, and validation constraints
/// used throughout the Stellar network.
///
/// Reference: https://developers.stellar.org/docs/
public struct StellarProtocolConstants {

    // MARK: - Ed25519 Cryptographic Sizes

    /// Size of an Ed25519 public key in bytes (32 bytes)
    /// Reference: https://ed25519.cr.yp.to/
    public static let ED25519_PUBLIC_KEY_SIZE = 32

    /// Size of an Ed25519 seed in bytes (32 bytes)
    /// Reference: https://ed25519.cr.yp.to/
    public static let ED25519_SEED_SIZE = 32

    /// Size of an Ed25519 private key in bytes (64 bytes)
    /// Reference: https://ed25519.cr.yp.to/
    public static let ED25519_PRIVATE_KEY_SIZE = 64

    /// Size of an Ed25519 signature in bytes (64 bytes)
    /// Reference: https://ed25519.cr.yp.to/
    public static let ED25519_SIGNATURE_SIZE = 64

    // MARK: - Hash Sizes

    /// Size of SHA-256 hash in bytes (32 bytes)
    /// Reference: https://en.wikipedia.org/wiki/SHA-2
    public static let SHA256_HASH_SIZE = 32

    // MARK: - StrKey Encoding Structure

    /// Size of the version byte in StrKey encoding (1 byte)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_VERSION_BYTE_SIZE = 1

    /// Size of the CRC-16 checksum in StrKey encoding (2 bytes)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_CHECKSUM_SIZE = 2

    /// Total overhead size in StrKey encoding (version byte + checksum = 3 bytes)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_OVERHEAD_SIZE = 3

    // MARK: - StrKey Encoded String Lengths

    /// Standard StrKey encoded string length for ed25519PublicKey, ed25519SecretSeed,
    /// preAuthTX, sha256Hash, contract, and liquidityPool (56 characters)
    /// Calculation: (1 version + 32 data + 2 checksum) bytes × 8 bits ÷ 5 bits/char = 56 chars
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_ENCODED_LENGTH_STANDARD = 56

    /// StrKey encoded string length for muxed account (med25519PublicKey) (69 characters)
    /// Calculation: (1 version + 40 data + 2 checksum) bytes × 8 bits ÷ 5 bits/char = 69 chars
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_ENCODED_LENGTH_MUXED = 69

    /// StrKey encoded string length for claimable balance (58 characters)
    /// Calculation: (1 version + 33 data + 2 checksum) bytes × 8 bits ÷ 5 bits/char = 58 chars
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_ENCODED_LENGTH_CLAIMABLE_BALANCE = 58

    /// Minimum StrKey encoded string length for signed payload (69 characters)
    /// This is the minimum because signed payloads encode:
    /// - 32 bytes for the signer public key
    /// - 4 bytes for the payload length field
    /// - 4 bytes minimum payload
    /// Total: (1 version + 40 data + 2 checksum) bytes × 8 bits ÷ 5 bits/char = 69 chars
    ///
    /// Note: This fixes an issue found in the Flutter SDK where it was incorrectly set to 56.
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    /// See also: https://github.com/Soneso/stellar_flutter_sdk/pull/116
    public static let STRKEY_SIGNED_PAYLOAD_MIN_LENGTH = 69

    /// Maximum StrKey encoded string length for signed payload (165 characters)
    /// Maximum payload size is 64 bytes, so:
    /// Total: (1 version + 32 key + 4 length + 64 payload + 2 checksum) bytes × 8 bits ÷ 5 bits/char = 165 chars
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let STRKEY_ENCODED_LENGTH_SIGNED_PAYLOAD_MAX = 165

    // MARK: - StrKey Decoded Payload Sizes

    /// Standard decoded payload size for StrKey types (32 bytes)
    /// Used for: ed25519PublicKey, ed25519SecretSeed, preAuthTX, sha256Hash, contract, liquidityPool
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_DECODED_SIZE_STANDARD = 32

    /// Decoded payload size for muxed account (40 bytes = 32 bytes key + 8 bytes ID)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_DECODED_SIZE_MUXED = 40

    /// Size of the muxed account ID field (8 bytes)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let MUXED_ACCOUNT_ID_SIZE = 8

    /// Size of the signer public key in a signed payload (32 bytes)
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let SIGNED_PAYLOAD_SIGNER_SIZE = 32

    /// Size of the payload length field in a signed payload (4 bytes)
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let SIGNED_PAYLOAD_SIZE_FIELD = 4

    /// Minimum payload size in a signed payload (4 bytes)
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let SIGNED_PAYLOAD_MIN_PAYLOAD = 4

    /// Maximum payload size in a signed payload (64 bytes)
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let SIGNED_PAYLOAD_MAX_PAYLOAD = 64

    /// Size of the claimable balance type discriminant (1 byte)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/claimable-balance
    public static let CLAIMABLE_BALANCE_DISCRIMINANT_SIZE = 1

    // MARK: - Version Byte Encoding

    /// Bit shift amount used in version byte encoding (3 bits)
    /// The base value is shifted left by 3 to produce the final version byte
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let VERSION_BYTE_SHIFT = 3

    /// Base value for ed25519 public key version byte (6, shifted becomes 48)
    /// Results in 'G' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let ED25519_PUBLIC_KEY_BASE = 6

    /// Base value for muxed ed25519 public key version byte (12, shifted becomes 96)
    /// Results in 'M' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let MED25519_PUBLIC_KEY_BASE = 12

    /// Base value for ed25519 secret seed version byte (18, shifted becomes 144)
    /// Results in 'S' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let ED25519_SECRET_SEED_BASE = 18

    /// Base value for pre-authorized transaction version byte (19, shifted becomes 152)
    /// Results in 'T' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let PREAUTH_TX_BASE = 19

    /// Base value for SHA-256 hash version byte (23, shifted becomes 184)
    /// Results in 'X' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let SHA256_HASH_BASE = 23

    /// Base value for signed payload version byte (15, shifted becomes 120)
    /// Results in 'P' prefix when encoded in Base32
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let SIGNED_PAYLOAD_BASE = 15

    /// Base value for contract version byte (2, shifted becomes 16)
    /// Results in 'C' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/learn/smart-contract-internals/contract-interactions/stellar-transaction
    public static let CONTRACT_BASE = 2

    /// Base value for liquidity pool version byte (11, shifted becomes 88)
    /// Results in 'L' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/liquidity-pool
    public static let LIQUIDITY_POOL_BASE = 11

    /// Base value for claimable balance version byte (1, shifted becomes 8)
    /// Results in 'B' prefix when encoded in Base32
    /// Reference: https://developers.stellar.org/docs/encyclopedia/claimable-balance
    public static let CLAIMABLE_BALANCE_BASE = 1

    // MARK: - Asset Code Limits

    /// Minimum asset code length (1 character)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/assets
    public static let ASSET_CODE_MIN_LENGTH = 1

    /// Maximum asset code length for AlphaNum4 assets (4 characters)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/assets
    public static let ASSET_CODE_ALPHANUM4_MAX_LENGTH = 4

    /// Minimum asset code length for AlphaNum12 assets (5 characters)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/assets
    public static let ASSET_CODE_ALPHANUM12_MIN_LENGTH = 5

    /// Maximum asset code length for AlphaNum12 assets (12 characters)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/assets
    public static let ASSET_CODE_ALPHANUM12_MAX_LENGTH = 12

    // MARK: - Asset Canonical Form

    /// Canonical form identifier for the native asset (XLM)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/assets
    public static let ASSET_CANONICAL_NATIVE = "native"

    // MARK: - Memo Limits

    /// Maximum length for MEMO_TEXT in bytes (28 bytes)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/operations-and-transactions
    public static let MEMO_TEXT_MAX_LENGTH = 28

    /// Size of MEMO_HASH in bytes (32 bytes)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/operations-and-transactions
    public static let MEMO_HASH_SIZE = 32

    /// Size of MEMO_RETURN_HASH in bytes (32 bytes)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/operations-and-transactions
    public static let MEMO_RETURN_HASH_SIZE = 32

    // MARK: - Transaction Limits

    /// Maximum number of operations allowed in a single transaction (100 operations)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/transactions
    public static let MAX_OPERATIONS_PER_TRANSACTION = 100

    /// Maximum length for account home domain (32 characters)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/account
    public static let HOME_DOMAIN_MAX_LENGTH = 32

    // MARK: - Transaction Constants

    /// Minimum base fee for a transaction in stroops (100 stroops = 0.00001 XLM)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/fees-surge-pricing-fee-strategies
    public static let MIN_BASE_FEE: UInt32 = 100

    // MARK: - Signed Payload

    /// Maximum length for signed payload data (64 bytes)
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let SIGNED_PAYLOAD_MAX_LENGTH = 64

    // MARK: - Signature Hint

    /// Size of the signature hint (last 4 bytes of the public key or payload)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/signatures-multisig
    public static let SIGNATURE_HINT_SIZE = 4

    // MARK: - ManageData Operation

    /// Maximum length for data entry name in ManageData operation (64 bytes)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/list-of-operations#manage-data
    public static let MANAGE_DATA_NAME_MAX_LENGTH = 64

    /// Maximum length for data entry value in ManageData operation (64 bytes)
    /// Reference: https://developers.stellar.org/docs/fundamentals-and-concepts/list-of-operations#manage-data
    public static let MANAGE_DATA_VALUE_MAX_LENGTH = 64

    // MARK: - SetOptions Thresholds

    /// Minimum value for account thresholds (0)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/signatures-multisig#thresholds
    public static let THRESHOLD_MIN: UInt32 = 0

    /// Maximum value for account thresholds (255)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/signatures-multisig#thresholds
    public static let THRESHOLD_MAX: UInt32 = 255

    /// Byte mask for signer weight (0xFF = 255)
    /// Ensures signer weight is in the valid range (0-255)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/signatures-multisig
    public static let SIGNER_WEIGHT_MASK: UInt32 = 0xFF

    // MARK: - Claimable Balance

    /// Size of a claimable balance ID (32 bytes)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/claimable-balance
    public static let CLAIMABLE_BALANCE_ID_SIZE = 32

    // MARK: - Liquidity Pool

    /// Liquidity pool fee in basis points for protocol version 18+ (30 basis points = 0.30%)
    /// Reference: https://developers.stellar.org/docs/encyclopedia/liquidity-on-stellar-sdex-liquidity-pools
    public static let LIQUIDITY_POOL_FEE_V18: Int32 = 30

    // MARK: - StrKey Prefixes

    /// StrKey prefix for account addresses (public keys)
    /// Encoded addresses start with 'G'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_PREFIX_ACCOUNT = "G"

    /// StrKey prefix for secret seeds
    /// Encoded seeds start with 'S'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_PREFIX_SEED = "S"

    /// StrKey prefix for muxed accounts
    /// Encoded muxed accounts start with 'M'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_PREFIX_MUXED = "M"

    /// StrKey prefix for pre-authorized transactions
    /// Encoded pre-auth TX start with 'T'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_PREFIX_PREAUTH_TX = "T"

    /// StrKey prefix for hash-x signers
    /// Encoded hash-x start with 'X'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/strkey
    public static let STRKEY_PREFIX_HASH_X = "X"

    /// StrKey prefix for signed payload signers
    /// Encoded signed payloads start with 'P'
    /// Reference: CAP-40 https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md
    public static let STRKEY_PREFIX_SIGNED_PAYLOAD = "P"

    /// StrKey prefix for contract addresses
    /// Encoded contracts start with 'C'
    /// Reference: https://developers.stellar.org/docs/learn/smart-contract-internals/contract-interactions/stellar-transaction
    public static let STRKEY_PREFIX_CONTRACT = "C"

    /// StrKey prefix for liquidity pool IDs
    /// Encoded liquidity pools start with 'L'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/liquidity-pool
    public static let STRKEY_PREFIX_LIQUIDITY_POOL = "L"

    /// StrKey prefix for claimable balance IDs
    /// Encoded claimable balances start with 'B'
    /// Reference: https://developers.stellar.org/docs/encyclopedia/claimable-balance
    public static let STRKEY_PREFIX_CLAIMABLE_BALANCE = "B"
}
