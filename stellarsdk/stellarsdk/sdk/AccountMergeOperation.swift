//
//  AccountMergeOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account merge operation. Transfers the native balance (the amount of XLM an account holds) to another account and removes the source account from the ledger.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#account-merge, "Account Merge Operations").
public class AccountMergeOperation:Operation {
    
    public let destination:KeyPair
    
    /// Creates a new AccountMergeOperation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    /// - Parameter destination: The account that receives the remaining XLM balance of the source account.
    ///
    public init(sourceAccount:KeyPair? = nil, destination:KeyPair) {
        self.destination = destination
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new AccountMergeOperation object from the given PublicKey object representing the destination account.
    ///
    /// - Parameter destinatioAccountPublicKey: the PublicKey object representing the destination account to be used to create a new AccountMergeOperation object.
    ///
    public init(destinatioAccountPublicKey:PublicKey, sourceAccount:KeyPair? = nil) {
        self.destination = KeyPair(publicKey: destinatioAccountPublicKey)
        super.init(sourceAccount: sourceAccount)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.accountMerge(destination.publicKey)
    }
}
