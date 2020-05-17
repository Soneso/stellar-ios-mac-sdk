//
//  FeeBumpTransaction.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum FeeBumpTransactionError: Error {
    case feeSmallerThanBaseFee(message: String)
    case feeSmallerThanInnerTransactionFee(message: String)
}

/// Represents a Fee Bump Transaction in Stellar network.
/// See https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md
public class FeeBumpTransaction {
    
    public let fee:UInt64
    public let sourceAccount:TransactionAccount
    public let innerTransaction:Transaction
    public private(set) var feeBumpTransactionXDR:FeeBumpTransactionXDR
    public private(set) var innerTransactionXDR:FeeBumpTransactionXDR.InnerTransactionXDR
    public static let MIN_BASE_FEE:UInt32 = 100
    
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
        
        if fee < FeeBumpTransaction.MIN_BASE_FEE {
            throw FeeBumpTransactionError.feeSmallerThanBaseFee(message: "fee cannot be smaller than the BASE_FEE :\(FeeBumpTransaction.MIN_BASE_FEE)")
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
    
    /// Returns the base64 encoded transaction envelope xdr to be used to post the transaction. Transaction need to have at least one signature before they can be sent to the stellar network.
    public func encodedEnvelope() throws -> String {
        return try feeBumpTransactionXDR.encodedEnvelope()
    }
    
    public func getTransactionHash(network:Network) throws -> String {
        let transactionHash = try [UInt8](feeBumpTransactionXDR.hash(network: network))
        let str = Data(bytes: transactionHash).hexEncodedString()
        return str
    }
    
    public func getTransactionHashData(network:Network) throws -> Data {
        let transactionHash = try [UInt8](feeBumpTransactionXDR.hash(network: network))
        let data = Data(bytes: transactionHash)
        return data
    }
}
