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
    
    @available(*, deprecated, message: "use destinationAccountId instead")
    public let destination:KeyPair
    public let destinationAccountId:String
    
    /// Creates a new AccountMergeOperation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    /// - Parameter destination: The account that receives the remaining XLM balance of the source account.
    ///
    @available(*, deprecated, message: "use init(destinationAccountId:String, sourceAccountId:String?) instead")
    public init(sourceAccount:KeyPair? = nil, destination:KeyPair) {
        self.destination = destination
        self.destinationAccountId = destination.accountId
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new AccountMergeOperation object from the given PublicKey object representing the destination account.
    ///
    /// - Parameter destinatioAccountPublicKey: the PublicKey object representing the destination account to be used to create a new AccountMergeOperation object.
    @available(*, deprecated, message: "use init(destinationAccountId:String, sourceAccountId:String?) instead")
    public init(destinatioAccountPublicKey:PublicKey, sourceAccount:KeyPair? = nil) {
        self.destination = KeyPair(publicKey: destinatioAccountPublicKey)
        self.destinationAccountId = destination.accountId
        super.init(sourceAccount: sourceAccount)
    }
    
    /// Creates a new AccountMergeOperation object.
    ///
    /// - Parameter destinationAccountId: The account that receives the remaining XLM balance of the source account.
    /// - Parameter sourceAccountId: (optional) source account Id. Must start with "G" and must be valid, otherwise it will be ignored.
    ///
    public init(destinationAccountId:String, sourceAccountId:String?) throws {
        self.destinationAccountId = destinationAccountId
        self.destination = try KeyPair(accountId: self.destinationAccountId)
        super.init(sourceAccountId:sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let mDestination = try destinationAccountId.decodeMuxedAccount()
        return OperationBodyXDR.accountMerge(mDestination)
    }
}
