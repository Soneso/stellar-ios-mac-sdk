import Foundation

/// Request parameters for querying transaction fees via SEP-0024.
///
/// This struct encapsulates the parameters needed to request fee information
/// from an anchor before initiating a deposit or withdrawal transaction.
///
/// See also:
/// - [InteractiveService.getFee] for the method that uses this request
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24FeeRequest: Sendable {

    /// Kind of operation (deposit or withdraw).
    public var operation:String

    /// Type of deposit or withdrawal (SEPA, bank_account, cash, etc.).
    public var type:String?

    /// Asset code.
    public var assetCode:String

    /// Amount of the asset that will be deposited/withdrawn.
    public var amount:Double

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String?

    /// Creates a new fee request.
    ///
    /// - Parameters:
    ///   - operation: Kind of operation (deposit or withdraw)
    ///   - type: Type of deposit or withdrawal (optional)
    ///   - assetCode: Asset code
    ///   - amount: Amount of the asset that will be deposited/withdrawn
    ///   - jwt: JWT from SEP-10 authentication (optional)
    public init(operation:String, type:String? = nil, assetCode:String, amount:Double, jwt:String? = nil) {
        self.type = type
        self.assetCode = assetCode
        self.amount = amount
        self.operation = operation
        self.jwt = jwt
    }
}
