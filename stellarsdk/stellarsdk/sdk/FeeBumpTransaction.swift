//
//  FeeBumpTransaction.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur when creating fee bump transactions.
public enum FeeBumpTransactionError: Error {
    /// Fee is smaller than the minimum base fee required by the network.
    case feeSmallerThanBaseFee(message: String)
    /// Fee is smaller than the inner transaction's fee.
    case feeSmallerThanInnerTransactionFee(message: String)
}

/// Represents a Fee Bump Transaction in Stellar network.
/// See https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md
public class FeeBumpTransaction {

    /// The maximum fee willing to pay for the fee bump transaction in stroops.
    public let fee:UInt64
    /// The account paying the fee for the bumped transaction.
    public let sourceAccount:TransactionAccount
    /// The account ID of the source account paying the fee.
    public let sourceAccountId:String
    /// The transaction being fee-bumped.
    public let innerTransaction:Transaction
    /// The XDR representation of this fee bump transaction.
    public private(set) var feeBumpTransactionXDR:FeeBumpTransactionXDR
    /// The XDR representation of the inner transaction.
    public private(set) var innerTransactionXDR:FeeBumpTransactionXDR.InnerTransactionXDR

    /// The base64-encoded XDR string of this fee bump transaction.
    public var xdrEncoded: String? {
        get {
            return feeBumpTransactionXDR.xdrEncoded
        }
    }
    
    /// Creates a new FeeBumpTransaction object.
    ///
    /// - Parameter sourceAccount: Account that originates the transaction.
    /// - Parameter fee: A fee-bump transaction has an effective number of operations equal to one plus the number of operations in the inner transaction. Correspondingly, the minimum fee for the fee-bump transaction is one base fee more than the minimum fee for the inner transaction. Similarly, the fee rate (see CAP-0005) is normalized by one plus the number of operations in the inner transaction rather than the number of operations in the inner transaction alone.
    /// - Parameter innterTransaction: fee bump inner transaction
    ///
    public init(sourceAccount:MuxedAccount, fee:UInt64, innerTransaction:Transaction) throws {

        if fee < StellarProtocolConstants.MIN_BASE_FEE {
            throw FeeBumpTransactionError.feeSmallerThanBaseFee(message: "fee cannot be smaller than the BASE_FEE :\(StellarProtocolConstants.MIN_BASE_FEE)")
        }
        var innerBaseFee = innerTransaction.transactionXDR.fee
        let operationsCount = innerTransaction.operations.count
        if operationsCount > 0 {
            innerBaseFee = innerBaseFee / UInt32(operationsCount)
        }
        if fee < innerBaseFee {
            throw FeeBumpTransactionError.feeSmallerThanBaseFee(message: "base fee cannot be lower than provided inner transaction  fee :\(innerBaseFee)")
        }
        
        
        self.sourceAccount = sourceAccount
        self.sourceAccountId = sourceAccount.accountId
        self.fee = fee
        self.innerTransaction = innerTransaction
        self.innerTransactionXDR = try FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerTransaction.transactionXDR.toEnvelopeV1XDR())
        
        self.feeBumpTransactionXDR = FeeBumpTransactionXDR(sourceAccount: sourceAccount.xdr, innerTx: self.innerTransactionXDR, fee: self.fee)
        
        self.sourceAccount.incrementSequenceNumber()
        
    }
    
    /// Each transaction needs to be signed before sending it to the stellar network.
    ///
    /// - Parameter keyPair: key pair to be used as a signer. Must containing the private key.
    /// - Parameter network: Network to specify which Stellar network you want to use.
    ///
    public func sign(keyPair:KeyPair, network:Network) throws {
        
        if (keyPair.privateKey == nil) {
            throw StellarSDKError.invalidArgument(message: "KeyPair must contain the private key to be able to sign the transaction.")
        }
        
        try self.feeBumpTransactionXDR.sign(keyPair: keyPair, network: network)
    }

    /// Adds a pre-computed signature to the fee bump transaction without requiring the private key.
    public func addSignature(signature:DecoratedSignatureXDR) -> Void {
        self.feeBumpTransactionXDR.addSignature(signature: signature)
    }

    /// Returns the base64-encoded transaction envelope XDR for submission to the network.
    public func encodedEnvelope() throws -> String {
        return try feeBumpTransactionXDR.encodedEnvelope()
    }

    /// Computes and returns the transaction hash as a hex-encoded string for the specified network.
    public func getTransactionHash(network:Network) throws -> String {
        let transactionHash = try [UInt8](feeBumpTransactionXDR.hash(network: network))
        let str = Data(transactionHash).base16EncodedString()
        return str
    }

    /// Computes and returns the transaction hash as Data for the specified network.
    public func getTransactionHashData(network:Network) throws -> Data {
        let transactionHash = try [UInt8](feeBumpTransactionXDR.hash(network: network))
        let data = Data(transactionHash)
        return data
    }
}
