//
//  CreateAccountOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a create account operation. This operation creates and funds a new account with the specified starting balance.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-account, "Create Account Operation").
public class CreateAccountOperation:Operation {
    
    public let destination:KeyPair
    public let startBalance:Decimal
    
    /// Creates a new CreateAccountOperation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    /// - Parameter destination: Account address that is created and funded.
    /// - Parameter startBalance: Amount of XLM to send to the newly created account. This XLM comes from the source account.
    @available(*, deprecated, message: "use init(sourceAccountId:String?, ...) instead")
    public init(sourceAccount:KeyPair? = nil, destination:KeyPair, startBalance:Decimal) {
        self.destination = destination
        self.startBalance = startBalance
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new CreateAccountOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    /// - Parameter destination: Account address that is created and funded.
    /// - Parameter startBalance: Amount of XLM to send to the newly created account. This XLM comes from the source account.
    ///
    public init(sourceAccountId:String?, destination:KeyPair, startBalance:Decimal) {
        self.destination = destination
        self.startBalance = startBalance
        super.init(sourceAccountId:sourceAccountId)
    }

    /// Creates a new CreateAccountOperation object from the given CreateAccountOperationXDR object.
    ///
    /// - Parameter fromXDR: the CreateAccountOperationXDR object to be used to create a new CreateAccountOperation object.
    ///
    @available(*, deprecated, message: "use init(..., sourceAccountId:String?) instead")
    public init(fromXDR:CreateAccountOperationXDR, sourceAccount:KeyPair? = nil) {
        self.destination = KeyPair(publicKey: fromXDR.destination)
        self.startBalance = Operation.fromXDRAmount(fromXDR.startingBalance)
        super.init(sourceAccount: sourceAccount)
    }
    
    /// Creates a new CreateAccountOperation object from the given CreateAccountOperationXDR object.
    ///
    /// - Parameter fromXDR: the CreateAccountOperationXDR object to be used to create a new CreateAccountOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:CreateAccountOperationXDR, sourceAccountId:String?) {
        self.destination = KeyPair(publicKey: fromXDR.destination)
        self.startBalance = Operation.fromXDRAmount(fromXDR.startingBalance)
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.createAccount(CreateAccountOperationXDR(destination: destination.publicKey,
                                                                        balance: Operation.toXDRAmount(amount: startBalance)))
    }
}
