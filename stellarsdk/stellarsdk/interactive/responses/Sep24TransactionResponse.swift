import Foundation

public struct Sep24TransactionsResponse: Decodable {

    ///Transactions
    public var transactions: [Sep24Transaction]
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case transactions = "transactions"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactions = try values.decode([Sep24Transaction].self, forKey: .transactions)
    }
}

public struct Sep24TransactionResponse: Decodable {

    public var transaction: Sep24Transaction
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case transaction
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transaction = try values.decode(Sep24Transaction.self, forKey: .transaction)
    }
}


public struct Sep24Transaction: Decodable {
    
    /// Unique, anchor-generated id for the deposit/withdrawal
    public var id:String
    
    /// deposit or withdrawal
    public var kind:String
    
    /// Processing status of deposit/withdrawal
    public var status:String
    
    /// (optional) Estimated number of seconds until a status change is expected
    public var statusEta:Int?
    
    /// (optional) True if the anchor has verified the user's KYC information for this transaction.
    public var kycVerified:Bool?
    
    /// (optional)  A URL that is opened by wallets after the interactive flow is complete. It can include banking information for users to start deposits, the status of the transaction, or any other information the user might need to know about the transaction.
    public var moreInfoUrl:String?
    
    /// Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds.
    public var amountIn:String?
    
    /// (optional)  The asset received or to be received by the Anchor. Must be present if the deposit/withdraw was made using non-equivalent assets.
    /// The value must be in SEP-38 Asset Identification Format.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#asset-identification-format
    /// See also the Asset Exchanges section for more information.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#asset-exchanges
    public var amountInAsset:String?
    
    /// Amount sent by anchor to user at end of transaction as a string with up to 7 decimals.
    /// Excludes amount converted to XLM to fund account and any external fees.
    public var amountOut:String
    
    /// (optional) The asset delivered or to be delivered to the user. Must be present if the deposit/withdraw was made using non-equivalent assets.
    /// The value must be in SEP-38 Asset Identification Format.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#asset-identification-format
    /// See also the Asset Exchanges section for more information.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#asset-exchanges
    public var amountOutAsset:String?
    
    /// Amount of fee charged by anchor
    public var amountFee:String
    
    /// (optional) The asset in which fees are calculated in. Must be present if the deposit/withdraw was made using non-equivalent assets.
    /// The value must be in SEP-38 Asset Identification Format.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#asset-identification-format
    /// See also the Asset Exchanges section for more information.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#asset-exchanges
    public var amountFeeAsset:String?
    
    /// (optional) The ID of the quote used when creating this transaction. Should be present if a quote_id
    /// was included in the POST /transactions/deposit/interactive or POST /transactions/withdraw/interactive request.
    /// Clients should be aware that the quote_id may not be present in older implementations.
    public var quoteId:String?
    
    /// start date and time of transaction
    public var startedAt:Date
    
    /// (optional) completion date and time of transaction
    public var completedAt:Date?
    
    /// (optional) The date and time of transaction reaching the current status.
    public var updatedAt:Date?
    
    /// (optional) transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal.
    public var stellarTransactionId:String?
    
    /// (optional) ID of transaction on external network that either started the deposit or completed the withdrawal.
    public var externalTransactionId:String?

    /// (optional) Human readable explanation of transaction status, if needed.
    public var message:String?
    
    
    /// (deprecated, optional) This field is deprecated in favor of the refunds object and the refunded status.
    /// True if the transaction was refunded in full. False if the transaction was partially refunded or not refunded.
    /// For more details about any refunds, see the refunds object.
    public var refunded:Bool?

    /// (optional) An object describing any on or off-chain refund associated with this transaction.
    public var refunds:Sep24Refund?
    
    /// In case of deposit: Sent from address, perhaps BTC, IBAN, or bank account.
    /// In case of withdraw: Stellar address the assets were withdrawn from.
    public var from:String?
    
    /// In case of deposit: Stellar address the deposited assets were sent to.
    /// In case of withdraw: Sent to address (perhaps BTC, IBAN, or bank account in the case of a withdrawal, Stellar address in the case of a deposit).
    public var to:String?
    
    
    //Fields for deposit transactions
    
    /// (optional) This is the memo (if any) used to transfer the asset to the to Stellar address.
    public var depositMemo:String?
    
    /// (optional) Type for the deposit_memo.
    public var depositMemoType:String?

    /// (optional) ID of the Claimable Balance used to send the asset initially requested.
    public var claimableBalanceId:String?
    
    //Fields for withdraw transactions
    
    /// If this is a withdrawal, this is the anchor's Stellar account that the user transferred (or will transfer) their asset to.
    public var withdrawAnchorAccount:String?
    
    /// Memo used when the user transferred to withdraw_anchor_account.
    /// Assigned null if the withdraw is not ready to receive payment, for example if KYC is not completed.
    public var withdrawMemo:String?
    
    /// Memo type for withdraw_memo.
    public var withdrawMemoType:String?
    
    /// Properties to encode and decode
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
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        kind = try values.decode(String.self, forKey: .kind)
        status = try values.decode(String.self, forKey: .status)
        statusEta = try values.decodeIfPresent(Int.self, forKey: .statusEta)
        kycVerified = try values.decodeIfPresent(Bool.self, forKey: .kycVerified)
        moreInfoUrl = try values.decodeIfPresent(String.self, forKey: .moreInfoUrl)
        amountIn = try values.decode(String.self, forKey: .amountIn)
        amountInAsset = try values.decodeIfPresent(String.self, forKey: .amountInAsset)
        amountOut = try values.decode(String.self, forKey: .amountOut)
        amountOutAsset = try values.decodeIfPresent(String.self, forKey: .amountOutAsset)
        amountFee = try values.decode(String.self, forKey: .amountFee)
        amountFeeAsset = try values.decodeIfPresent(String.self, forKey: .amountFeeAsset)
        quoteId = try values.decodeIfPresent(String.self, forKey: .quoteId)
        startedAt = try values.decode(Date.self, forKey: .startedAt)
        completedAt = try values.decodeIfPresent(Date.self, forKey: .completedAt)
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt)
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

public struct Sep24Refund: Decodable {
    
    /// The total amount refunded to the user, in units of amount_in_asset.
    /// If a full refund was issued, this amount should match amount_in.
    public var amountRefunded:String
    
    /// The total amount charged in fees for processing all refund payments, in units of amount_in_asset.
    /// The sum of all fee values in the payments object list should equal this value.
    public var amountFee:String
    
    /// A list of objects containing information on the individual payments made back to the user as refunds.
    public var payments:[Sep24RefundPayment]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amountRefunded = "amount_refunded"
        case amountFee = "amount_fee"
        case payments
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amountRefunded = try values.decode(String.self, forKey: .amountRefunded)
        amountFee = try values.decode(String.self, forKey: .amountFee)
        payments = try values.decodeIfPresent([Sep24RefundPayment].self, forKey: .payments)
    }
}

public struct Sep24RefundPayment: Decodable {
    
    /// The payment ID that can be used to identify the refund payment.
    /// This is either a Stellar transaction hash or an off-chain payment identifier,
    /// such as a reference number provided to the user when the refund was initiated.
    /// This id is not guaranteed to be unique.
    public var id:String
    
    /// stellar or external.
    public var idType:String
    
    /// The amount sent back to the user for the payment identified by id, in units of amount_in_asset.
    public var amount:String
    
    /// The amount charged as a fee for processing the refund, in units of amount_in_asset.
    public var fee:String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
        case idType = "id_type"
        case amount
        case fee
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        idType = try values.decode(String.self, forKey: .idType)
        amount = try values.decode(String.self, forKey: .amount)
        fee = try values.decode(String.self, forKey: .fee)
    }
}
