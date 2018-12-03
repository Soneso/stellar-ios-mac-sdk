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
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a transaction setup.
public typealias SetupTransactionXDRClosure = (_ completion: SetupTransactionXDREnum) -> (Void)

/// A closure to be called with the response from a transaction submission.
public typealias SubmitTransactionClosure = (_ completion: SubmitTransactionEnum) -> (Void)

/// A closure to be callded for the confirmation of a transaction.
public typealias TransactionConfirmationClosure = ((TransactionXDR) -> (Bool))

public class URIScheme: NSObject {
    let sdk = StellarSDK()
    
    /// This function is used to generate a URIScheme compliant URL to serve as a request to sign a transaction.
    ///
    /// - Parameter transactionXDR: A TransactionXDR object representing a transaction on the stellar network.
    /// - Parameter callBack: A URL callback that will be used to send the transactionXDR to.
    /// - Parameter publicKey: A publicKey that will be used to sign the url for.
    /// - Parameter message: A query parameter to indicate any additional information that the website or application wants to show the user in her wallet.
    /// - Parameter networkPassphrase: Only needs to be set if this transaction is for other network than the public one.
    /// - Parameter originDomain: A fully qualified domain name that specifies the originating domain of the URI request.
    /// - Parameter publicKey: A signature of the hash of the URI request (excluding the signature field and value itself).
    ///
    public func getSignTransactionURI(transactionXDR: TransactionXDR, callBack: String? = nil, publicKey: String? = nil, message: String? = nil, networkPassphrase: String? = nil,
                                      originDomain: String? = nil, signature: String? = nil) -> String {
        var uriScheme = URISchemeName
        if let encodedEnvelope = try? transactionXDR.encodedEnvelope(), let urlEncondedEnvelope = encodedEnvelope.urlEncoded {
            var params: [String] = []
           
            uriScheme += SignOperation
            
            params.append("\(SignTransactionParams.xdr)=\(urlEncondedEnvelope)")
            
            if let callBack = callBack, let urlEncodedCallBack = callBack.urlEncoded {
                params.append("\(SignTransactionParams.callback)=\(urlEncodedCallBack)")
            }
            
            if let publicKey = publicKey {
                params.append("\(SignTransactionParams.pubkey)=\(publicKey)")
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
    ///
    /// - Parameter accountID: A valid account ID or payment address that will be used as destination for the payment.
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
    public func getPayOperationURI(accountID: String, amount: Decimal? = nil, assetCode: String? = nil, assetIssuer: String? = nil, memo: String? = nil,
                                   memoType: String? = MemoTypeAsString.TEXT, callBack: String? = nil, message: String? = nil, networkPassphrase: String? = nil,
                                   originDomain: String? = nil, signature: String? = nil) -> String {
        var params: [String] = []
        var uriScheme = URISchemeName
        uriScheme += PayOperation
        
        params.append("\(PayOperationParams.destination)=\(accountID)")
        
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
    
    /// This function signs the transaction and sends it to the network.
    ///
    /// - Parameter forURL: A URIScheme compliant URL that was generated for the sign operation.
    /// - Parameter signerKeyPair: The KeyPair of the signer account.
    /// - Parameter transactionConfirmation: A closure to be used to confirm the transactionXDR it's valid.
    ///
    /// - Throws:
    ///     - A 'HorizonRequestError' error depending on the error case.
    ///
    public func signTransaction(forURL url: String, signerKeyPair keyPair: KeyPair, network: Network = .public, transactionConfirmation: TransactionConfirmationClosure? = nil, completion: @escaping SubmitTransactionClosure) {
        if let transactionXDR = getTransactionXDR(fromURL: url) {
            if let isConfirmed = transactionConfirmation?(transactionXDR), !isConfirmed {
                completion(.failure(error: HorizonRequestError.requestFailed(message: "Transaction was not confirmed!")))
                return
            }
            
            setupTransactionXDR(transactionXDR: transactionXDR, signerKeyPair: keyPair, publicKey: getValue(forParam: SignTransactionParams.pubkey, fromURL: url)) { (response) -> (Void) in
                switch response {
                case .success(transactionXDR: var transaction):
                    if transaction?.sourceAccount.accountId == keyPair.accountId {
                        try? transaction?.sign(keyPair: keyPair, network: .testnet)
                        let callback = self.getValue(forParam: .callback, fromURL: url)
                        self.submitTransaction(transactionXDR: transaction, callback: callback, keyPair: keyPair, completion: { (response) -> (Void) in
                            completion(response)
                        })
                    } else {
                        completion(.failure(error: HorizonRequestError.requestFailed(message: "Transaction's source account is no match for signer's public key!")))
                    }
                case .failure(error: let error):
                    completion(.failure(error: error))
                }
            }
        } else {
            completion(.failure(error: HorizonRequestError.requestFailed(message: "TransactionXDR missing from url!")))
        }
    }
    
    /// Sends the transaction to the network.
    private func submitTransaction(transactionXDR: TransactionXDR?, callback: String? = nil, keyPair: KeyPair, completion: @escaping SubmitTransactionClosure) {
        if let transactionEncodedEnvelope = try? transactionXDR?.encodedEnvelope(), let transactionEnvelope = transactionEncodedEnvelope {
            if var callback = callback, callback.hasPrefix("uri:") {
                callback = String(callback.dropLast(4))
                let serviceHelper = ServiceHelper(baseURL: callback)
                let data = try? JSONSerialization.data(withJSONObject: ["xdr":transactionEncodedEnvelope], options: .prettyPrinted)
                serviceHelper.POSTRequestWithPath(path: "", body: data) { (response) -> (Void) in
                    let _ = serviceHelper
                    switch response {
                    case .success(_):
                        completion(.success)
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                }
            } else {
                self.sdk.transactions.postTransaction(transactionEnvelope: transactionEnvelope, response: { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        completion(.success)
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                })
            }
        } else {
            completion(.failure(error: HorizonRequestError.requestFailed(message: "encodedEnvelop failed!")))
        }
    }
    
    /// Sets the sequence number for the transaction.
    private func setTransactionXDRSequenceNr(transactionXDR: TransactionXDR, signerKeyPair: KeyPair, completion: @escaping SetupTransactionXDRClosure) {
        sdk.accounts.getAccountDetails(accountId: transactionXDR.sourceAccount.accountId) { (response) -> (Void) in
            switch response {
            case .success(details: let accountDetails):
                let reconfiguredTransactionXDR = TransactionXDR(sourceAccount: transactionXDR.sourceAccount,
                                                            seqNum: accountDetails.incrementedSequenceNumber(),
                                                            timeBounds: transactionXDR.timeBounds,
                                                            memo: transactionXDR.memo,
                                                            operations: transactionXDR.operations)
                completion(.success(transactionXDR: reconfiguredTransactionXDR))
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Sets the source account and sequence number for the transaction.
    private func setTransactionXDRSourceAndSequenceNr(transactionXDR: TransactionXDR, signerAccountID: String, completion: @escaping SetupTransactionXDRClosure) {
        sdk.accounts.getAccountDetails(accountId: signerAccountID) { (response) -> (Void) in
            switch response {
            case .success(details: let accountDetails):
                let reconfiguredTransactionXDR = TransactionXDR(sourceAccount: accountDetails.keyPair.publicKey,
                                                            seqNum: accountDetails.incrementedSequenceNumber(),
                                                            timeBounds: transactionXDR.timeBounds,
                                                            memo: transactionXDR.memo,
                                                            operations: transactionXDR.operations)
                completion(.success(transactionXDR: reconfiguredTransactionXDR))
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    /// Checks and sets the transaction's source account and sequence number if they're missing.
    private func setupTransactionXDR(transactionXDR: TransactionXDR, signerKeyPair: KeyPair, publicKey: String? = nil, completion: @escaping SetupTransactionXDRClosure) {
        let sourceAccountIsEmpty = transactionXDR.sourceAccount.accountId.isEmpty
        let sequenceNumberIsEmpty = transactionXDR.seqNum == 0
        let signerAccountID = publicKey ?? signerKeyPair.accountId
        if sourceAccountIsEmpty && sequenceNumberIsEmpty {
            setTransactionXDRSourceAndSequenceNr(transactionXDR: transactionXDR, signerAccountID: signerAccountID) { (response) -> (Void) in
                switch response {
                case .success(transactionXDR: let transaction):
                    completion(.success(transactionXDR: transaction))
                case .failure(error: let error):
                    completion(.failure(error: error))
                }
            }
            
        } else if !sourceAccountIsEmpty && sequenceNumberIsEmpty {
            setTransactionXDRSequenceNr(transactionXDR: transactionXDR, signerKeyPair: signerKeyPair) { (response) -> (Void) in
                switch response {
                case .success(transactionXDR: let transaction):
                    completion(.success(transactionXDR: transaction))
                case .failure(error: let error):
                    completion(.failure(error: error))
                }
            }
        } else {
            completion(.success(transactionXDR: transactionXDR))
        }
    }
    
    /// Gets the public key field value from the url.
    private func getValue(forParam param: SignTransactionParams, fromURL url: String) -> String? {
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
        let base64UrlEncodedTransaction = getTransactionXDRFieldValue(fromURL: url)
        let base64Transaction = base64UrlEncodedTransaction?.urlDecoded
        if let base64Transaction = base64Transaction {
            if let transactionXDR = try? TransactionXDR(fromBinary: XDRDecoder.init(data: [UInt8].init(base64: base64Transaction))) {
                return transactionXDR
            }
        }
        
        return nil
    }
}
