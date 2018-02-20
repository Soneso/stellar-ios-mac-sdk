//
//  Operation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Superclass for operations. You should never use this class directly. Please use one of its subclasses.
    See [Stellar Guides] (https://www.stellar.org/developers/guides/concepts/operations.html, "Operations")
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html, "List of Operations")
 */

public class Operation {
    let sourceAccount:KeyPair?
    
    /**
        Initializer
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
     */
    public init(sourceAccount:KeyPair?) {
        self.sourceAccount = sourceAccount
    }
    
    /// Generates Operation XDR object.
    public func toXDR() throws -> OperationXDR {
        return try OperationXDR(sourceAccount: sourceAccount?.publicKey, body: getOperationBodyXDR())
    }
    
    public func fromXDR(operationXDR:OperationXDR) throws -> Operation {
        switch operationXDR.body {
        case .createAccount(let account):
            return CreateAccountOperation(fromXDR: account)
        case .payment(let payment):
            return PaymentOperation(fromXDR: payment)
        case .pathPayment(let pathPayment):
            return PathPaymentOperation(fromXDR: pathPayment)
        case .manageOffer(let manageOffer):
            return ManageOfferOperation(fromXDR: manageOffer)
        case .createPassiveOffer(let passiveOffer):
            return CreatePassiveOfferOperation(fromXDR: passiveOffer)
        case .setOptions(let setOptions):
            return SetOptionsOperation(fromXDR: setOptions)
        case .changeTrust(let changeTrust):
            return ChangeTrustOperation(fromXDR: changeTrust)
        case .allowTrust(let allowTrust):
            return AllowTrustOperation(fromXDR: allowTrust)
        case .accountMerge(let publicKey):
            return AccountMergeOperation(publicKeyXDR: publicKey)
        case .manageData(let manageData):
            return ManageDataOperation(fromXDR: manageData)
        default:
            throw StellarSDKError.invalidArgument(message: "Unknown operation body \(operationXDR.body)")
        }
    }
    
    func getOperationBodyXDR() throws -> OperationBodyXDR {
        throw StellarSDKError.invalidArgument(message: "Method must be overridden by subclass")
    }
    
    func toXDRAmount(amount:Int64) -> Int64 {
        return amount * 10000000
    }
    
    static func fromXDRAmount(_ xdrAmount:Int64) -> Int64 {
        return xdrAmount / 10000000
    }
}
