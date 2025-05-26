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
    
    public let destinationAccountId:String
    
    /// Creates a new AccountMergeOperation object.
    ///
    /// - Parameter destinationAccountId: The account that receives the remaining XLM balance of the source account.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(destinationAccountId:String, sourceAccountId:String?) throws {
        let mux = try destinationAccountId.decodeMuxedAccount()
        self.destinationAccountId = mux.accountId
        super.init(sourceAccountId:sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let mDestination = try destinationAccountId.decodeMuxedAccount()
        return OperationBodyXDR.accountMerge(mDestination)
    }
}
