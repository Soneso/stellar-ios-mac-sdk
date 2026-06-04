//
//  AllowCredential.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// A credential descriptor pairing a credential ID with optional transport hints.
///
/// Used in `WebAuthnProvider.authenticate` to constrain which passkeys the authenticator
/// offers and to indicate how the client can reach the authenticator (e.g., `internal`,
/// `hybrid`, `usb`, `ble`, `nfc`). Including transport hints enables cross-device
/// authentication flows such as QR-code scanning.
///
/// When `transports` is `nil`, the authenticator uses its default transport selection.
/// Unknown transport strings are passed through without validation — the OS
/// ignores values it does not recognize.
///
/// Equality compares the `id` byte content (not reference identity) so two descriptors built
/// from independently allocated `Data` values with the same bytes compare equal.
///
/// Example:
/// ```swift
/// let cred = AllowCredential(id: credentialIdData, transports: ["internal", "hybrid"])
/// let result = try await provider.authenticate(challenge: challenge, allowCredentials: [cred])
/// ```
public struct AllowCredential: Equatable, Hashable, Sendable {

    /// The raw credential ID bytes.
    public let id: Data

    /// Optional list of transport hints (e.g., `internal`, `hybrid`, `usb`, `ble`, `nfc`).
    public let transports: [String]?

    /// Creates an `AllowCredential` with the given credential ID and optional transports.
    ///
    /// - Parameters:
    ///   - id: Raw credential ID bytes.
    ///   - transports: Optional list of WebAuthn transport hints. `nil` lets the authenticator
    ///     select a transport.
    public init(id: Data, transports: [String]? = nil) {
        self.id = id
        self.transports = transports
    }

    public static func fromId(_ id: Data) -> AllowCredential {
        return AllowCredential(id: id)
    }

    public static func fromIds(_ ids: [Data]) -> [AllowCredential] {
        return ids.map { fromId($0) }
    }
}
