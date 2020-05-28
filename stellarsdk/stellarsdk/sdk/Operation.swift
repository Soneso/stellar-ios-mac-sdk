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
    @available(*, deprecated, message: "use sourceAccountId instead")
    public private (set) var sourceAccount:KeyPair?
    public private (set) var sourceAccountId:String? //"G..." or "M..."
    public private (set) var sourceAccountXdr: MuxedAccountXDR?
    
    /// Creates a new operation object.
    ///
    /// - Parameter sourceAccount: (optional) Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    ///
    @available(*, deprecated, message: "use init(sourceAccountId:String?) instead")
    public init(sourceAccount:KeyPair?) {
        if let sa = sourceAccount, let mux = try? sa.accountId.decodeMuxedAccount() {
            self.sourceAccount = sourceAccount
            self.sourceAccountId = sa.accountId
            self.sourceAccountXdr = mux
        }
    }
    
    /// Creates a new operation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    ///
    public init(sourceAccountId:String?) {
        
        if let saId = sourceAccountId, let mux = try? saId.decodeMuxedAccount() {
            self.sourceAccount = try? KeyPair(accountId: saId)
            self.sourceAccountId = sourceAccountId
            self.sourceAccountXdr = mux
        }
    }
    
    /// Generates Operation XDR object.
    public func toXDR() throws -> OperationXDR {
        return try OperationXDR(sourceAccount: self.sourceAccountXdr, body: getOperationBodyXDR())
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
        var mSourceAccountId: String?
        if let mux = operationXDR.sourceAccount {
            mSourceAccountId = mux.accountId
        }
        switch operationXDR.body {
        case .createAccount(let account):
            return CreateAccountOperation(fromXDR: account, sourceAccountId: mSourceAccountId)
        case .payment(let payment):
            return PaymentOperation(fromXDR: payment, sourceAccountId: mSourceAccountId)
        case .pathPayment(let pathPaymentStrictReceive):
            return PathPaymentStrictReceiveOperation(fromXDR: pathPaymentStrictReceive, sourceAccountId: mSourceAccountId)
        case .pathPaymentStrictSend(let pathPaymentStrictSend):
            return PathPaymentStrictSendOperation(fromXDR: pathPaymentStrictSend, sourceAccountId: mSourceAccountId)
        case .manageSellOffer(let manageOffer):
            return ManageSellOfferOperation(fromXDR: manageOffer, sourceAccountId: mSourceAccountId)
        case .manageBuyOffer(let manageOffer):
            return ManageBuyOfferOperation(fromXDR: manageOffer, sourceAccountId: mSourceAccountId)
        case .createPassiveSellOffer(let passiveOffer):
            return CreatePassiveSellOfferOperation(fromXDR: passiveOffer, sourceAccountId: mSourceAccountId)
        case .setOptions(let setOptions):
            return SetOptionsOperation(fromXDR: setOptions, sourceAccountId: mSourceAccountId)
        case .changeTrust(let changeTrust):
            return ChangeTrustOperation(fromXDR: changeTrust, sourceAccountId: mSourceAccountId)
        case .allowTrust(let allowTrust):
            return AllowTrustOperation(fromXDR: allowTrust, sourceAccountId: mSourceAccountId)
        case .accountMerge(let destination):
            return try AccountMergeOperation(destinationAccountId: destination.accountId, sourceAccountId: mSourceAccountId)
        case .manageData(let manageData):
            return ManageDataOperation(fromXDR: manageData, sourceAccountId: mSourceAccountId)
        case .bumpSequence(let bumpSequenceData):
            return BumpSequenceOperation(fromXDR: bumpSequenceData, sourceAccountId: mSourceAccountId)
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
