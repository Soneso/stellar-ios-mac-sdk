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
    
    /// (optional) Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds.
    public var amountIn:String?
    
    /// (optional) Amount sent by anchor to user at end of transaction as a string with up to 7 decimals. Excludes amount converted to XLM to fund account and any external fees
    public var amountOut:String?
    
    /// (optional) Amount of fee charged by anchor
    public var amountFee:String?
    
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
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case kind = "kind"
        case status = "status"
        case statusEta = "status_eta"
        case amountIn = "amount_in"
        case amountOut = "amount_out"
        case amountFee = "amount_fee"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case stellarTransactionId = "stellar_transaction_id"
        case externalTransactionId = "external_transaction_id"
        case message = "message"
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
        amountIn = try values.decodeIfPresent(String.self, forKey: .amountIn)
        amountOut = try values.decodeIfPresent(String.self, forKey: .amountOut)
        amountFee = try values.decodeIfPresent(String.self, forKey: .amountFee)
        startedAt = try values.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try values.decodeIfPresent(Date.self, forKey: .completedAt)
        stellarTransactionId = try values.decodeIfPresent(String.self, forKey: .stellarTransactionId)
        externalTransactionId = try values.decodeIfPresent(String.self, forKey: .externalTransactionId)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}
