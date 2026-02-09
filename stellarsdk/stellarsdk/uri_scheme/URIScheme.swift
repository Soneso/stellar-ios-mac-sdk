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
public enum SetupTransactionXDREnum {
    /// Successfully parsed and constructed the transaction XDR from the URI.
    case success(transactionXDR: TransactionXDR?)
    /// Failed to setup the transaction from the URI.
    case failure(error: HorizonRequestError)
}

/// An enum used to differentiate between a successful and a failed transaction submission.
public enum SubmitTransactionEnum {
    /// Transaction submitted successfully to the network.
    case success
    /// Transaction requires a memo for the destination account per SEP-0029.
    case destinationRequiresMemo(destinationAccountId: String)
    /// Transaction submission failed due to an error.
    case failure(error: HorizonRequestError)
}

/// Closure type for transaction confirmation callbacks. Returns true to proceed, false to cancel.
public typealias TransactionConfirmationClosure = ((TransactionXDR) -> (Bool))

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
public class URIScheme: NSObject {
    let sdk = StellarSDK()
    
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
    
    
    /// Signs and submits a transaction from a SEP-0007 URI to the Stellar network.
    ///
    /// Parses the transaction from the URI, optionally confirms it via the callback,
    /// signs it with the provided key pair, and submits it to the network or callback URL.
    ///
    /// - Parameter url: A SEP-0007 compliant URL containing the transaction to sign
    /// - Parameter keyPair: The KeyPair of the signer account
    /// - Parameter network: The Stellar network to use (defaults to public)
    /// - Parameter transactionConfirmation: Optional closure to confirm the transaction before signing (return false to cancel)
    /// - Returns: SubmitTransactionEnum indicating success, memo requirement, or failure
    public func signAndSubmitTransaction(forURL url: String,
                                         signerKeyPair keyPair: KeyPair,
                                         network: Network = .public,
                                         transactionConfirmation: TransactionConfirmationClosure? = nil) async -> SubmitTransactionEnum {
        
        if let transactionXDR = getTransactionXDR(fromURL: url) {
            if let isConfirmed = transactionConfirmation?(transactionXDR), !isConfirmed {
                return .failure(error: HorizonRequestError.requestFailed(message: "Transaction was not confirmed!", horizonErrorResponse: nil))
            }
            var transaction = transactionXDR
            try? transaction.sign(keyPair: keyPair, network: .testnet)
            let callback1 = self.getValue(forParam: .callback, fromURL: url)
            let response = await self.submitTransaction(transactionXDR: transaction, callback: callback1, keyPair: keyPair)
            return response
        } else {
            return .failure(error: HorizonRequestError.requestFailed(message: "TransactionXDR missing from url!", horizonErrorResponse: nil))
        }
    }
    
    /// Sends the transaction to the callback URL or to the Stellar network if no callback is set.
    ///
    /// - Parameter transactionXDR: The signed transaction XDR to submit
    /// - Parameter callback: Optional callback URL (prefixed with "url:") to send the transaction to
    /// - Parameter keyPair: The KeyPair used for signing
    /// - Parameter skipMemoRequiredCheck: Whether to skip SEP-0029 memo requirement validation
    /// - Returns: SubmitTransactionEnum indicating success, memo requirement, or failure
    private func submitTransaction(transactionXDR: TransactionXDR?, callback: String? = nil, keyPair: KeyPair, skipMemoRequiredCheck:Bool = false) async -> SubmitTransactionEnum {
        if let transactionEncodedEnvelope = try? transactionXDR?.encodedEnvelope() {
            if var callback = callback, callback.hasPrefix("url:") {
                callback = String(callback.dropFirst(4))
                let serviceHelper = ServiceHelper(baseURL: callback)
                var dataStr = ""
                if let urlEncodedTransaction = transactionEncodedEnvelope.urlEncoded {
                    dataStr = String("xdr=") + urlEncodedTransaction
                } else {
                    return .failure(error: HorizonRequestError.requestFailed(message: "error while urlencoding transaction", horizonErrorResponse: nil))
                }
                let data1 = dataStr.data(using: .utf8)
                let response = await serviceHelper.POSTRequestWithPath(path: "", body: data1, contentType: "application/x-www-form-urlencoded")
                let _ = serviceHelper
                switch response {
                case .success(_):
                    return .success
                case .failure(let error):
                    return .failure(error: error)
                }
            } else {
                let response = await self.sdk.transactions.postTransaction(transactionEnvelope: transactionEncodedEnvelope, skipMemoRequiredCheck: skipMemoRequiredCheck)
                switch response {
                case .success(_):
                    return .success
                case .destinationRequiresMemo(let destinationAccountId):
                    return .destinationRequiresMemo(destinationAccountId: destinationAccountId)
                case .failure(let error):
                    return .failure(error: error)
                }
            }
        } else {
            return .failure(error: HorizonRequestError.requestFailed(message: "encodedEnvelop failed!", horizonErrorResponse: nil))
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
    
    /// Extracts the raw XDR field value from a SEP-0007 URI.
    ///
    /// - Parameter url: The SEP-0007 URI to parse
    /// - Returns: The URL-encoded XDR string if found, nil otherwise
    private func getTransactionXDRFieldValue(fromURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(URISchemeName)\(SignOperation)\(SignTransactionParams.xdr)") {
                return field.replacingOccurrences(of: "\(URISchemeName)\(SignOperation)\(SignTransactionParams.xdr)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Parses and returns the TransactionXDR object from a SEP-0007 URI.
    ///
    /// - Parameter url: The SEP-0007 URI containing the transaction XDR
    /// - Returns: The decoded TransactionXDR object if successful, nil otherwise
    private func getTransactionXDR(fromURL url: String) -> TransactionXDR? {
        let base64UrlEncodedTransactionEnvelope = getTransactionXDRFieldValue(fromURL: url)
        let base64TransactionEnvelope = base64UrlEncodedTransactionEnvelope?.urlDecoded
        if let base64TransactionEnvelope = base64TransactionEnvelope {
            if let transactionXDR = try? Transaction(envelopeXdr: base64TransactionEnvelope).transactionXDR {
                return transactionXDR
            }
        }
        
        return nil
    }
}
