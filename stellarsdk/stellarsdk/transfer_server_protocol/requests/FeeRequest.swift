import Foundation

/// Request parameters for retrieving fee information via SEP-0006.
///
/// This struct encapsulates all the parameters needed to query the anchor's fee structure
/// for a specific deposit or withdrawal operation. The /fee endpoint is deprecated and optional,
/// as fee information can typically be provided through the /info endpoint using fee_fixed and
/// fee_percent fields.
///
/// Note: This endpoint is deprecated. Anchors are recommended to express fees through the
/// /info endpoint to provide a better user experience, allowing users to see fee structures
/// early in the process. This endpoint should only be used for complex fee structures that
/// cannot be adequately represented in the /info endpoint.
///
/// See also:
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
public struct FeeRequest: Sendable {

    /// Kind of operation: deposit or withdraw.
    public var operation:String

    /// Stellar asset code.
    public var assetCode:String

    /// Amount of the asset that will be deposited or withdrawn.
    public var amount:Double

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String?

    /// Type of deposit or withdrawal.
    /// Examples: SEPA, bank_account, cash, etc.
    public var type:String?

    /// Creates a new fee request.
    ///
    /// - Parameters:
    ///   - operation: The kind of operation (deposit or withdraw)
    ///   - type: Optional type of operation (SEPA, bank_account, etc)
    ///   - assetCode: The Stellar asset code
    ///   - amount: The amount that will be deposited or withdrawn
    ///   - jwt: Optional JWT token from SEP-10 authentication
    public init(operation:String, type:String? = nil, assetCode:String, amount:Double, jwt:String? = nil) {
        self.type = type
        self.assetCode = assetCode
        self.amount = amount
        self.operation = operation
        self.jwt = jwt
    }
}
