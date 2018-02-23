//
//  Ledger.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a ledger response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/ledger.html "Ledger")
public class LedgerResponse: NSObject, Decodable {
    
    /// A list of links related to this ledger.
    public var links:LedgerLinksResponse
    
    /// Unique identifier for this ledger.
    public var id:String
    
    /// Paging token suitable for use as a cursor parameter.
    public var pagingToken:String
    
    /// Hex-encoded SHA-256 hash of the ledger’s XDR-encoded form.
    public var hashXdr:String
    
    /// The hash of the ledger that chronologically came before this one.
    public var previousHashXdr:String?
    
    /// Sequence number of this ledger, suitable for use as the as the :id parameter for url templates that require a ledger number.
    public var sequenceNumber:Int64
    
    /// The number of transactions in this ledger.
    public var transactionCount:Int
    
    /// The number of operations in this ledger.
    public var operationCount:Int
    
    /// An ISO 8601 formatted string of when this ledger was closed.
    public var closedAt:Date
    
    /// The total number of lumens in circulation.
    public var totalCoins:String
    
    /// The sum of all transaction fees (in lumens) since the last inflation operation. They are redistributed during inflation.
    public var feePool:String
    
    /// The fee the network charges per operation in a transaction.
    public var baseFeeInStroops:Int?

    /// The reserve the network uses when calculating an account’s minimum balance.
    public var baseReserveInStroops:Int?
    
    /// The maximum number of transactions validators have agreed to process in a given ledger.
    public var maxTxSetSize:Int
    
    /// The protocol version that the stellar network was running when this ledger was committed.
    public var protocolVersion:Decimal
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case hashXdr = "hash"
        case previousHashXdr = "prev_hash"
        case sequenceNumber = "sequence"
        case transactionCount = "transaction_count"
        case operationCount = "operation_count"
        case closedAt = "closed_at"
        case totalCoins = "total_coins"
        case feePool = "fee_pool"
        case baseFeeInStroops = "base_fee_in_stroops"
        case baseReserveInStroops = "base_reserve_in_stroops"
        case maxTxSetSize = "max_tx_set_size"
        case protocolVersion = "protocol_version"
        
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(LedgerLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        hashXdr = try values.decode(String.self, forKey: .hashXdr)
        previousHashXdr = try values.decodeIfPresent(String.self, forKey: .previousHashXdr)
        sequenceNumber = try values.decode(Int64.self, forKey: .sequenceNumber)
        transactionCount = try values.decode(Int.self, forKey: .transactionCount)
        operationCount = try values.decode(Int.self, forKey: .operationCount)
        closedAt = try values.decode(Date.self, forKey: .closedAt)
        totalCoins = try values.decode(String.self, forKey: .totalCoins)
        feePool = try values.decode(String.self, forKey: .feePool)
        baseFeeInStroops = try values.decodeIfPresent(Int.self, forKey: .baseFeeInStroops)
        baseReserveInStroops = try values.decodeIfPresent(Int.self, forKey: .baseReserveInStroops)
        maxTxSetSize = try values.decode(Int.self, forKey: .maxTxSetSize)
        protocolVersion = try values.decode(Decimal.self, forKey: .protocolVersion)
    }
}
