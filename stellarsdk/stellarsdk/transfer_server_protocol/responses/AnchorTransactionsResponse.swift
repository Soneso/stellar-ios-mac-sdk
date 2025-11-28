//
//  AnchorTransactionsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// The type of transaction.
///
/// Indicates whether the transaction is a deposit, withdrawal, or an exchange variant.
///
/// See [SEP-6 Transaction](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public enum AnchorTransactionKind: String, Sendable {
    /// Standard deposit operation without asset conversion.
    case deposit = "deposit"
    /// Deposit operation with cross-asset conversion using SEP-38.
    case depositExchange = "deposit-exchange"
    /// Standard withdrawal operation without asset conversion.
    case withdrawal = "withdrawal"
    /// Withdrawal operation with cross-asset conversion using SEP-38.
    case withdrawalExchange = "withdrawal-exchange"
}

/// The processing status of a deposit or withdrawal transaction.
///
/// These statuses track the lifecycle of a transaction from initiation through completion,
/// including various pending states that require action from different parties.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public enum AnchorTransactionStatus: String, Sendable {
    /// deposit/withdrawal fully completed
    case completed = "completed"
    /// deposit/withdrawal has been submitted to external network, but is not yet confirmed. This is the status when waiting on Bitcoin or other external crypto network to complete a transaction, or when waiting on a bank transfer.
    case pendingExternal = "pending_external"
    /// deposit/withdrawal is being processed internally by anchor
    case pendingAnchor = "pending_anchor"
    /// deposit/withdrawal operation has been submitted to Stellar network, but is not yet confirmed
    case pendingStellar = "pending_stellar"
    /// the user must add a trust-line for the asset for the deposit to complete
    case pendingTrust = "pending_trust"
    /// the user must take additional action before the deposit / withdrawal can complete
    case pendingUser = "pending_user"
    /// the user has not yet initiated their transfer to the anchor. This is the necessary first step in any deposit or withdrawal flow.
    case pendingUserTransferStart = "pending_user_transfer_start"
    ///  means the Stellar payment has been successfully received by the anchor and the off-chain funds are available for the customer to pick up. Only used for withdrawal transactions.
    case pendingUserTransferComplete = "pending_user_transfer_complete"
    /// certain pieces of information need to be updated by the user.
    case pendingCustomerInfoUpdate = "pending_customer_info_update"
    /// certain pieces of information need to be updated by the user.
    case pendingTransactionInfoUpdate = "pending_transaction_info_update"
    /// there is not yet enough information for this transaction to be initiated. Perhaps the user has not yet entered necessary info in an interactive flow.
    case incomplete = "incomplete"
    /// could not complete deposit because no satisfactory asset/XLM market was available to create the account
    case noMarket = "no_market"
    /// deposit/withdrawal size less than min_amount
    case tooSmall = "too_small"
    /// deposit/withdrawal size exceeded max_amount
    case tooLarge = "too_large"
    /// catch-all for any error not enumerated above
    case error = "error"
    /// the deposit/withdrawal is fully refunded.
    case refunded = "refunded"
    /// the transaction has expired and is no longer valid. Normally this is due to the transaction_expiration_date being reached.
    case expired = "expired"
}

/// Response returned when requesting transaction history.
///
/// This response is returned by GET /transactions requests in SEP-6 and contains a list
/// of transactions for the authenticated user.
///
/// See [SEP-6 Transaction History](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct AnchorTransactionsResponse: Decodable , Sendable {

    /// List of transactions
    public let transactions: [AnchorTransaction]
    
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
        transactions = try values.decode([AnchorTransaction].self, forKey: .transactions)
    }
}

/// Response returned when requesting a single transaction.
///
/// This response is returned by GET /transaction requests in SEP-6 and contains details
/// about a specific transaction.
///
/// See [SEP-6 Single Historical Transaction](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#single-historical-transaction)
public struct AnchorTransactionResponse: Decodable , Sendable {

    /// Transaction details
    public let transaction: AnchorTransaction
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case transaction = "transaction"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transaction = try values.decode(AnchorTransaction.self, forKey: .transaction)
    }
}

/// Details about a specific deposit or withdrawal transaction.
///
/// Contains comprehensive information about a transaction including its status, amounts,
/// fees, and timestamps. This structure is used in both transaction history and single
/// transaction responses.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct AnchorTransaction: Decodable , Sendable {

    /// Unique, anchor-generated id for the deposit/withdrawal
    public let id:String
    
    /// deposit, deposit-exchange, withdrawal or withdrawal-exchange.
    public let kind:AnchorTransactionKind
    
    /// Processing status of deposit/withdrawal
    public let status:AnchorTransactionStatus
    
    /// (optional) Estimated number of seconds until a status change is expected.
    public let statusEta:Int?
    
    /// (optional) A URL the user can visit if they want more information about their account / status.
    public let moreInfoUrl:String?
    
    /// (optional) Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds. Should be equals to quote.sell_asset if a quote_id was used.
    public let amountIn:String?
    
    /// (optional) The asset received or to be received by the Anchor. Must be present if the deposit/withdraw was made using quotes. The value must be in SEP-38 Asset Identification Format.
    public let amountInAsset:String?
    
    /// (optional) Amount sent by anchor to user at end of transaction as a string with up to 7 decimals. Excludes amount converted to XLM to fund account and any external fees. Should be equals to quote.buy_asset if a quote_id was used.
    public let amountOut:String?
    
    /// (optional) The asset delivered or to be delivered to the user. Must be present if the deposit/withdraw was made using quotes. The value must be in SEP-38 Asset Identification Format.
    public let amountOutAsset:String?
    
    /// (deprecated, optional) Amount of fee charged by anchor. Should be equals to quote.fee.total if a quote_id was used.
    public let amountFee:String?
    
    ///(deprecated, optional) The asset in which fees are calculated in. Must be present if the deposit/withdraw was made using quotes. The value must be in SEP-38 Asset Identification Format. Should be equals to quote.fee.asset if a quote_id was used.
    public let amountFeeAsset:String?
    
    /// Description of fee charged by the anchor.  If quote_id is present, it should match the referenced quote's fee object.
    public let feeDetails:FeeDetails?
    
    /// (optional) The ID of the quote used to create this transaction. Should be present if a quote_id was included in the POST /transactions request. Clients should be aware though that the quote_id may not be present in older implementations.
    public let quoteId:String?
    
    /// (optional) Sent from address (perhaps BTC, IBAN, or bank account in the case of a deposit, Stellar address in the case of a withdrawal).
    public let from:String?
    
    /// (optional) Sent to address (perhaps BTC, IBAN, or bank account in the case of a withdrawal, Stellar address in the case of a deposit).
    public let to:String?
    
    /// (optional) Extra information for the external account involved. It could be a bank routing number, BIC, or store number for example.
    public let externalExtra:String?
    
    /// (optional) Text version of external_extra. This is the name of the bank or store.
    public let externalExtraText:String?
    
    /// (optional) If this is a deposit, this is the memo (if any) used to transfer the asset to the to Stellar address
    public let depositMemo:String?
    
    /// (optional) Type for the deposit_memo.
    public let depositMemoType:String?
    
    /// (optional) If this is a withdrawal, this is the anchor's Stellar account that the user transferred (or will transfer) their issued asset to.
    public let withdrawAnchorAccount:String?
    
    /// (optional) Memo used when the user transferred to withdraw_anchor_account.
    public let withdrawMemo:String?
    
    /// (optional) Memo type for withdraw_memo.
    public let withdrawMemoType:String?
    
    /// (optional) start date and time of transaction
    public let startedAt:Date?
    
    /// (optional) The date and time of transaction reaching the current status.
    public let updatedAt:Date?
    
    /// (optional) completion date and time of transaction
    public let completedAt:Date?
    
    /// (optional) The date and time by when the user action is required. In certain statuses, such as pending_user_transfer_start or incomplete, anchor waits for the user action and
    /// user_action_required_by field should be used to show the time anchors gives for the user to make an action before transaction will automatically be moved into
    /// a different status (such as expired or to be refunded). user_action_required_by should only be specified for statuses where user action is required, and omitted for all other.
    /// Anchor should specify the action waited on using message or more_info_url.
    public let userActionRequiredBy:Date?
    
    /// (optional) transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal
    public let stellarTransactionId:String?
    
    /// (optional) ID of transaction on external network that either started the deposit or completed the withdrawal
    public let externalTransactionId:String?
    
    /// (optional) Human readable explanation of transaction status, if needed.
    public let message:String?
    
    /// (deprecated, optional) This field is deprecated in favor of the refunds object. True if the transaction was refunded in full. False if the transaction was partially refunded or not refunded. For more details about any refunds, see the refunds object.
    public let refunded:Bool?
    
    /// (optional) An object describing any on or off-chain refund associated with this transaction.
    public let refunds:Refunds?
    
    /// (optional) A human-readable message indicating any errors that require updated information from the user.
    public let requiredInfoMessage:String?
    
    /// (optional) A set of fields that require update from the user described in the same format as /info. This field is only relevant when status is pending_transaction_info_update
    public let requiredInfoUpdates:RequiredInfoUpdates?
    
    /// (optional) JSON object containing the SEP-9 financial account fields that describe how to complete the off-chain deposit in the same format as the /deposit response. This field should be present if the instructions were provided in the /deposit response or if it could not have been previously provided synchronously. This field should only be present once the status becomes pending_user_transfer_start, not while the transaction has any statuses that precede it such as incomplete, pending_anchor, or pending_customer_info_update.
    public let instructions:[String:DepositInstruction]?
    
    /// (optional) ID of the Claimable Balance used to send the asset initially requested. Only relevant for deposit transactions.
    public let claimableBalanceId:String?
        
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case status
        case statusEta = "status_eta"
        case moreInfoUrl = "more_info_url"
        case amountIn = "amount_in"
        case amountInAsset = "amount_in_asset"
        case amountOut = "amount_out"
        case amountOutAsset = "amount_out_asset"
        case amountFee = "amount_fee"
        case amountFeeAsset = "amount_fee_asset"
        case feeDetails = "fee_details"
        case quoteId = "quote_id"
        case from
        case to
        case externalExtra = "external_extra"
        case externalExtraText = "external_extra_text"
        case depositMemo = "deposit_memo"
        case depositMemoType = "deposit_memo_type"
        case withdrawAnchorAccount = "withdraw_anchor_account"
        case withdrawMemo = "withdraw_memo"
        case withdrawMemoType = "withdraw_memo_type"
        case startedAt = "started_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case userActionRequiredBy = "user_action_required_by"
        case stellarTransactionId = "stellar_transaction_id"
        case externalTransactionId = "external_transaction_id"
        case message
        case refunded
        case refunds
        case requiredInfoMessage = "required_info_message"
        case requiredInfoUpdates = "required_info_updates"
        case instructions
        case claimableBalanceId = "claimable_balance_id"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        kind = AnchorTransactionKind(rawValue:try values.decode(String.self, forKey: .kind))!
        status = AnchorTransactionStatus(rawValue: try values.decode(String.self, forKey: .status))!
        statusEta = try values.decodeIfPresent(Int.self, forKey: .statusEta)
        moreInfoUrl = try values.decodeIfPresent(String.self, forKey: .moreInfoUrl)
        amountIn = try values.decodeIfPresent(String.self, forKey: .amountIn)
        amountInAsset = try values.decodeIfPresent(String.self, forKey: .amountInAsset)
        amountOut = try values.decodeIfPresent(String.self, forKey: .amountOut)
        amountOutAsset = try values.decodeIfPresent(String.self, forKey: .amountOutAsset)
        amountFee = try values.decodeIfPresent(String.self, forKey: .amountFee)
        amountFeeAsset = try values.decodeIfPresent(String.self, forKey: .amountFeeAsset)
        feeDetails = try values.decodeIfPresent(FeeDetails.self, forKey: .feeDetails)
        quoteId = try values.decodeIfPresent(String.self, forKey: .quoteId)
        from = try values.decodeIfPresent(String.self, forKey: .from)
        to = try values.decodeIfPresent(String.self, forKey: .to)
        externalExtra = try values.decodeIfPresent(String.self, forKey: .externalExtra)
        externalExtraText = try values.decodeIfPresent(String.self, forKey: .externalExtraText)
        depositMemo = try values.decodeIfPresent(String.self, forKey: .depositMemo)
        depositMemoType = try values.decodeIfPresent(String.self, forKey: .depositMemoType)
        withdrawAnchorAccount = try values.decodeIfPresent(String.self, forKey: .withdrawAnchorAccount)
        withdrawMemo = try values.decodeIfPresent(String.self, forKey: .withdrawMemo)
        withdrawMemoType = try values.decodeIfPresent(String.self, forKey: .withdrawMemoType)
        
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
        refunds = try values.decodeIfPresent(Refunds.self, forKey: .refunds)
        requiredInfoMessage = try values.decodeIfPresent(String.self, forKey: .requiredInfoMessage)
        requiredInfoUpdates = try values.decodeIfPresent(RequiredInfoUpdates.self, forKey: .requiredInfoUpdates)
        instructions = try values.decodeIfPresent([String:DepositInstruction].self, forKey: .instructions)
        claimableBalanceId = try values.decodeIfPresent(String.self, forKey: .claimableBalanceId)
    }
}

/// Information about fields that need to be updated for a transaction.
///
/// Returned when transaction status is pending_transaction_info_update, indicating
/// additional information is required to proceed.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct RequiredInfoUpdates: Decodable , Sendable {

    /// Fields that require updates, keyed by field name.
    public let fields: [String:AnchorField]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case fields = "transaction"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fields = try values.decodeIfPresent([String:AnchorField].self, forKey: .fields)
    }
}

/// Detailed breakdown of fees charged for a transaction.
///
/// Provides a comprehensive view of all fees applied, including the total fee amount,
/// the asset in which fees are charged, and optional itemized details.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct FeeDetails: Decodable , Sendable {

    /// The total amount of fee applied.
    public let total:String
    
    /// The asset in which the fee is applied, represented through the Asset Identification Format.
    public let asset:String
    
    /// (optional) An array of objects detailing the fees that were used to
    /// calculate the conversion price. This can be used to datail the price
    /// components for the end-user.
    public let details:[FeeDetailsDetails]?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case total
        case asset
        case details
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        total = try values.decode(String.self, forKey: .total)
        asset = try values.decode(String.self, forKey: .asset)
        details = try values.decodeIfPresent([FeeDetailsDetails].self, forKey: .details)
    }
}

/// Individual fee component in the fee breakdown.
///
/// Provides details about a specific fee component, allowing anchors to show
/// itemized pricing to users.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct FeeDetailsDetails: Decodable , Sendable {

    /// The name of the fee, for example ACH fee, Brazilian conciliation fee, Service fee, etc.
    public let name:String
    
    /// The amount of asset applied. If fee_details.details is provided,
    /// sum(fee_details.details.amount) should be equals fee_details.total.
    public let amount:String
    
    /// (optional) A text describing the fee.
    public let description:String?
    

    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
        case amount
        case description
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        amount = try values.decode(String.self, forKey: .amount)
        description = try values.decodeIfPresent(String.self, forKey: .description)
    }
}

/// Information about refunds associated with a transaction.
///
/// Describes any on or off-chain refunds that have been issued for the transaction,
/// including the total refunded amount and individual refund payments.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct Refunds: Decodable , Sendable {

    /// The total amount refunded to the user, in units of amount_in_asset. If a full refund was issued, this amount should match amount_in.
    public let amountRefunded:String
    
    /// The total amount charged in fees for processing all refund payments, in units of amount_in_asset. The sum of all fee values in the payments object list should equal this value.
    public let amountFee:String
    
    /// A list of objects containing information on the individual payments made back to the user as refunds.
    public let payments:[RefundPayment]?
    
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
        payments = try values.decodeIfPresent([RefundPayment].self, forKey: .payments)
    }
}

/// Details about an individual refund payment.
///
/// Represents a single refund payment that was made back to the user, either on-chain
/// via Stellar or off-chain through an external payment system.
///
/// See [SEP-6 Transaction Object](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)
public struct RefundPayment: Decodable , Sendable {

    /// The payment ID that can be used to identify the refund payment.
    /// This is either a Stellar transaction hash or an off-chain payment identifier,
    /// such as a reference number provided to the user when the refund was initiated.
    /// This id is not guaranteed to be unique.
    public let id:String
    
    /// stellar or external.
    public let idType:String
    
    /// The amount sent back to the user for the payment identified by id, in units of amount_in_asset.
    public let amount:String
    
    /// The amount charged as a fee for processing the refund, in units of amount_in_asset.
    public let fee:String
    
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
