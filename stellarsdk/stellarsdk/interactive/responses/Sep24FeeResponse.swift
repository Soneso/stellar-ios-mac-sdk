import Foundation

/// Response containing fee information for a deposit or withdrawal transaction.
///
/// This response is returned when querying the fee endpoint to determine the cost
/// of a deposit or withdrawal operation before initiating the transaction.
///
/// See also:
/// - [Sep24FeeRequest] for the corresponding request
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24FeeResponse: Decodable {

    /// The total fee (in units of the asset involved) that would be charged to deposit/withdraw the specified amount of asset_code.
    public var fee:Double


    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case fee
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fee = try values.decode(Double.self, forKey: .fee)
    }
}
