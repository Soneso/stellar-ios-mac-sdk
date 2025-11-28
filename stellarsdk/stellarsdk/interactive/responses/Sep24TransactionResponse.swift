import Foundation

/// Response containing multiple transactions.
///
/// This response is returned when querying for a list of transactions via the /transactions endpoint.
///
/// See also:
/// - [Sep24TransactionsRequest] for the corresponding request
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24TransactionsResponse: Decodable , Sendable {

    /// List of transactions.
    public let transactions: [Sep24Transaction]

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case transactions = "transactions"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactions = try values.decode([Sep24Transaction].self, forKey: .transactions)
    }
}

/// Response containing a single transaction.
///
/// This response is returned when querying for a specific transaction via the /transaction endpoint.
///
/// See also:
/// - [Sep24TransactionRequest] for the corresponding request
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24TransactionResponse: Decodable , Sendable {

    /// The transaction details.
    public let transaction: Sep24Transaction

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case transaction
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transaction = try values.decode(Sep24Transaction.self, forKey: .transaction)
    }
}

/// Details of a single deposit or withdrawal transaction.
///
/// Contains comprehensive information about the transaction status, amounts, fees, and identifiers
/// for both on-chain and off-chain components of the transaction.
///
/// See also:
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24Transaction: Decodable , Sendable {

    /// Unique, anchor-generated id for the deposit/withdrawal.
    public let id:String

    /// Type of transaction: deposit or withdrawal.
    public let kind:String

    /// Processing status of deposit/withdrawal.
    public let status:String
    
    /// Estimated number of seconds until a status change is expected.
    public let statusEta:Int?

    /// True if the anchor has verified the user's KYC information for this transaction.
    public let kycVerified:Bool?

    /// A URL that is opened by wallets after the interactive flow is complete. It can include banking information for users to start deposits, the status of the transaction, or any other information the user might need to know about the transaction.
    public let moreInfoUrl:String?

    /// Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds.
    public let amountIn:String?

    /// The asset received or to be received by the Anchor. Must be present if the deposit/withdraw was made using non-equivalent assets.
    /// The value must be in SEP-38 Asset Identification Format.
    public let amountInAsset:String?

    /// Amount sent by anchor to user at end of transaction as a string with up to 7 decimals.
    /// Excludes amount converted to XLM to fund account and any external fees.
    public let amountOut:String?

    /// The asset delivered or to be delivered to the user. Must be present if the deposit/withdraw was made using non-equivalent assets.
    /// The value must be in SEP-38 Asset Identification Format.
    public let amountOutAsset:String?

    /// Amount of fee charged by anchor.
    public let amountFee:String?

    /// The asset in which fees are calculated in. Must be present if the deposit/withdraw was made using non-equivalent assets.
    /// The value must be in SEP-38 Asset Identification Format.
    public let amountFeeAsset:String?

    /// The ID of the quote used when creating this transaction. Should be present if a quote_id
    /// was included in the POST /transactions/deposit/interactive or POST /transactions/withdraw/interactive request.
    /// Clients should be aware that the quote_id may not be present in older implementations.
    public let quoteId:String?

    /// Start date and time of transaction.
    public let startedAt:Date

    /// Completion date and time of transaction.
    public let completedAt:Date?

    /// The date and time of transaction reaching the current status.
    public let updatedAt:Date?

    /// The date and time by when the user action is required. In certain statuses, such as pending_user_transfer_start or incomplete, anchor waits for the user action and
    /// user_action_required_by field should be used to show the time anchors gives for the user to make an action before transaction will automatically be moved into
    /// a different status (such as expired or to be refunded). user_action_required_by should only be specified for statuses where user action is required, and omitted for all other.
    /// Anchor should specify the action waited on using message or more_info_url.
    public let userActionRequiredBy:Date?

    /// Transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal.
    public let stellarTransactionId:String?

    /// ID of transaction on external network that either started the deposit or completed the withdrawal.
    public let externalTransactionId:String?

    /// Human readable explanation of transaction status, if needed.
    public let message:String?


    /// Deprecated. This field is deprecated in favor of the refunds object and the refunded status.
    /// True if the transaction was refunded in full. False if the transaction was partially refunded or not refunded.
    /// For more details about any refunds, see the refunds object.
    public let refunded:Bool?

    /// An object describing any on or off-chain refund associated with this transaction.
    public let refunds:Sep24Refund?

    /// In case of deposit: Sent from address, perhaps BTC, IBAN, or bank account.
    /// In case of withdraw: Stellar address the assets were withdrawn from.
    public let from:String?

    /// In case of deposit: Stellar address the deposited assets were sent to.
    /// In case of withdraw: Sent to address (perhaps BTC, IBAN, or bank account in the case of a withdrawal, Stellar address in the case of a deposit).
    public let to:String?


    /// This is the memo (if any) used to transfer the asset to the to Stellar address. Deposit transactions only.
    public let depositMemo:String?

    /// Type for the deposit_memo. Deposit transactions only.
    public let depositMemoType:String?

    /// ID of the Claimable Balance used to send the asset initially requested. Deposit transactions only.
    public let claimableBalanceId:String?

    /// If this is a withdrawal, this is the anchor's Stellar account that the user transferred (or will transfer) their asset to. Withdrawal transactions only.
    public let withdrawAnchorAccount:String?

    /// Memo used when the user transferred to withdraw_anchor_account.
    /// Assigned null if the withdraw is not ready to receive payment, for example if KYC is not completed. Withdrawal transactions only.
    public let withdrawMemo:String?

    /// Memo type for withdraw_memo. Withdrawal transactions only.
    public let withdrawMemoType:String?

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case status
        case statusEta = "status_eta"
        case kycVerified = "kyc_verified"
        case moreInfoUrl = "more_info_url"
        case amountIn = "amount_in"
        case amountInAsset = "amount_in_asset"
        case amountOut = "amount_out"
        case amountOutAsset = "amount_out_asset"
        case amountFee = "amount_fee"
        case amountFeeAsset = "amount_fee_asset"
        case quoteId = "quote_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
        case userActionRequiredBy = "user_action_required_by"
        case stellarTransactionId = "stellar_transaction_id"
        case externalTransactionId = "external_transaction_id"
        case message
        case refunded
        case refunds
        case from
        case to
        case depositMemo = "deposit_memo"
        case depositMemoType = "deposit_memo_type"
        case withdrawAnchorAccount = "withdraw_anchor_account"
        case claimableBalanceId = "claimable_balance_id"
        case withdrawMemo = "withdraw_memo"
        case withdrawMemoType = "withdraw_memo_type"
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        kind = try values.decode(String.self, forKey: .kind)
        status = try values.decode(String.self, forKey: .status)
        statusEta = try values.decodeIfPresent(Int.self, forKey: .statusEta)
        kycVerified = try values.decodeIfPresent(Bool.self, forKey: .kycVerified)
        moreInfoUrl = try values.decodeIfPresent(String.self, forKey: .moreInfoUrl)
        amountIn = try values.decodeIfPresent(String.self, forKey: .amountIn)
        amountInAsset = try values.decodeIfPresent(String.self, forKey: .amountInAsset)
        amountOut = try values.decodeIfPresent(String.self, forKey: .amountOut)
        amountOutAsset = try values.decodeIfPresent(String.self, forKey: .amountOutAsset)
        amountFee = try values.decodeIfPresent(String.self, forKey: .amountFee)
        amountFeeAsset = try values.decodeIfPresent(String.self, forKey: .amountFeeAsset)
        quoteId = try values.decodeIfPresent(String.self, forKey: .quoteId)
        
        let startedAtStr = try values.decode(String.self, forKey: .startedAt)
        if let startedAtDate = ISO8601DateFormatter.full.date(from: startedAtStr) {
            startedAt = startedAtDate
        } else {
            startedAt = try values.decode(Date.self, forKey: .startedAt)
        }
        
        if let completedAtStr = try values.decodeIfPresent(String.self, forKey: .completedAt),
           let completedAtDate = ISO8601DateFormatter.full.date(from: completedAtStr) {
            completedAt = completedAtDate
        } else {
            completedAt = try values.decodeIfPresent(Date.self, forKey: .completedAt)
        }
        
        if let updatedAtStr = try values.decodeIfPresent(String.self, forKey: .updatedAt),
            let updatedAtDate =  ISO8601DateFormatter.full.date(from: updatedAtStr) {
            updatedAt = updatedAtDate
        } else {
            updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt)
        }
        
        if let userActionRequiredByStr = try values.decodeIfPresent(String.self, forKey: .userActionRequiredBy),
            let userActionRequiredByDate =  ISO8601DateFormatter.full.date(from: userActionRequiredByStr) {
            userActionRequiredBy = userActionRequiredByDate
        } else {
            userActionRequiredBy = try values.decodeIfPresent(Date.self, forKey: .userActionRequiredBy)
        }
        
        stellarTransactionId = try values.decodeIfPresent(String.self, forKey: .stellarTransactionId)
        externalTransactionId = try values.decodeIfPresent(String.self, forKey: .externalTransactionId)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        refunded = try values.decodeIfPresent(Bool.self, forKey: .refunded)
        refunds = try values.decodeIfPresent(Sep24Refund.self, forKey: .refunds)
        from = try values.decodeIfPresent(String.self, forKey: .from)
        to = try values.decodeIfPresent(String.self, forKey: .to)
        depositMemo = try values.decodeIfPresent(String.self, forKey: .depositMemo)
        depositMemoType = try values.decodeIfPresent(String.self, forKey: .depositMemoType)
        claimableBalanceId = try values.decodeIfPresent(String.self, forKey: .claimableBalanceId)
        withdrawAnchorAccount = try values.decodeIfPresent(String.self, forKey: .withdrawAnchorAccount)
        withdrawMemo = try values.decodeIfPresent(String.self, forKey: .withdrawMemo)
        withdrawMemoType = try values.decodeIfPresent(String.self, forKey: .withdrawMemoType)
    }
}

/// Information about refunds associated with a transaction.
///
/// Contains details about the total refund amount, fees, and individual refund payments
/// for transactions that have been partially or fully refunded.
///
/// See also:
/// - [Sep24Transaction] for the parent transaction
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24Refund: Decodable , Sendable {

    /// The total amount refunded to the user, in units of amount_in_asset.
    /// If a full refund was issued, this amount should match amount_in.
    public let amountRefunded:String

    /// The total amount charged in fees for processing all refund payments, in units of amount_in_asset.
    /// The sum of all fee values in the payments object list should equal this value.
    public let amountFee:String

    /// A list of objects containing information on the individual payments made back to the user as refunds.
    public let payments:[Sep24RefundPayment]?

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case amountRefunded = "amount_refunded"
        case amountFee = "amount_fee"
        case payments
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amountRefunded = try values.decode(String.self, forKey: .amountRefunded)
        amountFee = try values.decode(String.self, forKey: .amountFee)
        payments = try values.decodeIfPresent([Sep24RefundPayment].self, forKey: .payments)
    }
}

/// Details of an individual refund payment.
///
/// Represents a single refund payment made back to the user, either on-chain or off-chain.
///
/// See also:
/// - [Sep24Refund] for the parent refund object
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24RefundPayment: Decodable , Sendable {

    /// The payment ID that can be used to identify the refund payment.
    /// This is either a Stellar transaction hash or an off-chain payment identifier,
    /// such as a reference number provided to the user when the refund was initiated.
    /// This id is not guaranteed to be unique.
    public let id:String

    /// Payment type: stellar or external.
    public let idType:String

    /// The amount sent back to the user for the payment identified by id, in units of amount_in_asset.
    public let amount:String

    /// The amount charged as a fee for processing the refund, in units of amount_in_asset.
    public let fee:String

    /// Properties to encode and decode.
    private enum CodingKeys: String, CodingKey {
        case id
        case idType = "id_type"
        case amount
        case fee
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        idType = try values.decode(String.self, forKey: .idType)
        amount = try values.decode(String.self, forKey: .amount)
        fee = try values.decode(String.self, forKey: .fee)
    }
}
