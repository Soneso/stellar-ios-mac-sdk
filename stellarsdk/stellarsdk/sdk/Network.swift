//
//  Network.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 19/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar network and its network passphrase.
///
/// Each Stellar network (public, testnet, futurenet, or custom) has a unique network passphrase
/// that is used to derive transaction IDs. The network passphrase is hashed together with the
/// transaction envelope to ensure transactions created for one network cannot be replayed on
/// another network.
///
/// You must specify the correct network when building and submitting transactions. Using the
/// wrong network passphrase will result in transaction rejection.
///
/// Example:
/// ```swift
/// // Build transaction for public network
/// let transaction = try Transaction(
///     sourceAccount: account,
///     operations: [operation],
///     memo: .none
/// )
/// try transaction.sign(keyPair: keyPair, network: .public)
///
/// // Build transaction for testnet
/// try transaction.sign(keyPair: keyPair, network: .testnet)
///
/// // Build transaction for custom network
/// try transaction.sign(keyPair: keyPair, network: .custom(passphrase: "My Custom Network"))
/// ```
///
/// See also:
/// - [Transaction Signatures](https://developers.stellar.org/docs/encyclopedia/security/signatures-multisig)
/// - [Network Passphrases](https://developers.stellar.org/docs/encyclopedia/network-configuration/network-passphrases)
public enum Network {
    /// The Stellar public network (mainnet) - "Public Global Stellar Network ; September 2015"
    case `public`

    /// The Stellar test network - "Test SDF Network ; September 2015"
    case testnet

    /// The Stellar future network for testing upcoming features - "Test SDF Future Network ; October 2022"
    case futurenet

    /// A custom network with a user-defined passphrase
    case custom(passphrase: String)
}

// MARK: passphrase, Network Id

public extension Network {

    /// The SHA256 hash of the network passphrase.
    ///
    /// This network ID is used when signing transactions and verifying signatures.
    /// It ensures that transactions cannot be replayed across different networks.
    var networkId: Data {
        return passphrase.sha256Hash
    }

    /// The network passphrase string for this network.
    ///
    /// Returns the standard passphrase for Stellar's public, testnet, or futurenet,
    /// or the custom passphrase for custom networks.
    var passphrase: String {
        switch self {
        case .public:
            return "Public Global Stellar Network ; September 2015"
        case .testnet:
            return "Test SDF Network ; September 2015"
        case .futurenet:
            return "Test SDF Future Network ; October 2022"
        case .custom(let passphrase):
            return passphrase
        }
    }
}

