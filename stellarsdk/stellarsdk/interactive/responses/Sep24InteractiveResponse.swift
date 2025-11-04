import Foundation

/// Response returned when initiating an interactive deposit or withdrawal transaction.
///
/// This response contains the URL that the client should present to the user for completing
/// the interactive flow, along with a transaction ID for tracking the request.
///
/// See also:
/// - [Sep24DepositRequest] for initiating deposits
/// - [Sep24WithdrawRequest] for initiating withdrawals
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24InteractiveResponse: Decodable {

    /// Always set to interactive_customer_info_needed.
    public var type:String

    /// URL hosted by the anchor. The wallet should show this URL to the user as a popup.
    public var url:String

    /// The anchor's internal ID for this deposit / withdrawal request. The wallet will use this ID to query the /transaction endpoint to check status of the request.
    public var id:String

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case type
        case url
        case id
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        url = try values.decode(String.self, forKey: .url)
        id = try values.decode(String.self, forKey: .id)
    }
}
