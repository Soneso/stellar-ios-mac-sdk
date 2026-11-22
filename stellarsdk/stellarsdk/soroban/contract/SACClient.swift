//
//  SACClient.swift
//  stellarsdk
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Typed client for a Stellar Asset Contract (SAC).
///
/// A Stellar Asset Contract is the token contract built into the network for a classic asset,
/// the native asset (XLM) included. Its id derives from the asset and the network
/// (``Asset/contractId(network:)``), and it has no wasm on chain, so the client carries the
/// contract spec itself (``specEntries()``) and opens without an RPC request.
///
/// Opening a client:
/// - ``forAsset(asset:sourceAccountKeyPair:network:rpcUrl:urlSession:)`` and
///   ``forContractId(contractId:sourceAccountKeyPair:network:rpcUrl:urlSession:)`` open a
///   client for a source account. Its keypair signs the transactions the client submits, and
///   the account must exist, because building a transaction reads its sequence number.
/// - ``readOnlyForAsset(asset:network:rpcUrl:urlSession:)`` and
///   ``readOnlyForContractId(contractId:network:rpcUrl:urlSession:)`` open a read-only client,
///   which needs no keypair and no account. Its transactions name the placeholder source
///   account ``READ_ONLY_SOURCE_ACCOUNT_ID``, the all-zero ed25519 public key, for which no
///   secret key exists. They simulate, and they allow
///   ``AssembledTransaction/signAuthEntries(signerKeyPair:authorizeEntryCallback:validUntilLedgerSeq:)``
///   with an authorizing account's keypair, but they refuse to sign their envelope, to
///   submit, and to restore archived entries.
///
/// Amounts are base units, the smallest unit of the asset: a token has 7 decimals, so one
/// token is 10,000,000 base units. The contract counts them as a signed 128-bit integer, which
/// this client takes and returns as a decimal `String`. ``toBaseUnits(_:)`` converts a decimal
/// amount such as `"12.5"`.
///
/// The reads ``balance(holder:)``, ``decimals()``, ``name()`` and ``symbol()`` only simulate:
/// they never sign, submit, or restore, on either kind of client. A missing account or
/// trustline surfaces as the contract's error, never as a zero balance.
///
/// The writes take `methodOptions` for the fee, the timeout, and the simulation.
/// ``transfer(from:to:amount:methodOptions:)`` returns the transaction, simulated by default,
/// for the caller to authorize, sign, and send. ``transferAndSend(to:amount:methodOptions:)``
/// transfers from the client's source account, signs, sends, and waits for the result. With
/// `simulate: false`, ``transfer(from:to:amount:methodOptions:)`` returns an unsimulated
/// transaction and ``transferAndSend(to:amount:methodOptions:)`` throws; call `simulate()` on
/// the returned transaction before inspecting or completing authorization entries.
///
/// The other functions of the contract, such as `approve` or `mint`, go through
/// ``sorobanClient`` and its `buildInvokeMethodTx`, like the functions of any contract a
/// ``SorobanClient`` opens.
///
/// ```swift
/// let reader = try SACClient.readOnlyForAsset(asset: asset,
///                                             network: Network.testnet,
///                                             rpcUrl: "https://soroban-testnet.stellar.org")
/// let balance = try await reader.balance(holder: try SCAddressXDR(accountId: accountId))
///
/// let client = try SACClient.forAsset(asset: asset,
///                                     sourceAccountKeyPair: senderKeyPair,
///                                     network: Network.testnet,
///                                     rpcUrl: "https://soroban-testnet.stellar.org")
/// let response = try await client.transferAndSend(to: try SCAddressXDR(accountId: receiverId),
///                                                 amount: try SACClient.toBaseUnits("12.5"))
/// ```
public final class SACClient: Sendable {

    /// The source account of the transactions a read-only client builds: the account id of
    /// the all-zero ed25519 public key.
    ///
    /// No secret key produces this public key, so nobody can sign for the account, and a
    /// simulation needs no account entry for its source.
    public static let READ_ONLY_SOURCE_ACCOUNT_ID = "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"

    /// The id of the contract as its "C..." strkey.
    public let contractId: String

    /// The client this one wraps. It builds transactions for the functions of the contract
    /// that have no typed method here, with the same source account and the same read-only
    /// state.
    public let sorobanClient: SorobanClient

    /// Whether the client was opened without a keypair.
    private let readOnly: Bool

    /// The account id of the source account of the client's transactions.
    private let sourceAccountId: String

    private static let subject = "The contract to invoke"
    private static let maxI128Digits = Array("170141183460469231731687303715884105727".utf8)
    private static let fractionDigits = 7

    private init(contractId: String, sorobanClient: SorobanClient, readOnly: Bool, sourceAccountId: String) {
        self.contractId = contractId
        self.sorobanClient = sorobanClient
        self.readOnly = readOnly
        self.sourceAccountId = sourceAccountId
    }

    // MARK: - Spec

    /// The spec entries of the Stellar Asset Contract, decoded from the embedded ``SACSpec``.
    ///
    /// Every call decodes afresh and checks the embedded bytes: their sha256 against
    /// ``SACSpec/SHA256``, and that every entry decodes and encodes again to the bytes it was
    /// read from.
    ///
    /// - Returns: The entries in the order of the embedded spec: one per contract function
    ///   and one per contract event.
    /// - Throws: `StellarSDKError.xdrDecodingError` when the embedded spec is not valid
    ///   base64, has another sha256, or holds an entry that does not decode or does not
    ///   re-encode to its bytes.
    public static func specEntries() throws -> [SCSpecEntryXDR] {
        return try decodeSpec(base64: SACSpec.XDR_BASE64, sha256Hex: SACSpec.SHA256)
    }

    /// Decodes `base64` as a sequence of spec entries whose bytes have the sha256 `sha256Hex`
    /// in lowercase hex.
    ///
    /// The XDR decoder skips the padding bytes of strings and data unchecked, so every entry
    /// is encoded again and compared with the bytes it was read from.
    ///
    /// - Throws: `StellarSDKError.xdrDecodingError` as ``specEntries()`` describes.
    internal static func decodeSpec(base64: String, sha256Hex: String) throws -> [SCSpecEntryXDR] {
        guard let bytes = Data(base64Encoded: base64) else {
            throw StellarSDKError.xdrDecodingError(message: "The embedded SAC spec is not valid base64")
        }
        let actualSha256Hex = bytes.sha256Hash.base16EncodedString()
        guard actualSha256Hex == sha256Hex else {
            throw StellarSDKError.xdrDecodingError(message: "The embedded SAC spec has sha256 \(actualSha256Hex), expected \(sha256Hex)")
        }
        let input = [UInt8](bytes)
        let decoder = XDRDecoder(data: input)
        var entries: [SCSpecEntryXDR] = []
        while decoder.remainingBytes > 0 {
            let start = input.count - decoder.remainingBytes
            let entry: SCSpecEntryXDR
            do {
                entry = try SCSpecEntryXDR(from: decoder)
            } catch {
                throw StellarSDKError.xdrDecodingError(message: "The embedded SAC spec does not decode at byte offset \(start): \(String(describing: error))")
            }
            let end = input.count - decoder.remainingBytes
            guard try XDREncoder.encode(entry) == Array(input[start..<end]) else {
                throw StellarSDKError.xdrDecodingError(message: "The embedded SAC spec does not decode at byte offset \(start): the entry re-encodes to different bytes")
            }
            entries.append(entry)
        }
        return entries
    }

    // MARK: - Factories

    /// Opens the Stellar Asset Contract of `asset` for a source account, without an RPC request.
    ///
    /// The client does not check that the contract is deployed; a call to a contract that is
    /// not fails in its simulation.
    ///
    /// - Parameters:
    ///   - asset: The native asset or an issued asset.
    ///   - sourceAccountKeyPair: The keypair of the source account of the client's
    ///     transactions. The account must exist, and the keypair needs its private key to
    ///     sign and submit.
    ///   - network: The network the contract lives on.
    ///   - rpcUrl: The URL of the Soroban RPC server.
    ///   - urlSession: Optional URL session used for every RPC request. Defaults to
    ///     ``URLSession/shared`` when nil.
    /// - Returns: The client, whose ``contractId`` is `asset.contractId(network:)`.
    /// - Throws: `StellarSDKError.xdrEncodingError` for a liquidity pool share, as
    ///   ``Asset/contractId(network:)`` does; `StellarSDKError.xdrDecodingError` when the
    ///   embedded spec does not decode.
    public static func forAsset(asset: Asset, sourceAccountKeyPair: KeyPair, network: Network, rpcUrl: String, urlSession: URLSession? = nil) throws -> SACClient {
        return try open(contractId: try asset.contractId(network: network),
                        sourceAccountKeyPair: sourceAccountKeyPair,
                        network: network,
                        rpcUrl: rpcUrl,
                        urlSession: urlSession,
                        readOnly: false)
    }

    /// Opens the Stellar Asset Contract with the given id for a source account, without an
    /// RPC request.
    ///
    /// The client does not check that the id names a deployed Stellar Asset Contract; a call
    /// to another contract fails in its simulation or runs that contract's function of the
    /// same name.
    ///
    /// - Parameters:
    ///   - contractId: The contract id as a "C..." strkey or as the 64 character hex of the
    ///     32 byte id; ``contractId`` holds the strkey either way.
    ///   - sourceAccountKeyPair: The keypair of the source account of the client's
    ///     transactions. The account must exist, and the keypair needs its private key to
    ///     sign and submit.
    ///   - network: The network the contract lives on.
    ///   - rpcUrl: The URL of the Soroban RPC server.
    ///   - urlSession: Optional URL session used for every RPC request. Defaults to
    ///     ``URLSession/shared`` when nil.
    /// - Returns: The client.
    /// - Throws: `StellarSDKError.invalidArgument` when `contractId` is any other string,
    ///   naming the kind of address given: a muxed contract (W...) address is refused with
    ///   its base contract address as the remedy, and a secret seed is named by its kind and
    ///   never echoed. `StellarSDKError.xdrDecodingError` when the embedded spec does not
    ///   decode.
    public static func forContractId(contractId: String, sourceAccountKeyPair: KeyPair, network: Network, rpcUrl: String, urlSession: URLSession? = nil) throws -> SACClient {
        return try open(contractId: try strKey(ofContractId: contractId),
                        sourceAccountKeyPair: sourceAccountKeyPair,
                        network: network,
                        rpcUrl: rpcUrl,
                        urlSession: urlSession,
                        readOnly: false)
    }

    /// Opens the Stellar Asset Contract of `asset` for reading only, without a keypair and
    /// without an RPC request.
    ///
    /// The client's transactions name ``READ_ONLY_SOURCE_ACCOUNT_ID`` as their source and
    /// simulate without loading it. They refuse to sign their envelope, to submit, and to
    /// restore archived entries; ``transferAndSend(to:amount:methodOptions:)`` throws before
    /// any request.
    ///
    /// - Parameters:
    ///   - asset: The native asset or an issued asset.
    ///   - network: The network the contract lives on.
    ///   - rpcUrl: The URL of the Soroban RPC server.
    ///   - urlSession: Optional URL session used for every RPC request. Defaults to
    ///     ``URLSession/shared`` when nil.
    /// - Returns: The read-only client, whose ``contractId`` is `asset.contractId(network:)`.
    /// - Throws: `StellarSDKError.xdrEncodingError` for a liquidity pool share, as
    ///   ``Asset/contractId(network:)`` does; `StellarSDKError.xdrDecodingError` when the
    ///   embedded spec does not decode.
    public static func readOnlyForAsset(asset: Asset, network: Network, rpcUrl: String, urlSession: URLSession? = nil) throws -> SACClient {
        return try open(contractId: try asset.contractId(network: network),
                        sourceAccountKeyPair: try KeyPair(accountId: READ_ONLY_SOURCE_ACCOUNT_ID),
                        network: network,
                        rpcUrl: rpcUrl,
                        urlSession: urlSession,
                        readOnly: true)
    }

    /// Opens the Stellar Asset Contract with the given id for reading only, without a keypair
    /// and without an RPC request.
    ///
    /// The client's transactions name ``READ_ONLY_SOURCE_ACCOUNT_ID`` as their source and
    /// simulate without loading it. They refuse to sign their envelope, to submit, and to
    /// restore archived entries; ``transferAndSend(to:amount:methodOptions:)`` throws before
    /// any request.
    ///
    /// - Parameters:
    ///   - contractId: The contract id as a "C..." strkey or as the 64 character hex of the
    ///     32 byte id; ``contractId`` holds the strkey either way.
    ///   - network: The network the contract lives on.
    ///   - rpcUrl: The URL of the Soroban RPC server.
    ///   - urlSession: Optional URL session used for every RPC request. Defaults to
    ///     ``URLSession/shared`` when nil.
    /// - Returns: The read-only client.
    /// - Throws: `StellarSDKError.invalidArgument` when `contractId` is any other string, as
    ///   ``forContractId(contractId:sourceAccountKeyPair:network:rpcUrl:urlSession:)`` does;
    ///   `StellarSDKError.xdrDecodingError` when the embedded spec does not decode.
    public static func readOnlyForContractId(contractId: String, network: Network, rpcUrl: String, urlSession: URLSession? = nil) throws -> SACClient {
        return try open(contractId: try strKey(ofContractId: contractId),
                        sourceAccountKeyPair: try KeyPair(accountId: READ_ONLY_SOURCE_ACCOUNT_ID),
                        network: network,
                        rpcUrl: rpcUrl,
                        urlSession: urlSession,
                        readOnly: true)
    }

    /// The "C..." strkey of `contractId`, which is that strkey or the 64 character hex of the
    /// 32 byte id.
    ///
    /// - Throws: `StellarSDKError.invalidArgument` naming the kind of address given for any
    ///   other string.
    private static func strKey(ofContractId contractId: String) throws -> String {
        if let refusal = ContractAddressGuard.contractIdRefusal(contractId, subject: subject) {
            throw StellarSDKError.invalidArgument(message: refusal)
        }
        return contractId.isValidContractId() ? contractId : try contractId.encodeContractIdHex()
    }

    private static func open(contractId: String, sourceAccountKeyPair: KeyPair, network: Network, rpcUrl: String, urlSession: URLSession?, readOnly: Bool) throws -> SACClient {
        let options = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair,
                                    contractId: contractId,
                                    network: network,
                                    rpcUrl: rpcUrl,
                                    urlSession: urlSession)
        let sorobanClient = try SorobanClient.forSpecEntries(specEntries: try specEntries(), options: options, readOnly: readOnly)
        return SACClient(contractId: contractId,
                         sorobanClient: sorobanClient,
                         readOnly: readOnly,
                         sourceAccountId: sourceAccountKeyPair.accountId)
    }

    // MARK: - Amounts

    /// Converts a decimal amount of tokens to base units.
    ///
    /// A token has 7 decimals, so the result is the amount times 10,000,000: `"12.5"` gives
    /// `"125000000"` and `"0.0000001"` gives `"1"`. The amount is one or more ASCII digits,
    /// optionally followed by `.` and one to seven more digits; it takes no sign, no
    /// whitespace, no exponent, and no grouping. The largest amount is
    /// `17014118346046923173168730371588.4105727`, the largest value of the contract's signed
    /// 128-bit amounts.
    ///
    /// - Parameter amount: The decimal amount.
    /// - Returns: The base units as a decimal string without leading zeros.
    /// - Throws: `StellarSDKError.invalidArgument` when `amount` is not such a decimal amount
    ///   or exceeds the largest amount. The message shows at most 80 characters of the input
    ///   with control characters escaped; a secret seed given by mistake is named by its kind
    ///   and never echoed.
    public static func toBaseUnits(_ amount: String) throws -> String {
        if let seedKind = SecretSeedRedaction.seedKind(of: amount) {
            throw StellarSDKError.invalidArgument(message: "Invalid amount: got \(seedKind) instead of a decimal amount")
        }
        let parts = Array(amount.utf8).split(separator: UInt8(ascii: "."), omittingEmptySubsequences: false)
        let whole = parts[0]
        let fraction = parts.count == 2 ? parts[1] : []
        guard parts.count <= 2,
              isDigits(whole),
              parts.count == 1 || (isDigits(fraction) && fraction.count <= fractionDigits) else {
            throw StellarSDKError.invalidArgument(message: "Invalid amount \"\(preview(amount))\": expected decimal digits with at most 7 fractional digits, such as 12.5")
        }
        let padding = [UInt8](repeating: UInt8(ascii: "0"), count: fractionDigits - fraction.count)
        let baseUnits = withoutLeadingZeros(whole + fraction + padding)
        if exceedsMaxI128(baseUnits) {
            throw StellarSDKError.invalidArgument(message: "Amount \(preview(amount)) exceeds the largest i128 amount, 17014118346046923173168730371588.4105727")
        }
        return String(decoding: baseUnits, as: UTF8.self)
    }

    /// Whether `bytes` is one or more ASCII digits. The check is on bytes, because the
    /// `Character` digit tests also accept digits of other scripts.
    private static func isDigits<Bytes: Collection>(_ bytes: Bytes) -> Bool where Bytes.Element == UInt8 {
        return !bytes.isEmpty && bytes.allSatisfy { $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") }
    }

    /// The ASCII digits `digits` without leading zeros; a single zero when no other digit is left.
    private static func withoutLeadingZeros<Bytes: Collection>(_ digits: Bytes) -> [UInt8] where Bytes.Element == UInt8 {
        let significant = Array(digits.drop { $0 == UInt8(ascii: "0") })
        return significant.isEmpty ? [UInt8(ascii: "0")] : significant
    }

    /// Whether the ASCII digits `digits`, which have no leading zeros, spell a number above
    /// 2^127 - 1, the largest signed 128-bit integer.
    private static func exceedsMaxI128(_ digits: [UInt8]) -> Bool {
        if digits.count != maxI128Digits.count {
            return digits.count > maxI128Digits.count
        }
        return maxI128Digits.lexicographicallyPrecedes(digits)
    }

    /// `text` as an error message shows it: a secret seed inside it replaced by its kind,
    /// control characters escaped, and at most 80 characters.
    private static func preview(_ text: String) -> String {
        return XdrJson.preview(SecretSeedRedaction.redactingSecretSeeds(in: text))
    }

    /// Checks a transfer amount: base units as one or more ASCII digits, at most 2^127 - 1.
    ///
    /// - Throws: `StellarSDKError.invalidArgument` for any other string.
    private static func requireTransferAmount(_ amount: String) throws {
        if let seedKind = SecretSeedRedaction.seedKind(of: amount) {
            throw StellarSDKError.invalidArgument(message: "Invalid transfer amount: got \(seedKind) instead of a whole number of base units")
        }
        let digits = Array(amount.utf8)
        guard isDigits(digits) else {
            throw StellarSDKError.invalidArgument(message: "The transfer amount must be a whole number of base units, got \"\(preview(amount))\"; convert a decimal amount with SACClient.toBaseUnits(_:)")
        }
        if exceedsMaxI128(withoutLeadingZeros(digits)) {
            throw StellarSDKError.invalidArgument(message: "The transfer amount must be from 0 to 170141183460469231731687303715884105727 base units, got \(preview(amount))")
        }
    }

    // MARK: - Reads

    /// Reads the balance of `holder` in base units.
    ///
    /// The call only simulates. A holder that is an account without the asset's trustline,
    /// or an account that does not exist, fails the simulation with the contract's error
    /// rather than reading as zero: `AssembledTransactionError.reportedContractError` gives
    /// the code 13 for a missing trustline and 6 for a missing account when the simulation
    /// reports it. A contract holder without a balance reads `"0"`.
    ///
    /// - Parameter holder: An account (G...) or contract (C...) address.
    /// - Returns: The balance in base units as a decimal string.
    /// - Throws: `StellarSDKError.invalidArgument` before any request for a muxed account
    ///   (M...) or muxed contract (W...) holder, naming its base address: the contract keeps
    ///   balances per base address. `ContractSpecError.invalidType` before any request for a
    ///   claimable balance or liquidity pool address.
    ///   `AssembledTransactionError.simulationFailed` when the simulation fails,
    ///   `AssembledTransactionError.restoreNeeded` when ledger entries the call needs are
    ///   archived, and `SorobanClientError.invokeFailed` when the contract returns anything
    ///   but an i128. A keyed client also throws the RPC error of loading its source account.
    public func balance(holder: SCAddressXDR) async throws -> String {
        let requirement = "The balance holder must be an account (G...) or contract (C...) address"
        switch holder {
        case .muxedAccount(let muxedAccount):
            let base = MuxedAccountXDR.med25519(muxedAccount).ed25519AccountId
            throw StellarSDKError.invalidArgument(message: "\(requirement), got a muxed account (M...) address: \(try holder.toStrKey()); query its base account \(base)")
        case .muxedContract(let muxedContract):
            let base = try muxedContract.contractId.wrapped.encodeContractId()
            throw StellarSDKError.invalidArgument(message: "\(requirement), got a muxed contract (W...) address: \(try holder.toStrKey()); query its base contract \(base)")
        default:
            break
        }
        let function = "balance"
        let value = try await read(function, args: ["id": holder])
        guard let balance = value.i128String else {
            throw unexpectedArm(of: value, from: function, expected: .i128)
        }
        return balance
    }

    /// Reads the number of decimals of the token, which is 7 for every Stellar Asset Contract.
    ///
    /// The call only simulates.
    ///
    /// - Returns: The number of decimals.
    /// - Throws: `AssembledTransactionError.simulationFailed` when the simulation fails,
    ///   `AssembledTransactionError.restoreNeeded` when ledger entries the call needs are
    ///   archived, and `SorobanClientError.invokeFailed` when the contract returns anything
    ///   but a u32. A keyed client also throws the RPC error of loading its source account.
    public func decimals() async throws -> UInt32 {
        let function = "decimals"
        let value = try await read(function, args: [:])
        guard let decimals = value.u32 else {
            throw unexpectedArm(of: value, from: function, expected: .u32)
        }
        return decimals
    }

    /// Reads the name of the token: `CODE:ISSUER` for an issued asset and `native` for the
    /// native asset.
    ///
    /// The call only simulates.
    ///
    /// - Returns: The name.
    /// - Throws: `AssembledTransactionError.simulationFailed` when the simulation fails,
    ///   `AssembledTransactionError.restoreNeeded` when ledger entries the call needs are
    ///   archived, and `SorobanClientError.invokeFailed` when the contract returns anything
    ///   but a string or a string whose bytes are not valid UTF-8. A keyed client also throws
    ///   the RPC error of loading its source account.
    public func name() async throws -> String {
        return try await readString("name")
    }

    /// Reads the symbol of the token: the asset code of an issued asset and `native` for the
    /// native asset.
    ///
    /// The call only simulates.
    ///
    /// - Returns: The symbol.
    /// - Throws: `AssembledTransactionError.simulationFailed` when the simulation fails,
    ///   `AssembledTransactionError.restoreNeeded` when ledger entries the call needs are
    ///   archived, and `SorobanClientError.invokeFailed` when the contract returns anything
    ///   but a string or a string whose bytes are not valid UTF-8. A keyed client also throws
    ///   the RPC error of loading its source account.
    public func symbol() async throws -> String {
        return try await readString("symbol")
    }

    /// Simulates `function`, which takes no argument, and returns the text of the string it
    /// returns.
    private func readString(_ function: String) async throws -> String {
        let value = try await read(function, args: [:])
        guard case .string(let bytes) = value else {
            throw unexpectedArm(of: value, from: function, expected: .string)
        }
        guard let text = value.string else {
            throw SorobanClientError.invokeFailed(message: "The Stellar Asset Contract \(contractId) returned a string from \(function) whose bytes are not valid UTF-8: \(TxRepHelper.escapeBytes(bytes))")
        }
        return text
    }

    /// Simulates `function` with the arguments `args`, keyed by parameter name, and returns
    /// the value the simulation returns. A read never restores: archived entries throw.
    private func read(_ function: String, args: [String: Any]) async throws -> SCValXDR {
        let tx = try await sorobanClient.buildInvokeMethodTx(
            name: function,
            args: try sorobanClient.getContractSpec().funcArgsToXdrSCValues(name: function, args: args),
            methodOptions: MethodOptions(restore: false))
        if tx.simulationResponse?.restorePreamble != nil {
            throw AssembledTransactionError.restoreNeeded(message: "The Stellar Asset Contract \(contractId) cannot run \(function): ledger entries it needs are archived; restore them from a client opened with a funded account's keypair")
        }
        return try tx.getSimulationData().returnedValue
    }

    /// The error for a value of another arm than `expected` returned from `function`.
    private func unexpectedArm(of value: SCValXDR, from function: String, expected: SCValType) -> SorobanClientError {
        let arm = SCValType(rawValue: value.type())!.enumName()
        return .invokeFailed(message: "The Stellar Asset Contract \(contractId) returned \(arm) from \(function), expected \(expected.enumName())")
    }

    // MARK: - Writes

    /// Builds a transfer of `amount` base units from `from` to `to`.
    ///
    /// By default the returned transaction is simulated, unsigned, and unsent. On the
    /// simulated transaction, when `from` is the client's source account, `signAndSend()`
    /// completes the transfer. Another account as `from` appears in its
    /// `needsNonInvokerSigningBy()` and authorizes with
    /// ``AssembledTransaction/signAuthEntries(signerKeyPair:authorizeEntryCallback:validUntilLedgerSeq:)``
    /// before `signAndSend()`; a contract as `from` authorizes through its own `__check_auth`.
    /// A read-only client builds the transfer, by default simulated, and allows authorization
    /// entry signing on the simulated transaction, but its transaction refuses to sign its
    /// envelope, to submit, and to restore.
    ///
    /// With `simulate: false` in `methodOptions`, the returned transaction is unsimulated;
    /// call `simulate()` on it before inspecting or completing authorization entries.
    ///
    /// - Parameters:
    ///   - from: The sender, an account (G...) or contract (C...) address.
    ///   - to: The receiver, an account (G...), muxed account (M...), contract (C...) or
    ///     muxed contract (W...) address. A muxed receiver is credited at its base address,
    ///     and the transfer event carries its id.
    ///   - amount: The amount in base units as one or more ASCII digits, from 0 to
    ///     170141183460469231731687303715884105727; ``toBaseUnits(_:)`` converts a decimal
    ///     amount.
    ///   - methodOptions: The fee, the timeout, and whether to simulate and to restore.
    ///     Defaults to `MethodOptions()`.
    /// - Returns: The transaction.
    /// - Throws: `StellarSDKError.invalidArgument` before any request when `amount` is not
    ///   such a number; a secret seed given by mistake is named by its kind and never echoed.
    ///   `ContractSpecError.invalidType` before any request for a muxed `from` and for a
    ///   claimable balance or liquidity pool address. The errors of building and simulating
    ///   the transaction, such as `AssembledTransactionError.simulationFailed`, and, on a
    ///   keyed client, the RPC error of loading its source account.
    public func transfer(from: SCAddressXDR, to: SCAddressXDR, amount: String, methodOptions: MethodOptions? = nil) async throws -> AssembledTransaction {
        try SACClient.requireTransferAmount(amount)
        let function = "transfer"
        let args = try sorobanClient.getContractSpec().funcArgsToXdrSCValues(
            name: function,
            args: ["from": from, "to": to, "amount": try SCValXDR.i128(stringValue: amount)])
        return try await sorobanClient.buildInvokeMethodTx(name: function, args: args, methodOptions: methodOptions)
    }

    /// Transfers `amount` base units from the client's source account to `to`: builds the
    /// transfer, signs it with the source account's keypair, sends it, and waits for its result.
    ///
    /// Only a transaction that ends with the status `SUCCESS` returns. A transaction that is
    /// not confirmed within `timeoutInSeconds` of `methodOptions` throws
    /// `AssembledTransactionError.pollInterrupted` with its hash; it may still succeed, so
    /// poll that hash again before sending another transfer.
    ///
    /// - Parameters:
    ///   - to: The receiver, an account (G...), muxed account (M...), contract (C...) or
    ///     muxed contract (W...) address.
    ///   - amount: The amount in base units as one or more ASCII digits, from 0 to
    ///     170141183460469231731687303715884105727; ``toBaseUnits(_:)`` converts a decimal
    ///     amount.
    ///   - methodOptions: The fee, the timeout, and whether to restore. Defaults to
    ///     `MethodOptions()`. With `simulate: false` the call throws
    ///     `AssembledTransactionError.notYetSimulated`, because an unsimulated transaction
    ///     cannot be signed.
    /// - Returns: The response of the successful transaction.
    /// - Throws: `AssembledTransactionError.missingPrivateKey` on a read-only client, before
    ///   any request and before the amount is checked. The errors of
    ///   ``transfer(from:to:amount:methodOptions:)``. The errors of signing and sending, such
    ///   as `AssembledTransactionError.sendFailed` for a submission the network did not
    ///   queue and `AssembledTransactionError.pollInterrupted`.
    ///   `SorobanClientError.invokeFailed` naming the status and the transaction result XDR
    ///   when the transaction ends with another status than `SUCCESS`.
    public func transferAndSend(to: SCAddressXDR, amount: String, methodOptions: MethodOptions? = nil) async throws -> GetTransactionResponse {
        if readOnly {
            throw AssembledTransactionError.missingPrivateKey(message: "transferAndSend needs the sending account's keypair, and this SACClient is read-only; open the client with SACClient.forAsset or SACClient.forContractId")
        }
        let tx = try await transfer(from: try SCAddressXDR(accountId: sourceAccountId), to: to, amount: amount, methodOptions: methodOptions)
        let response = try await tx.signAndSend()
        guard response.status == GetTransactionResponse.STATUS_SUCCESS else {
            throw SorobanClientError.invokeFailed(message: "The transfer did not succeed: status \(response.status), transaction result xdr: \(response.resultXdr ?? "not available")")
        }
        return response
    }
}
