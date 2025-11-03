//
//  PaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a payment operation that sends an asset from one account to another.
///
/// PaymentOperation is one of the most common operations on the Stellar network. It sends a
/// specified amount of an asset (native XLM or issued assets) from the source account to a
/// destination account. The destination account must already exist and, for non-native assets,
/// must have a trustline established for that asset.
///
/// The payment operation will fail if:
/// - The destination account does not exist
/// - The destination lacks a trustline for non-native assets
/// - The source account has insufficient balance
/// - The destination account would exceed asset limits
/// - The asset issuer has authorization controls that prevent the transfer
///
/// Example:
/// ```swift
/// // Send 100 XLM
/// let payment = try PaymentOperation(
///     sourceAccountId: nil,
///     destinationAccountId: "GDEST...",
///     asset: Asset(type: AssetType.ASSET_TYPE_NATIVE),
///     amount: 100.0
/// )
///
/// // Send 50 USD (issued asset)
/// let usd = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
///                 code: "USD",
///                 issuer: "GISSUER...")!
/// let usdPayment = try PaymentOperation(
///     sourceAccountId: nil,
///     destinationAccountId: "GDEST...",
///     asset: usd,
///     amount: 50.0
/// )
/// ```
///
/// See also:
/// - [Payment Operation](https://developers.stellar.org/docs/learn/fundamentals/transactions/list-of-operations#payment)
/// - [Assets](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/assets)
public class PaymentOperation:Operation {

    /// The destination account that will receive the payment.
    public let destinationAccountId:String

    /// The asset being sent.
    public let asset:Asset

    /// The amount of the asset to send (in decimal format).
    public let amount:Decimal

    /// Creates a new PaymentOperation.
    ///
    /// - Parameter sourceAccountId: Optional source account. If nil, uses the transaction source account.
    /// - Parameter destinationAccountId: The account that will receive the payment (G-address or M-address)
    /// - Parameter asset: The asset to send (native XLM or issued asset)
    /// - Parameter amount: The amount to send in decimal format
    /// - Throws: An error if the destination account ID is invalid
    public init(sourceAccountId:String?, destinationAccountId:String, asset:Asset, amount:Decimal) throws {
        
        let mux = try destinationAccountId.decodeMuxedAccount()
        self.destinationAccountId = mux.accountId
        self.asset = asset
        self.amount = amount
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new PaymentOperation object from the given PaymentOperationXDR object.
    ///
    /// - Parameter fromXDR: the PaymentOperationXDR object to be used to create a new PaymentOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:PaymentOperationXDR, sourceAccountId:String?) {
        self.destinationAccountId = fromXDR.destination.accountId
        self.asset = try! Asset.fromXDR(assetXDR: fromXDR.asset)
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let assetXDR = try asset.toXDR()
        let xdrAmount = Operation.toXDRAmount(amount: amount)
        let mDestination = try destinationAccountId.decodeMuxedAccount()
        return OperationBodyXDR.payment(PaymentOperationXDR(destination: mDestination,
                                                            asset:assetXDR,
                                                            amount: xdrAmount))
    }
}
