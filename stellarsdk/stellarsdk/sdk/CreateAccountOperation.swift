//
//  CreateAccountOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a create account operation that creates and funds a new account.
///
/// CreateAccountOperation creates a new account on the Stellar network and funds it with
/// an initial balance of native XLM. The new account must not already exist on the network,
/// and the starting balance must meet the minimum account reserve requirement.
///
/// The minimum starting balance is determined by the network's base reserve (currently 0.5 XLM)
/// multiplied by 2 (one for the account, one for the native balance). Additional reserves are
/// required for each trustline, offer, signer, or data entry added to the account.
///
/// The operation will fail if:
/// - The destination account already exists
/// - The starting balance is below the minimum reserve requirement
/// - The source account has insufficient XLM balance
/// - The destination account ID is invalid
///
/// Example:
/// ```swift
/// // Create and fund a new account with 10 XLM
/// let newKeyPair = try KeyPair.generateRandomKeyPair()
/// let createAccount = CreateAccountOperation(
///     sourceAccountId: nil,
///     destination: newKeyPair,
///     startBalance: 10.0
/// )
///
/// // Or using an existing account ID
/// let createAccount2 = try CreateAccountOperation(
///     sourceAccountId: nil,
///     destinationAccountId: "GNEW...",
///     startBalance: 10.0
/// )
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
public class CreateAccountOperation:Operation, @unchecked Sendable {

    /// The keypair representing the new account to be created.
    public let destination:KeyPair

    /// The starting balance in XLM to fund the new account.
    public let startBalance:Decimal

    /// Creates a new CreateAccountOperation.
    ///
    /// - Parameter sourceAccountId: Optional source account. If nil, uses the transaction source account.
    /// - Parameter destination: KeyPair representing the new account to create
    /// - Parameter startBalance: Starting XLM balance for the new account (must meet minimum reserve)
    public init(sourceAccountId:String?, destination:KeyPair, startBalance:Decimal) {
        self.destination = destination
        self.startBalance = startBalance
        super.init(sourceAccountId:sourceAccountId)
    }

    /// Creates a new CreateAccountOperation using a destination account ID string.
    ///
    /// - Parameter sourceAccountId: Optional source account. If nil, uses the transaction source account.
    /// - Parameter destinationAccountId: The account ID of the new account to create (G-address)
    /// - Parameter startBalance: Starting XLM balance for the new account (must meet minimum reserve)
    /// - Throws: An error if the destination account ID is invalid
    public init(sourceAccountId:String?, destinationAccountId:String, startBalance:Decimal) throws {
        self.destination = try KeyPair(accountId: destinationAccountId)
        self.startBalance = startBalance
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new CreateAccountOperation object from the given CreateAccountOperationXDR object.
    ///
    /// - Parameter fromXDR: the CreateAccountOperationXDR object to be used to create a new CreateAccountOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
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
