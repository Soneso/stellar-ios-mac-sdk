//
//  AnchorTransactionsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AnchorTransactionKind: String {
    case deposit = "deposit"
    case withdrawal = "withdrawal"
}

public enum AnchorTransactionStatus: String {
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
}

public struct AnchorTransactionsResponse: Decodable {

    ///Transactions
    public var transactions: [AnchorTransaction]
    
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

public struct AnchorTransaction: Decodable {
    
    /// Unique, anchor-generated id for the deposit/withdrawal
    public var id:String
    
    /// deposit or withdrawal
    public var kind:AnchorTransactionKind
    
    /// Processing status of deposit/withdrawal
    public var status:AnchorTransactionStatus
    
    /// (optional) Estimated number of seconds until a status change is expected
    public var statusEta:Int?
    
    /// (optional) A URL the user can visit if they want more information about their account / status.
    public var moreInfoUrl:String?
    
    /// (optional) Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds.
    public var amountIn:String?
    
    /// (optional) Amount sent by anchor to user at end of transaction as a string with up to 7 decimals. Excludes amount converted to XLM to fund account and any external fees
    public var amountOut:String?
    
    /// (optional) Amount of fee charged by anchor
    public var amountFee:String?
    
    /// (optional) Sent from address (perhaps BTC, IBAN, or bank account in the case of a deposit, Stellar address in the case of a withdrawal).
    public var from:String?
    
    /// (optional) Sent to address (perhaps BTC, IBAN, or bank account in the case of a withdrawal, Stellar address in the case of a deposit).
    public var to:String?
    
    /// (optional) Extra information for the external account involved. It could be a bank routing number, BIC, or store number for example.
    public var externalExtra:String?
    
    /// (optional) Text version of external_extra. This is the name of the bank or store.
    public var externalExtraText:String?
    
    /// (optional) If this is a deposit, this is the memo (if any) used to transfer the asset to the to Stellar address
    public var depositMemo:String?
    
    /// (optional) Type for the deposit_memo.
    public var depositMemoType:String?
    
    /// (optional) If this is a withdrawal, this is the anchor's Stellar account that the user transferred (or will transfer) their issued asset to.
    public var withdrawAnchorAccount:String?
    
    /// (optional) Memo used when the user transferred to withdraw_anchor_account.
    public var withdrawMemo:String?
    
    /// (optional) Memo type for withdraw_memo.
    public var withdrawMemoType:String?
    
    /// (optional) start date and time of transaction
    public var startedAt:Date?
    
    /// (optional) completion date and time of transaction
    public var completedAt:Date?
    
    /// (optional) transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal
    public var stellarTransactionId:String?
    
    /// (optional) ID of transaction on external network that either started the deposit or completed the withdrawal
    public var externalTransactionId:String?
    
    /// (optional) Human readable explanation of transaction status, if needed.
    public var message:String?
    
    /// (optional) Should be true if the transaction was refunded. Not including this field means the transaction was not refunded.
    public var refunded:Bool?
    
    /// (optional) A human-readable message indicating any errors that require updated information from the user.
    public var requiredInfoMessage:String?
    
    /// (optional) A set of fields that require update from the user described in the same format as /info. This field is only relevant when status is pending_transaction_info_update
    public var requiredInfoUpdates:[String:AnchorField]?
    
    /// (optional) ID of the Claimable Balance used to send the asset initially requested. Only relevant for deposit transactions.
    public var claimableBalanceId:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case status
        case statusEta = "status_eta"
        case moreInfoUrl = "more_info_url"
        case amountIn = "amount_in"
        case amountOut = "amount_out"
        case amountFee = "amount_fee"
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
        case completedAt = "completed_at"
        case stellarTransactionId = "stellar_transaction_id"
        case externalTransactionId = "external_transaction_id"
        case message
        case refunded
        case requiredInfoMessage = "required_info_message"
        case requiredInfoUpdates = "required_info_updates"
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
        amountOut = try values.decodeIfPresent(String.self, forKey: .amountOut)
        amountFee = try values.decodeIfPresent(String.self, forKey: .amountFee)
        from = try values.decodeIfPresent(String.self, forKey: .from)
        to = try values.decodeIfPresent(String.self, forKey: .to)
        externalExtra = try values.decodeIfPresent(String.self, forKey: .externalExtra)
        externalExtraText = try values.decodeIfPresent(String.self, forKey: .externalExtraText)
        depositMemo = try values.decodeIfPresent(String.self, forKey: .depositMemo)
        depositMemoType = try values.decodeIfPresent(String.self, forKey: .depositMemoType)
        withdrawAnchorAccount = try values.decodeIfPresent(String.self, forKey: .withdrawAnchorAccount)
        withdrawMemo = try values.decodeIfPresent(String.self, forKey: .withdrawMemo)
        withdrawMemoType = try values.decodeIfPresent(String.self, forKey: .withdrawMemoType)
        startedAt = try values.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try values.decodeIfPresent(Date.self, forKey: .completedAt)
        stellarTransactionId = try values.decodeIfPresent(String.self, forKey: .stellarTransactionId)
        externalTransactionId = try values.decodeIfPresent(String.self, forKey: .externalTransactionId)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        refunded = try values.decodeIfPresent(Bool.self, forKey: .refunded)
        requiredInfoMessage = try values.decodeIfPresent(String.self, forKey: .requiredInfoMessage)
        requiredInfoUpdates = try values.decodeIfPresent([String:AnchorField].self, forKey: .requiredInfoUpdates)
        claimableBalanceId = try values.decodeIfPresent(String.self, forKey: .claimableBalanceId)
    }
}
