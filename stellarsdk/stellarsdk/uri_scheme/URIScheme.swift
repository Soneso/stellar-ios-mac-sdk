//
//  URIScheme.swift
//  stellarsdk
//
//  Created by Soneso on 10/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// The URI scheme identifier for Stellar SEP-0007 compliant URIs.
public let URISchemeName = "web+stellar:"

/// The operation identifier for transaction signing requests in SEP-0007 URIs.
public let SignOperation = "tx?"

/// The operation identifier for payment requests in SEP-0007 URIs.
public let PayOperation = "pay?"

/// Maximum allowed length for message parameters in SEP-0007 URIs.
public let MessageMaximumLength = 300

/// An enum used to differentiate between a successful and a failed transaction setup.
public enum SetupTransactionXDREnum: Sendable {
    /// Successfully parsed and constructed the transaction XDR from the URI.
    case success(transactionXDR: TransactionXDR?)
    /// Failed to setup the transaction from the URI.
    case failure(error: HorizonRequestError)
}

/// An enum used to differentiate between a successful and a failed transaction submission.
public enum SubmitTransactionEnum: Sendable {
    /// Transaction submitted successfully to the network.
    case success
    /// Transaction requires a memo for the destination account per SEP-0029.
    case destinationRequiresMemo(destinationAccountId: String)
    /// Transaction submission failed due to an error.
    case failure(error: HorizonRequestError)
}

/// Closure type for transaction confirmation callbacks. Returns true to proceed, false to cancel.
public typealias TransactionConfirmationClosure = @Sendable (TransactionXDR) -> (Bool)

/// Implements SEP-0007 - URI Scheme to Facilitate Delegated Signing.
///
/// This class provides functionality for creating and processing Stellar URIs that enable
/// transaction signing delegation. Applications can generate URIs requesting users to sign
/// transactions or make payments, and wallets can parse these URIs to fulfill the requests.
///
/// ## Typical Usage
///
/// ```swift
/// let uriScheme = URIScheme()
///
/// // Generate payment URI
/// let paymentUri = uriScheme.getPayOperationURI(
///     destination: "GDESTINATION...",
///     amount: 100.50,
///     assetCode: "USDC",
///     assetIssuer: "GISSUER..."
/// )
///
/// // Generate transaction signing URI
/// let transaction = try Transaction(...)
/// let signingUri = uriScheme.getSignTransactionURI(
///     transactionXDR: transaction.transactionXDR,
///     callBack: "url:https://callback.example.com"
/// )
/// ```
///
/// See also:
/// - [SEP-0007 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md)
public final class URIScheme: Sendable {
    public init() {}

    /// Generates a SEP-0007 compliant URI to request transaction signing.
    ///
    /// All parameter values are URL-encoded automatically.
    ///
    /// - Parameter transactionXDR: A TransactionXDR object representing a transaction on the Stellar network
    /// - Parameter replace: Optional value identifying fields to be replaced in the XDR using Txrep (SEP-0011) representation
    /// - Parameter callBack: Optional URL callback where the signed transactionXDR will be sent (must be prefixed with "url:")
    /// - Parameter publicKey: Optional public key that will be used to sign the transaction
    /// - Parameter chain: Optional SEP-0007 request that spawned or triggered the creation of this request
    /// - Parameter message: Optional message to display to the user in their wallet (max 300 characters)
    /// - Parameter networkPassphrase: Optional network passphrase, only needed for non-public networks
    /// - Parameter originDomain: Optional fully qualified domain name specifying the originating domain of the URI request
    /// - Parameter signature: Optional signature of the hash of the URI request (excluding the signature field itself)
    /// - Returns: A SEP-0007 compliant URI string for the transaction signing request
    ///
    /// See: [SEP-0007 tx operation](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md#operation-tx)
    public func getSignTransactionURI(transactionXDR: TransactionXDR,
                                      replace: String? = nil,
                                      callBack: String? = nil,
                                      publicKey: String? = nil,
                                      chain: String? = nil,
                                      message: String? = nil,
                                      networkPassphrase: String? = nil,
                                      originDomain: String? = nil,
                                      signature: String? = nil) -> String {
        
        var uriScheme = URISchemeName
        if let encodedEnvelope = try? transactionXDR.encodedEnvelope(), let urlEncondedEnvelope = encodedEnvelope.urlEncoded {
            var params: [String] = []
           
            uriScheme += SignOperation
            
            params.append("\(SignTransactionParams.xdr)=\(urlEncondedEnvelope)")
            
            if let replace = replace, let urlEncodedReplace = replace.urlEncoded {
                params.append("\(SignTransactionParams.replace)=\(urlEncodedReplace)")
            }
            
            if let callBack = callBack, let urlEncodedCallBack = callBack.urlEncoded {
                params.append("\(SignTransactionParams.callback)=\(urlEncodedCallBack)")
            }
            
            if let publicKey = publicKey {
                params.append("\(SignTransactionParams.pubkey)=\(publicKey)")
            }
            
            if let chain = chain, let urlEncodedChain = chain.urlEncoded {
                params.append("\(SignTransactionParams.chain)=\(urlEncodedChain)")
            }
            
            if let message = message, message.count < MessageMaximumLength, let urlEncodedMessage = message.urlEncoded {
                params.append("\(SignTransactionParams.msg)=\(urlEncodedMessage)")
            }
            
            if let networkPassphrase = networkPassphrase, let urlEncodedPassphrase = networkPassphrase.urlEncoded {
                params.append("\(SignTransactionParams.network_passphrase)=\(urlEncodedPassphrase)")
            }
            
            if let originDomain = originDomain {
                params.append("\(SignTransactionParams.origin_domain)=\(originDomain)")
            }
            
            if let signature = signature {
                params.append("\(SignTransactionParams.signature)=\(signature)")
            }
            
            for param in params {
                uriScheme += "\(param)&"
            }
            
            uriScheme.removeLast()
        }
        
        return uriScheme
    }
    
    /// Generates a SEP-0007 compliant URI to request a payment to a specific address.
    ///
    /// All parameter values are URL-encoded automatically. For MEMO_HASH or MEMO_RETURN memo types,
    /// the memo is base64-encoded before URL encoding.
    ///
    /// - Parameter destination: A valid account ID or payment address for the payment destination
    /// - Parameter amount: Optional amount that the destination will receive
    /// - Parameter assetCode: Optional asset code the destination will receive (defaults to XLM if not present)
    /// - Parameter assetIssuer: Optional account ID of the asset issuer (required for non-native assets)
    /// - Parameter memo: Optional memo to include in the payment
    /// - Parameter memoType: Optional memo type: MEMO_TEXT, MEMO_ID, MEMO_HASH, or MEMO_RETURN (defaults to TEXT)
    /// - Parameter callBack: Optional URL callback where the signed transactionXDR will be sent (must be prefixed with "url:")
    /// - Parameter message: Optional message to display to the user in their wallet (max 300 characters)
    /// - Parameter networkPassphrase: Optional network passphrase, only needed for non-public networks
    /// - Parameter originDomain: Optional fully qualified domain name specifying the originating domain of the URI request
    /// - Parameter signature: Optional signature of the hash of the URI request (excluding the signature field itself)
    /// - Returns: A SEP-0007 compliant URI string for the payment request
    ///
    /// See: [SEP-0007 pay operation](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md#operation-pay)
    public func getPayOperationURI(destination: String,
                                   amount: Decimal? = nil,
                                   assetCode: String? = nil,
                                   assetIssuer: String? = nil,
                                   memo: String? = nil,
                                   memoType: String? = MemoTypeAsString.TEXT,
                                   callBack: String? = nil,
                                   message: String? = nil,
                                   networkPassphrase: String? = nil,
                                   originDomain: String? = nil,
                                   signature: String? = nil) -> String {
        var params: [String] = []
        var uriScheme = URISchemeName
        uriScheme += PayOperation
        
        params.append("\(PayOperationParams.destination)=\(destination)")
        
        if let amount = amount {
            params.append("\(PayOperationParams.amount)=\(amount)")
        }
        
        if let assetCode = assetCode {
            params.append("\(PayOperationParams.asset_code)=\(assetCode)")
        }
        
        if let assetIssuer = assetIssuer {
            params.append("\(PayOperationParams.asset_issuer)=\(assetIssuer)")
        }
        
        if let memo = memo {
            switch memoType {
            case MemoTypeAsString.TEXT:
                if let urlEncodedMemo = memo.urlEncoded {
                    params.append("\(PayOperationParams.memo)=\(urlEncodedMemo)")
                }
            case MemoTypeAsString.ID:
                params.append("\(PayOperationParams.memo)=\(memo)")
            case MemoTypeAsString.RETURN, MemoTypeAsString.HASH:
                if let base64Memo = memo.base64Encoded(), let urlEncodedMemo = base64Memo.urlEncoded {
                    params.append("\(PayOperationParams.memo)=\(urlEncodedMemo)")
                }
            default:
                break
            }
        }

        if let _ = memo, let memoType = memoType {
            // Convert memo type to SEP-0007 format: "MEMO_" + uppercase type
            // Only add memo_type when memo is actually provided per SEP-0007
            let sepMemoType = "MEMO_\(memoType.uppercased())"
            params.append("\(PayOperationParams.memo_type)=\(sepMemoType)")
        }
        
        if let callBack = callBack, let urlEncodedCallBack = callBack.urlEncoded {
            params.append("\(PayOperationParams.callback)=\(urlEncodedCallBack)")
        }
        
        if let message = message, message.count < MessageMaximumLength, let urlEncodedMessage = message.urlEncoded {
            params.append("\(PayOperationParams.msg)=\(urlEncodedMessage)")
        }
        
        if let networkPassphrase = networkPassphrase, let urlEncodedPassphrase = networkPassphrase.urlEncoded {
            params.append("\(PayOperationParams.network_passphrase)=\(urlEncodedPassphrase)")
        }
        
        if let originDomain = originDomain {
            params.append("\(PayOperationParams.origin_domain)=\(originDomain)")
        }
        
        if let signature = signature {
            params.append("\(PayOperationParams.signature)=\(signature)")
        }
        
        for param in params {
            uriScheme += "\(param)&"
        }
        
        uriScheme.removeLast()
        return uriScheme
    }
    
    
    /// Signs and submits a transaction from a SEP-0007 `tx` URI.
    ///
    /// Parses the `xdr` parameter from a `web+stellar:tx?` URI regardless of parameter order,
    /// decodes a V0, V1, or fee bump transaction envelope, optionally asks for confirmation, signs
    /// the transaction with `keyPair` for `network` (signing the fee bump hash for a fee bump
    /// envelope while leaving the inner transaction and its signatures unchanged), and submits the
    /// resulting envelope.
    ///
    /// When the `callback` parameter is present, values starting with `"url:"` are used as given
    /// and other values are percent-decoded once. Only `"url:"` callbacks are supported; they must
    /// use HTTPS (HTTP is allowed only for `localhost`, `127.0.0.1`, or `::1`), and the signed
    /// envelope is sent in a `POST` request as `application/x-www-form-urlencoded` with field `xdr`.
    /// Any other callback type or invalid percent-encoding fails without sending a request.
    ///
    /// When `callback` is omitted, the signed envelope is submitted to the Horizon server matching
    /// `network` (`StellarSDK.publicNet()`, `StellarSDK.testNet()`, or `StellarSDK.futureNet()`),
    /// running the SEP-0029 memo requirement check. `.custom` networks have no known Horizon URL
    /// and fail unless a `url:` callback is provided.
    ///
    /// Signing errors, including a `KeyPair` without a private key, return `.failure` with
    /// `HorizonRequestError.requestFailed` naming the cause, and nothing is sent.
    ///
    /// - Parameter url: A SEP-0007 `web+stellar:tx?` URI containing the transaction to sign.
    /// - Parameter keyPair: The signing `KeyPair` (must include the private key).
    /// - Parameter network: The Stellar network to sign for and, when no callback is set, submit to (defaults to `.public`).
    /// - Parameter transactionConfirmation: Optional closure to confirm the transaction before
    ///   signing (return `false` to cancel). Receives `transactionXDR` for a V0 or V1 envelope, or
    ///   `innerTransaction.transactionXDR` for a fee bump envelope.
    /// - Returns: `SubmitTransactionEnum` indicating success, a SEP-0029 memo requirement, or failure.
    public func signAndSubmitTransaction(forURL url: String,
                                         signerKeyPair keyPair: KeyPair,
                                         network: Network = .public,
                                         transactionConfirmation: TransactionConfirmationClosure? = nil) async -> SubmitTransactionEnum {
        guard let parsedTransaction = parseTransaction(fromURL: url) else {
            return .failure(error: HorizonRequestError.requestFailed(message: "TransactionXDR missing from url!", horizonErrorResponse: nil))
        }

        if let isConfirmed = transactionConfirmation?(parsedTransaction.confirmationTransactionXDR), !isConfirmed {
            return .failure(error: HorizonRequestError.requestFailed(message: "Transaction was not confirmed!", horizonErrorResponse: nil))
        }

        do {
            try parsedTransaction.sign(keyPair: keyPair, network: network)
        } catch let error as StellarSDKError {
            let cause: String
            switch error {
            case .invalidArgument(let message),
                 .xdrDecodingError(let message),
                 .xdrEncodingError(let message),
                 .encodingError(let message),
                 .decodingError(let message):
                cause = message
            }
            return .failure(error: HorizonRequestError.requestFailed(message: "Failed to sign transaction: \(cause)", horizonErrorResponse: nil))
        } catch {
            return .failure(error: HorizonRequestError.requestFailed(message: "Failed to sign transaction: \(error)", horizonErrorResponse: nil))
        }

        let encodedEnvelope: String
        do {
            encodedEnvelope = try parsedTransaction.encodedEnvelope()
        } catch {
            return .failure(error: HorizonRequestError.requestFailed(message: "Failed to encode transaction envelope: \(error)", horizonErrorResponse: nil))
        }

        let callback = getTxQueryValue(forParam: .callback, fromURL: url)
        return await submitTransaction(encodedEnvelope: encodedEnvelope, callback: callback, network: network)
    }

    /// Sends a signed transaction envelope to the callback URL, or to the Horizon server for
    /// `network` when `callback` is nil.
    private func submitTransaction(encodedEnvelope: String, callback: String?, network: Network) async -> SubmitTransactionEnum {
        if let rawCallback = callback {
            let urlCallbackPrefix = "url:"
            let resolvedCallback: String
            if rawCallback.hasPrefix(urlCallbackPrefix) {
                resolvedCallback = rawCallback
            } else {
                guard let decoded = rawCallback.removingPercentEncoding else {
                    return .failure(error: HorizonRequestError.requestFailed(message: "Invalid callback URL", horizonErrorResponse: nil))
                }
                resolvedCallback = decoded
            }

            guard resolvedCallback.hasPrefix(urlCallbackPrefix) else {
                let callbackType: String
                if let colonIndex = resolvedCallback.firstIndex(of: ":") {
                    callbackType = String(resolvedCallback[..<colonIndex])
                } else {
                    callbackType = resolvedCallback
                }
                let message = callbackType.isEmpty
                    ? "Unsupported callback type (only 'url:' callbacks are supported)"
                    : "Unsupported callback type '\(callbackType)' (only 'url:' callbacks are supported)"
                return .failure(error: HorizonRequestError.requestFailed(message: message, horizonErrorResponse: nil))
            }

            let callbackTarget = String(resolvedCallback.dropFirst(urlCallbackPrefix.count))
            guard let callbackURL = URL(string: callbackTarget),
                  let scheme = callbackURL.scheme?.lowercased(),
                  let host = callbackURL.host?.lowercased() else {
                return .failure(error: HorizonRequestError.requestFailed(message: "Invalid callback URL", horizonErrorResponse: nil))
            }
            let isLocalhost = host == "localhost" || host == "127.0.0.1" || host == "::1"
            if scheme != "https" && !(scheme == "http" && isLocalhost) {
                return .failure(error: HorizonRequestError.requestFailed(message: "Callback URL must use HTTPS (HTTP allowed only for localhost)", horizonErrorResponse: nil))
            }

            let serviceHelper = ServiceHelper(baseURL: callbackTarget)
            guard let urlEncodedTransaction = encodedEnvelope.urlEncoded else {
                return .failure(error: HorizonRequestError.requestFailed(message: "error while urlencoding transaction", horizonErrorResponse: nil))
            }
            let body = ("xdr=" + urlEncodedTransaction).data(using: .utf8)
            let response = await serviceHelper.POSTRequestWithPath(path: "", body: body, contentType: "application/x-www-form-urlencoded")
            switch response {
            case .success(_):
                return .success
            case .failure(let error):
                return .failure(error: error)
            }
        } else {
            guard let sdk = horizonSDK(for: network) else {
                return .failure(error: HorizonRequestError.requestFailed(
                    message: "No Horizon URL is known for custom network '\(network.passphrase)'. Provide a callback URL or submit the signed transaction directly.",
                    horizonErrorResponse: nil))
            }
            let response = await sdk.transactions.postTransaction(transactionEnvelope: encodedEnvelope, skipMemoRequiredCheck: false)
            switch response {
            case .success(_):
                return .success
            case .destinationRequiresMemo(let destinationAccountId):
                return .destinationRequiresMemo(destinationAccountId: destinationAccountId)
            case .failure(let error):
                return .failure(error: error)
            }
        }
    }
    
    /// Extracts a parameter value from a SEP-0007 URI.
    ///
    /// - Parameter param: The parameter to extract
    /// - Parameter url: The SEP-0007 URI to parse
    /// - Returns: The parameter value if found, nil otherwise
    public func getValue(forParam param: SignTransactionParams, fromURL url: String) -> String? {
        // Extract query string (everything after ?)
        guard let queryStart = url.range(of: "?") else {
            return nil
        }

        let queryString = String(url[queryStart.upperBound...])
        let fields = queryString.split(separator: "&")

        for field in fields {
            if field.hasPrefix("\(param)=") {
                return field.replacingOccurrences(of: "\(param)=", with: "")
            }
        }
        return nil
    }

    private enum ParsedTransaction {
        case transaction(Transaction)
        case feeBump(FeeBumpTransaction)

        var confirmationTransactionXDR: TransactionXDR {
            switch self {
            case .transaction(let transaction):
                return transaction.transactionXDR
            case .feeBump(let feeBumpTransaction):
                return feeBumpTransaction.innerTransaction.transactionXDR
            }
        }

        func sign(keyPair: KeyPair, network: Network) throws {
            switch self {
            case .transaction(let transaction):
                try transaction.sign(keyPair: keyPair, network: network)
            case .feeBump(let feeBumpTransaction):
                try feeBumpTransaction.sign(keyPair: keyPair, network: network)
            }
        }

        func encodedEnvelope() throws -> String {
            switch self {
            case .transaction(let transaction):
                return try transaction.encodedEnvelope()
            case .feeBump(let feeBumpTransaction):
                return try feeBumpTransaction.encodedEnvelope()
            }
        }
    }

    private func horizonSDK(for network: Network) -> StellarSDK? {
        switch network {
        case .public:
            return StellarSDK.publicNet()
        case .testnet:
            return StellarSDK.testNet()
        case .futurenet:
            return StellarSDK.futureNet()
        case .custom:
            return nil
        }
    }

    /// Extracts the raw value of the first `param=` query field from a `web+stellar:tx?` URI.
    private func getTxQueryValue(forParam param: SignTransactionParams, fromURL url: String) -> String? {
        let prefix = "\(URISchemeName)\(SignOperation)"
        guard url.hasPrefix(prefix) else {
            return nil
        }
        let query = url.dropFirst(prefix.count)
        let fieldPrefix = "\(param)="
        for field in query.split(separator: "&") {
            if field.hasPrefix(fieldPrefix) {
                return String(field.dropFirst(fieldPrefix.count))
            }
        }
        return nil
    }

    /// Parses a V0, V1, or fee bump transaction envelope from a `web+stellar:tx?` URI.
    private func parseTransaction(fromURL url: String) -> ParsedTransaction? {
        guard let urlEncodedEnvelope = getTxQueryValue(forParam: .xdr, fromURL: url),
              let base64Envelope = urlEncodedEnvelope.removingPercentEncoding else {
            return nil
        }
        let xdrDecoder = XDRDecoder(data: [UInt8](base64: base64Envelope))
        guard let envelopeXDR = try? TransactionEnvelopeXDR(fromBinary: xdrDecoder) else {
            return nil
        }
        switch envelopeXDR {
        case .v0, .v1:
            guard let transaction = try? Transaction(envelopeXdr: base64Envelope) else {
                return nil
            }
            return .transaction(transaction)
        case .feeBump:
            guard let feeBumpTransaction = try? FeeBumpTransaction(envelopeXdr: base64Envelope) else {
                return nil
            }
            return .feeBump(feeBumpTransaction)
        }
    }
}
