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

    public init(contractId: String) throws {
        var contractIdHex = contractId
        if contractId.hasPrefix("C") {
            contractIdHex = try contractId.decodeContractIdToHex()
        }
        if let contractIdData = contractIdHex.data(using: .hexadecimal) {
            self = .contract(WrappedData32(contractIdData))
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid contract id")
        }
    }

    public init(claimableBalanceId: String) throws {
        self = .claimableBalanceId(try ClaimableBalanceIDXDR(claimableBalanceId: claimableBalanceId))
    }

    public init(liquidityPoolId: String) throws {
        var liquidityPoolIdHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L") {
            liquidityPoolIdHex = try liquidityPoolId.decodeLiquidityPoolIdToHex()
        }
        if let _ = liquidityPoolIdHex.data(using: .hexadecimal) {
            self = .liquidityPoolId(liquidityPoolIdHex.wrappedData32FromHex())
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid liquidity pool id")
        }
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

    public var claimableBalanceId: String? {
        switch self {
        case .claimableBalanceId(let xdr):
            return xdr.claimableBalanceIdString
        default:
            return nil
        }
    }

    public func getClaimableBalanceIdStrKey() throws -> String? {
        switch self {
        case .claimableBalanceId(let xdr):
            return try xdr.claimableBalanceIdString.encodeClaimableBalanceIdHex()
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
