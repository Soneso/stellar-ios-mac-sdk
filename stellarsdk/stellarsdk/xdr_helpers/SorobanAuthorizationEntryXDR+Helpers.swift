import Foundation

extension SorobanAuthorizationEntryXDR {

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanAuthorizationEntryXDR(from: xdrDecoder)
    }

    // MARK: - Preimage builder

    /// Builds the `HashIDPreimageXDR` for this entry from its credential arm.
    ///
    /// Arm selection:
    /// - `.address`  ->  `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION` (legacy, no address field).
    /// - `.addressV2` and `.addressWithDelegates`  ->
    ///   `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS` (protocol 27). The `address`
    ///   field in the preimage is always the top-level credential address, never a delegate's.
    ///
    /// The caller must set `signatureExpirationLedger` on the credentials before calling
    /// this method; the preimage is built from the current value in the credentials.
    ///
    /// - Throws: `StellarSDKError.invalidArgument` for `.sourceAccount` credentials.
    public func buildPreimage(network: Network) throws -> HashIDPreimageXDR {
        let networkIdBytes = network.networkId
        switch credentials {
        case .address(let creds):
            let preimageBody = HashIDPreimageSorobanAuthorizationXDR(
                networkID: WrappedData32(networkIdBytes),
                nonce: creds.nonce,
                signatureExpirationLedger: creds.signatureExpirationLedger,
                invocation: rootInvocation
            )
            return .sorobanAuthorization(preimageBody)

        case .addressV2(let creds):
            let preimageBody = HashIDPreimageSorobanAuthorizationWithAddressXDR(
                networkID: WrappedData32(networkIdBytes),
                nonce: creds.nonce,
                signatureExpirationLedger: creds.signatureExpirationLedger,
                address: creds.address,
                invocation: rootInvocation
            )
            return .sorobanAuthorizationWithAddress(preimageBody)

        case .addressWithDelegates(let withDelegates):
            let creds = withDelegates.addressCredentials
            let preimageBody = HashIDPreimageSorobanAuthorizationWithAddressXDR(
                networkID: WrappedData32(networkIdBytes),
                nonce: creds.nonce,
                signatureExpirationLedger: creds.signatureExpirationLedger,
                address: creds.address,
                invocation: rootInvocation
            )
            return .sorobanAuthorizationWithAddress(preimageBody)

        case .sourceAccount:
            throw StellarSDKError.invalidArgument(
                message: "Cannot build a signing preimage for source-account credentials"
            )
        }
    }

    // MARK: - Expiration

    /// Resolves the expiration ledger a new signature on this entry commits to.
    ///
    /// The entry stores one `signatureExpirationLedger` in its top-level address credentials,
    /// and every signature on the entry, top-level and delegate, commits to it through the
    /// shared preimage. Signing appends to a node's signature vector and never removes an
    /// earlier signature, so while any node carries a signature other than `.void` the
    /// stored value is the only one that keeps the entry valid.
    ///
    /// - Parameter requested: The expiration the caller asks for, or `nil` for none.
    /// - Returns: The stored expiration when a node carries a signature; otherwise
    ///   `requested`, where `nil` leaves the choice of a default to the caller.
    /// - Throws: `StellarSDKError.invalidArgument` when a node carries a signature and
    ///   `requested` differs from the stored expiration, or when the delegate tree nests
    ///   deeper than 128 levels.
    internal func signatureExpirationForNewSignature(requested: UInt32?) throws -> UInt32? {
        guard let creds = credentials.addressCredentials, try carriesSignature(topLevel: creds) else {
            return requested
        }
        let stored = creds.signatureExpirationLedger
        if let requested = requested, requested != stored {
            throw StellarSDKError.invalidArgument(
                message: "The authorization entry already carries a signature committed to signatureExpirationLedger \(stored); the requested expiration \(requested) would invalidate it. Pass \(stored) or omit the expiration."
            )
        }
        return stored
    }

    /// `true` when `topLevel`, the entry's top-level address credentials, or any delegate
    /// node carries a signature other than `.void`.
    private func carriesSignature(topLevel: SorobanAddressCredentialsXDR) throws -> Bool {
        if !topLevel.signature.isVoid { return true }
        guard case .addressWithDelegates(let withDelegates) = credentials else { return false }
        return try delegateTreeCarriesSignature(withDelegates.delegates)
    }

    // MARK: - Signing

    /// Signs this authorization entry with `signer` and stamps `signatureExpirationLedger`.
    ///
    /// All three address-credential arms are supported. The credential arm is preserved on
    /// write-back; the method never coerces one arm to another.
    ///
    /// Expiration is written into the credentials before the preimage is built, so the hash
    /// is computed over the final expiration value. This is required: the network reconstructs
    /// the preimage from the submitted credentials, so a preimage built from a stale value
    /// fails verification.
    ///
    /// **`forAddress` parameter**
    ///
    /// - `nil` (default): the signature is appended to the top-level credential node.
    /// - Non-nil strkey: the signature is appended to every node in the tree (top-level or
    ///   delegate, depth-first) whose XDR-encoded address matches the supplied strkey. Throws
    ///   when no node matches.
    ///
    /// **Signature write-back semantics**
    ///
    /// Appends the new `AccountEd25519Signature` to the node's existing signature vector.
    /// A `.void` signature becomes a one-element vector. The vector is never re-sorted;
    /// callers must supply signatures in ascending public-key order when G-address
    /// verification requires it (the host enforces strict ordering and a 20-signature cap).
    ///
    /// Calling `sign` repeatedly for the same signer and node appends repeatedly; callers
    /// must not double-sign, as duplicate signature elements cause host verification to fail.
    ///
    /// **Void top-level signature**
    ///
    /// A void top-level signature is legitimate for `WITH_DELEGATES` entries where only
    /// delegates sign. This method never rejects or fills in a void top-level signature;
    /// when `forAddress` points to a delegate, the top-level node is not modified.
    ///
    /// - Parameters:
    ///   - signer: Key pair that must include the private key.
    ///   - network: Network the entry targets.
    ///   - signatureExpirationLedger: Ledger at which the signature expires; `nil` keeps
    ///     the value stored in the credentials. While any node of the entry carries a
    ///     signature, only the stored value is accepted, because every signature on the
    ///     entry commits to it.
    ///   - forAddress: Optional strkey routing the signature to matching nodes only.
    ///     `nil` signs the top-level node.
    /// - Throws: `StellarSDKError.invalidArgument` for source-account credentials, when
    ///   the signer has no private key, when the credential address or `forAddress` is a
    ///   muxed account (M...) or muxed contract (W...) address, when `forAddress` matches no
    ///   node, or when `signatureExpirationLedger` differs from the stored value of an entry
    ///   that already carries a signature.
    public mutating func sign(
        signer: KeyPair,
        network: Network,
        signatureExpirationLedger: UInt32? = nil,
        forAddress: String? = nil
    ) throws {
        guard let credentialAddress = credentials.addressCredentials?.address else {
            throw StellarSDKError.invalidArgument(
                message: "credentials must be of an address type to sign"
            )
        }
        guard signer.privateKey != nil else {
            throw StellarSDKError.invalidArgument(
                message: "signer KeyPair must contain the private key to be able to sign"
            )
        }
        if let refusal = try muxedCredentialAddressRefusal(credentialAddress) {
            throw StellarSDKError.invalidArgument(message: refusal)
        }
        let target = try forAddress.map { (strkey: $0, address: try scAddressXDR(fromStrkey: $0)) }

        // Stamp expiration into credentials before hashing.
        if let expLedger = try signatureExpirationForNewSignature(requested: signatureExpirationLedger) {
            guard var creds = credentials.addressCredentials else {
                throw StellarSDKError.invalidArgument(message: "signing requires address-type credentials")
            }
            creds.signatureExpirationLedger = expLedger
            credentials = try credentials.withAddressCredentials(creds)
        }

        // Build and hash the preimage (reads the now-updated expiration).
        let preimage = try buildPreimage(network: network)
        let encoded = try XDREncoder.encode(preimage)
        let payload = Data(bytes: encoded, count: encoded.count).sha256Hash
        let sigBytes = signer.sign([UInt8](payload))
        let accountSig = AccountEd25519Signature(publicKey: signer.publicKey, signature: sigBytes)
        let sigVal = SCValXDR(accountEd25519Signature: accountSig)

        if let target {
            // Route signature to matching nodes.
            var didSign = false

            // Check top-level node.
            if let topCreds = credentials.addressCredentials,
               sorobanAddressXDREqual(topCreds.address, target.address) {
                var creds = topCreds
                creds.appendSignature(signature: sigVal)
                credentials = try credentials.withAddressCredentials(creds)
                didSign = true
            }

            // Check delegate nodes (only present for WITH_DELEGATES).
            if case .addressWithDelegates(var withDelegates) = credentials {
                let result = try appendSignatureToMatchingDelegates(
                    nodes: &withDelegates.delegates,
                    targetAddress: target.address,
                    signature: sigVal
                )
                if result == .found {
                    credentials = .addressWithDelegates(withDelegates)
                    didSign = true
                }
            }

            if !didSign {
                throw StellarSDKError.invalidArgument(
                    message: "forAddress '\(target.strkey)' does not match any node in this authorization entry"
                )
            }
        } else {
            // Sign the top-level credential node.
            guard var creds = credentials.addressCredentials else {
                throw StellarSDKError.invalidArgument(message: "signing requires address-type credentials")
            }
            creds.appendSignature(signature: sigVal)
            credentials = try credentials.withAddressCredentials(creds)
        }
    }

    // MARK: - Delegate tree builder

    /// Constructs a new `WITH_DELEGATES` authorization entry from an `ADDRESS` or
    /// `ADDRESS_V2` entry plus a set of delegate descriptors (CAP-71, protocol 27).
    ///
    /// The returned entry carries the `SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES` arm.
    /// Calling this on an entry that already carries `WITH_DELEGATES` credentials throws;
    /// build from an `ADDRESS` or `ADDRESS_V2` source instead.
    ///
    /// **Sorting and deduplication**
    ///
    /// Every delegate array (top-level and each `nestedDelegates` recursively) is sorted
    /// ascending by the lexicographic order of the complete XDR-encoded bytes of
    /// `SCAddress`. This ordering is required by the host: strkey ordering is different
    /// (contracts sort before accounts by string; XDR encoding places accounts first with
    /// discriminant 0). Duplicate addresses within one array are rejected; the same address
    /// at different nesting levels is legal.
    ///
    /// **Top-level signature**
    ///
    /// The top-level signature in `addressCredentials` is reset to `.void`. Use
    /// `sign(signer:network:signatureExpirationLedger:)` to add signatures after building
    /// the tree.
    ///
    /// **Nonce and expiration**
    ///
    /// The nonce and address are copied from the source entry's inner credentials.
    /// `signatureExpirationLedger` in `addressCredentials` is set to `expirationLedger`;
    /// delegates carry no nonce or expiration (only the top-level credentials do).
    ///
    /// - Parameters:
    ///   - entry: Source `ADDRESS` or `ADDRESS_V2` entry. Must not be `WITH_DELEGATES`.
    ///   - delegates: Top-level delegate descriptors.
    ///   - expirationLedger: Ledger at which the signature expires; stamped into the
    ///     `addressCredentials` of the returned entry.
    /// - Returns: New authorization entry with `WITH_DELEGATES` credentials.
    /// - Throws: `StellarSDKError.invalidArgument` when `entry` is already
    ///   `WITH_DELEGATES`, has source-account credentials or a muxed credential address,
    ///   when a delegate address is a muxed account (M...) or muxed contract (W...) address,
    ///   or when a delegate array contains duplicate addresses.
    public static func withDelegates(
        entry: SorobanAuthorizationEntryXDR,
        delegates: [SorobanDelegateDescriptor],
        expirationLedger: UInt32
    ) throws -> SorobanAuthorizationEntryXDR {
        guard let sourceCreds = entry.credentials.addressCredentials else {
            throw StellarSDKError.invalidArgument(
                message: "withDelegates: source entry must have address-type credentials"
            )
        }
        if case .addressWithDelegates = entry.credentials {
            throw StellarSDKError.invalidArgument(
                message: "withDelegates: source entry already carries WITH_DELEGATES credentials; build from an ADDRESS or ADDRESS_V2 entry"
            )
        }
        if let refusal = try muxedCredentialAddressRefusal(sourceCreds.address) {
            throw StellarSDKError.invalidArgument(message: refusal)
        }

        // Build delegate XDR nodes, sorting and validating each array recursively.
        let delegateNodes: [SorobanDelegateSignatureXDR] = try delegates.map {
            try delegateSignatureXDR(from: $0)
        }
        let sortedDelegates = try sortAndValidateDelegates(delegateNodes)

        // Copy address and nonce; stamp expiration; reset signature to void.
        var newCreds = sourceCreds
        newCreds.signatureExpirationLedger = expirationLedger
        newCreds.signature = .void

        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: newCreds,
            delegates: sortedDelegates
        )

        return SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(withDelegates),
            rootInvocation: entry.rootInvocation
        )
    }
}

// MARK: - Muxed addresses in Soroban auth

/// The text refusing a muxed account or muxed contract address, `strKey`, where Soroban auth
/// takes an account or contract address. A credential address adds the hint to the address
/// that takes its place.
internal func muxedAuthAddressMessage(_ strKey: String, credential: Bool = false) -> String {
    let refusal = "Muxed account (M...) and muxed contract (W...) addresses are not valid Soroban auth"
    guard credential else {
        return "\(refusal) addresses: \(strKey)"
    }
    return "\(refusal) credential addresses: \(strKey); use the underlying G... or C... address instead"
}

/// The text refusing `strKey` as a Soroban auth address, nil unless it is a muxed account
/// (M...) or muxed contract (W...) strkey.
internal func muxedAuthAddressRefusal(strKey: String) -> String? {
    guard strKey.isValidMed25519PublicKey() || strKey.isValidMuxedContractId() else {
        return nil
    }
    return muxedAuthAddressMessage(strKey)
}

/// The text refusing `address` as the address of Soroban auth credentials, nil for every
/// address that is not muxed.
///
/// The host names accounts and contracts in credentials; a muxed account (M...) or muxed
/// contract (W...) address there makes an entry no signature can authorize.
internal func muxedCredentialAddressRefusal(_ address: SCAddressXDR) throws -> String? {
    switch address {
    case .muxedAccount, .muxedContract:
        return muxedAuthAddressMessage(try address.toStrKey(), credential: true)
    case .account, .contract, .claimableBalanceId, .liquidityPoolId:
        return nil
    }
}

/// Throws for the first entry whose credential address is a muxed account (M...) or muxed
/// contract (W...) address. Helpers that sign a list of entries run it before they stamp an
/// expiration or hand an entry to a caller's callback.
internal func requireUnmuxedCredentialAddresses(_ entries: [SorobanAuthorizationEntryXDR]) throws {
    for entry in entries {
        if let address = entry.credentials.addressCredentials?.address,
           let refusal = try muxedCredentialAddressRefusal(address) {
            throw StellarSDKError.invalidArgument(message: refusal)
        }
    }
}
