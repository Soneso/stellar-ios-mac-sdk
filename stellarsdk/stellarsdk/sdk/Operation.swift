//
//  Operation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Superclass for operations. You should never use this class directly. Please use one of its subclasses.
/// See [Stellar Guides] (https://www.stellar.org/developers/guides/concepts/operations.html, "Operations")
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html, "List of Operations")
public class Operation {
    public let sourceAccount:KeyPair?
    
    /// Creates a new operation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    ///
    public init(sourceAccount:KeyPair?) {
        self.sourceAccount = sourceAccount
    }
    
    /// Generates Operation XDR object.
    public func toXDR() throws -> OperationXDR {
        return try OperationXDR(sourceAccount: sourceAccount?.publicKey, body: getOperationBodyXDR())
    }
    
    /// Creates a new Operation object from the given OperationXDR object.
    ///
    /// - Parameter operationXDR: the OperationXDR object to be used for creating the new Operation object.
    ///
    /// - Returns the created Operation object
    ///
    /// - Throws StellarSDKError.invalidArgument error if the given OperationXDR object has an unknown type.
    ///
    public static func fromXDR(operationXDR:OperationXDR) throws -> Operation {
        var source: KeyPair?
        if let publicKey = operationXDR.sourceAccount {
            source = KeyPair(publicKey: publicKey)
        }
        switch operationXDR.body {
        case .createAccount(let account):
            return CreateAccountOperation(fromXDR: account, sourceAccount: source)
        case .payment(let payment):
            return PaymentOperation(fromXDR: payment, sourceAccount: source)
        case .pathPayment(let pathPayment):
            return PathPaymentOperation(fromXDR: pathPayment, sourceAccount: source)
        case .manageOffer(let manageOffer):
            return ManageOfferOperation(fromXDR: manageOffer, sourceAccount: source)
        case .createPassiveOffer(let passiveOffer):
            return CreatePassiveOfferOperation(fromXDR: passiveOffer, sourceAccount: source)
        case .setOptions(let setOptions):
            return SetOptionsOperation(fromXDR: setOptions, sourceAccount: source)
        case .changeTrust(let changeTrust):
            return ChangeTrustOperation(fromXDR: changeTrust, sourceAccount: source)
        case .allowTrust(let allowTrust):
            return AllowTrustOperation(fromXDR: allowTrust, sourceAccount: source)
        case .accountMerge(let publicKey):
            return AccountMergeOperation(destinatioAccountPublicKey: publicKey, sourceAccount: source)
        case .manageData(let manageData):
            return ManageDataOperation(fromXDR: manageData, sourceAccount: source)
        case .bumpSequence(let bumpSequenceData):
            return BumpSequenceOperation(fromXDR: bumpSequenceData, sourceAccount: source)
        default:
            throw StellarSDKError.invalidArgument(message: "Unknown operation body \(operationXDR.body)")
        }
    }
    
    public func toXDRBase64() throws -> String {
        let xdr = try toXDR()
        return try Data(bytes: XDREncoder.encode(xdr)).base64EncodedString()
    }
    
    func getOperationBodyXDR() throws -> OperationBodyXDR {
        throw StellarSDKError.invalidArgument(message: "Method must be overridden by subclass")
    }
    
    static func toXDRAmount(amount:Decimal) -> Int64 {
        let multiplied = amount * 10000000
        let decimalNumber = NSDecimalNumber(decimal: multiplied)
        let handler = NSDecimalNumberHandler(roundingMode: NSDecimalNumber.RoundingMode.bankers, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let rounded = decimalNumber.rounding(accordingToBehavior: handler)
        
        return rounded.int64Value
    }
    
    static func fromXDRAmount(_ xdrAmount:Int64) -> Decimal {
        var decimal = Decimal(xdrAmount)
        decimal = decimal / 10000000
        
        return decimal
    }
}
