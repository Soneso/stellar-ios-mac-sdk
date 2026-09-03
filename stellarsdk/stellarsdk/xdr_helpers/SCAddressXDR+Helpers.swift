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

extension SCAddressXDR {

    /// The strkey this address spells.
    ///
    /// Every address kind has one: an account gives its "G..." key, a muxed account its
    /// "M...", a contract its "C...", a claimable balance its "B..." and a liquidity pool
    /// its "L...". The `contractId`, `claimableBalanceId` and `liquidityPoolId` accessors
    /// read the same ids as hex.
    ///
    /// - Returns: the strkey of the address
    /// - Throws: XdrJsonError.invalidValue if the payload bytes have no strkey encoding.
    /// A decoded address always has one.
    public func toStrKey() throws -> String {
        let encoded: XdrJsonValue
        // Each arm names its own encoder, so an address kind added later has to be given
        // its strkey here before this file compiles again.
        switch self {
        case .account(let account):
            encoded = try account.toXdrJsonValue()
        case .contract(let contract):
            encoded = try ContractIDXDRJsonCodec.toXdrJsonValue(contract, type: "SCAddressXDR", key: "contract")
        case .muxedAccount(let muxedAccount):
            encoded = try muxedAccount.toXdrJsonValue()
        case .claimableBalanceId(let balance):
            encoded = try balance.toXdrJsonValue()
        case .liquidityPoolId(let pool):
            encoded = try PoolIDXDRJsonCodec.toXdrJsonValue(pool, type: "SCAddressXDR", key: "liquidity_pool")
        }
        return try XdrJson.string(encoded, type: "SCAddressXDR")
    }
}
