//
//  URIScheme.swift
//  stellarsdk
//
//  Created by Soneso on 10/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public let URISchemeName = "web+stellar:"
public let SignOperation = "tx?"
public let PayOperation = "pay?"
public let MessageMaximumLength = 300

/// An enum used to differentiate between a successful and a failed transaction setup.
public enum SetupTransactionXDREnum {
    case success(transactionXDR: TransactionXDR?)
    case failure(error: HorizonRequestError)
}

/// An enum used to differentiate between a successful and a failed transaction submission.
public enum SubmitTransactionEnum {
    case success
    case destinationRequiresMemo(destinationAccountId: String)
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a transaction setup.
public typealias SetupTransactionXDRClosure = (_ completion: SetupTransactionXDREnum) -> (Void)

/// A closure to be called with the response from a transaction submission.
public typealias SubmitTransactionClosure = (_ completion: SubmitTransactionEnum) -> (Void)

/// A closure to be callded for the confirmation of a transaction.
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
    
    /// This function is used to generate a URIScheme compliant URL to serve as a request to sign a transaction. It will URL-encode the given parameter values.
    ///  see: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md#operation-tx
    ///
    /// - Parameter transactionXDR: A TransactionXDR object representing a transaction on the stellar network.
    /// - Parameter replace: (optional) A  value that identifies the fields to be replaced in the xdr using the Txrep (SEP-0011) representation.
    /// - Parameter callBack: (optional) A URL callback that will be used to send the transactionXDR to.
    /// - Parameter publicKey: (optional) A publicKey that will be used to sign the url for.
    /// - Parameter chain: (optional) Includes a single SEP-0007 request that spawned or triggered the creation of this SEP-0007 request
    /// - Parameter message: (optional) A query parameter to indicate any additional information that the website or application wants to show the user in her wallet.
    /// - Parameter networkPassphrase: (optional) Only needs to be set if this transaction is for other network than the public one.
    /// - Parameter originDomain: (optional) A fully qualified domain name that specifies the originating domain of the URI request.
    /// - Parameter signature: (optional) A signature of the hash of the URI request (excluding the signature field and value itself).
    ///
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
    
    /// This function is used to generate a URIScheme compliant URL to serve as a request to pay a specific address with a specific asset, regardless of the source asset used by the payer.
    /// It will URL-encode the given parameter values. If memo is MEMO_HASH or MEMO_RETURN it will bese64 encode it and the url encode it.
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md#operation-pay
    ///
    /// - Parameter destination: A valid account ID or payment address that will be used as destination for the payment.
    /// - Parameter amount: Amount that destination will receive.
    /// - Parameter assetCode: Asset code (XLM if not present) destination will receive.
    /// - Parameter assetIssuer: Account ID of asset issuer (XLM if not present) destination will receive.
    /// - Parameter memo: A memo to be included in the payment / path payment.
    /// - Parameter memoType: One of MEMO_TEXT, MEMO_ID,MEMO_HASH, MEMO_RETURN.
    /// - Parameter callBack: A URL callback that will be used to send the transactionXDR to.
    /// - Parameter message: A query parameter to indicate any additional information that the website or application wants to show the user in her wallet.
    /// - Parameter networkPassphrase: Only needs to be set if this transaction is for other network than the public one.
    /// - Parameter originDomain: A fully qualified domain name that specifies the originating domain of the URI request.
    /// - Parameter signature: A signature of the hash of the URI request (excluding the signature field and value itself).
    ///
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
    
    
    /// This function signs the transaction and sends it to the network. It throws a 'HorizonRequestError' on validation error.
    ///
    /// - Parameter forURL: A URIScheme compliant URL that was generated for the sign operation.
    /// - Parameter signerKeyPair: The KeyPair of the signer account.
    /// - Parameter transactionConfirmation: A closure to be used to confirm the transactionXDR it's valid.
    ///
    @available(*, renamed: "signAndSubmitTransaction(forURL:signerKeyPair:network:transactionConfirmation:)")
    public func signAndSubmitTransaction(forURL url: String,
                                signerKeyPair keyPair: KeyPair,
                                network: Network = .public,
                                transactionConfirmation: TransactionConfirmationClosure? = nil,
                                         completion: @escaping SubmitTransactionClosure) {
        Task {
            let result = await signAndSubmitTransaction(forURL: url, signerKeyPair: keyPair, network: network, transactionConfirmation: transactionConfirmation)
            completion(result)
        }
    }
    
    /// This function signs the transaction and sends it to the network. It throws a 'HorizonRequestError' on validation error.
    ///
    /// - Parameter forURL: A URIScheme compliant URL that was generated for the sign operation.
    /// - Parameter signerKeyPair: The KeyPair of the signer account.
    /// - Parameter transactionConfirmation: A closure to be used to confirm the transactionXDR it's valid.
    ///
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
    
    /// Sends the transaction to the callback url or to the stellar network if callback url is not set
    @available(*, renamed: "submitTransaction(transactionXDR:callback:keyPair:skipMemoRequiredCheck:)")
    private func submitTransaction(transactionXDR: TransactionXDR?, callback: String? = nil, keyPair: KeyPair, skipMemoRequiredCheck:Bool = false, completion: @escaping SubmitTransactionClosure) {
        Task {
            let result = await submitTransaction(transactionXDR: transactionXDR, callback: callback, keyPair: keyPair, skipMemoRequiredCheck: skipMemoRequiredCheck)
            completion(result)
        }
    }
    
    /// Sends the transaction to the callback url or to the stellar network if callback url is not set
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
    
    /// Gets the public key field value from the url.
    public func getValue(forParam param: SignTransactionParams, fromURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(param)") {
                return field.replacingOccurrences(of: "\(param)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Gets the transactionXDR field value from the url.
    private func getTransactionXDRFieldValue(fromURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(URISchemeName)\(SignOperation)\(SignTransactionParams.xdr)") {
                return field.replacingOccurrences(of: "\(URISchemeName)\(SignOperation)\(SignTransactionParams.xdr)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Gets the transactionXDR object corresponding to the xdr field value in the url.
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
