import Foundation

extension SCAddressXDR {
    public init(accountId: String) throws {
        if accountId.hasPrefix("G") {
            self = .account(try PublicKey(accountId: accountId))
            return
        } else if accountId.hasPrefix("M") {
            let muxl = try accountId.decodeMuxedAccount()
            switch muxl {
            case .med25519(let inner):
                self = .muxedAccount(inner)
                return
            default:
                break
            }
        }
        throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid account id")
    }

    /// Creates a contract address from a "C..." strkey contract id or from the 64 character
    /// hex of the 32 byte id.
    ///
    /// - Throws: KeyUtilsError if a "C..." strkey is malformed,
    /// StellarSDKError.invalidArgument if a hex id is not exactly 64 hexadecimal characters
    public init(contractId: String) throws {
        var contractIdHex = contractId
        // "C" is a hexadecimal digit, so only a string of the strkey's exact length reads
        // as a strkey; a 64 character hex id may lead with "C" too.
        if contractId.hasPrefix("C")
            && contractId.count == StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD {
            contractIdHex = try contractId.decodeContractIdToHex()
        }
        self = .contract(try contractIdHex.wrappedData32FromHex(idKind: "contract id"))
    }

    public init(claimableBalanceId: String) throws {
        self = .claimableBalanceId(try ClaimableBalanceIDXDR(claimableBalanceId: claimableBalanceId))
    }

    /// Creates a liquidity pool address from an "L..." strkey pool id or from the 64 character
    /// hex of the 32 byte id.
    ///
    /// - Throws: KeyUtilsError if an "L..." strkey is malformed,
    /// StellarSDKError.invalidArgument if a hex id is not exactly 64 hexadecimal characters
    public init(liquidityPoolId: String) throws {
        var liquidityPoolIdHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L") {
            liquidityPoolIdHex = try liquidityPoolId.decodeLiquidityPoolIdToHex()
        }
        self = .liquidityPoolId(try liquidityPoolIdHex.wrappedData32FromHex(idKind: "liquidity pool id"))
    }

    public var accountId: String? {
        switch self {
        case .account(let pk):
            return pk.accountId
        case .muxedAccount(let xdr):
            if !xdr.accountId.isEmpty {
                return xdr.accountId
            }
            return nil
        default:
            return nil
        }
    }

    public var contractId: String? {
        switch self {
        case .contract(let data):
            return data.wrapped.base16EncodedString()
        default:
            return nil
        }
    }

    /// The claimable balance id this address names, nil for an address of any other kind.
    ///
    /// The id comes in the 72-character form Horizon serves: the four-byte big-endian union
    /// discriminant ahead of the 32-byte hash.
    public var claimableBalanceId: String? {
        switch self {
        case .claimableBalanceId(let xdr):
            return xdr.paddedBalanceIdHex
        default:
            return nil
        }
    }

    /// The claimable balance id this address names as its "B..." strkey, nil for an address
    /// of any other kind.
    public func getClaimableBalanceIdStrKey() throws -> String? {
        switch self {
        case .claimableBalanceId(let xdr):
            return try xdr.paddedBalanceIdHex.encodeClaimableBalanceIdHex()
        default:
            return nil
        }
    }

    public var liquidityPoolId: String? {
        switch self {
        case .liquidityPoolId(let data):
            return data.wrapped.base16EncodedString()
        default:
            return nil
        }
    }
}
