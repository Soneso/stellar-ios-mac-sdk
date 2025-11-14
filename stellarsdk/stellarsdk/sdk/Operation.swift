//
//  Operation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Base class for all Stellar operations.
///
/// Operations are the building blocks of Stellar transactions. Each operation represents a
/// specific action on the Stellar network such as sending payments, creating accounts, or
/// managing offers. Operations are grouped into transactions and submitted to the network.
///
/// You should never instantiate this class directly. Instead, use one of its subclasses that
/// represent specific operation types. Each operation can optionally specify a source account
/// that differs from the transaction's source account.
///
/// Common operation types:
/// - PaymentOperation: Send assets between accounts
/// - CreateAccountOperation: Create and fund new accounts
/// - ChangeTrustOperation: Establish trustlines for assets
/// - ManageSellOfferOperation: Create or modify sell offers
/// - ManageBuyOfferOperation: Create or modify buy offers
/// - SetOptionsOperation: Configure account settings
/// - And many more...
///
/// Operation-level source accounts:
/// When an operation specifies a source account, that account will be used as the source for
/// that specific operation instead of the transaction's source account. This is useful for
/// multi-signature transactions or channel accounts.
///
/// Example:
/// ```swift
/// // Payment operation using transaction source account
/// let payment1 = try PaymentOperation(
///     sourceAccountId: nil,
///     destinationAccountId: "GDEST...",
///     asset: Asset(type: AssetType.ASSET_TYPE_NATIVE),
///     amount: 100.0
/// )
///
/// // Payment operation using different source account
/// let payment2 = try PaymentOperation(
///     sourceAccountId: "GSOURCE...",
///     destinationAccountId: "GDEST...",
///     asset: Asset(type: AssetType.ASSET_TYPE_NATIVE),
///     amount: 50.0
/// )
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
public class Operation {
    /// The source account for this operation. If nil, uses the transaction's source account.
    public private (set) var sourceAccountId:String? //"G..." or "M..."

    /// The XDR representation of the source account (supports muxed accounts).
    public private (set) var sourceAccountXdr: MuxedAccountXDR?

    /// Creates a new operation object.
    ///
    /// - Parameter sourceAccountId: Optional source account for this operation. If provided, must be a valid
    ///   account ID (G-address or M-address). If nil or invalid, the transaction's source account will be used.
    public init(sourceAccountId:String?) {
        
        if let saId = sourceAccountId, let mux = try? saId.decodeMuxedAccount() {
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
            return try ChangeTrustOperation(fromXDR: changeTrust, sourceAccountId: mSourceAccountId)
        case .allowTrust(let allowTrust):
            return AllowTrustOperation(fromXDR: allowTrust, sourceAccountId: mSourceAccountId)
        case .accountMerge(let destination):
            return try AccountMergeOperation(destinationAccountId: destination.accountId, sourceAccountId: mSourceAccountId)
        case .manageData(let manageData):
            return ManageDataOperation(fromXDR: manageData, sourceAccountId: mSourceAccountId)
        case .bumpSequence(let bumpSequenceData):
            return BumpSequenceOperation(fromXDR: bumpSequenceData, sourceAccountId: mSourceAccountId)
        case .createClaimableBalance(let data):
            return try CreateClaimableBalanceOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .claimClaimableBalance(let data):
            return try ClaimClaimableBalanceOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .beginSponsoringFutureReserves(let data):
            return try BeginSponsoringFutureReservesOperation(fromXDR: data, sponsoringAccountId: mSourceAccountId)
        case .endSponsoringFutureReserves:
            return EndSponsoringFutureReservesOperation(sponsoredAccountId: mSourceAccountId)
        case .revokeSponsorship(let data):
            return try RevokeSponsorshipOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .clawback(let data):
            return ClawbackOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .clawbackClaimableBalance(let data):
            return try ClawbackClaimableBalanceOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .setTrustLineFlags(let data):
            return SetTrustlineFlagsOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .liquidityPoolDeposit(let data):
            return LiquidityPoolDepositOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .liquidityPoolWithdraw(let data):
            return LiquidityPoolWithdrawOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .invokeHostFunction(let data):
            return try InvokeHostFunctionOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .extendFootprintTTL(let data):
            return ExtendFootprintTTLOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        case .restoreFootprint(let data):
            return RestoreFootprintOperation(fromXDR: data, sourceAccountId: mSourceAccountId)
        default:
            throw StellarSDKError.invalidArgument(message: "Unknown operation body \(operationXDR.body)")
        }
    }

    /// Encodes the operation to a base64-encoded XDR string for serialization or transmission.
    public func toXDRBase64() throws -> String {
        let xdr = try toXDR()
        return try Data(XDREncoder.encode(xdr)).base64EncodedString()
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
