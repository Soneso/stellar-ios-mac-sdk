//
//  EventInfo.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Part of the getEvents respopnse
/// See https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
public class EventInfo: NSObject, Decodable {
    
    /// The type of event emission. Possible values: contract, diagnostic,  system
    public var type:String
    
    /// Sequence number of the ledger in which this event was emitted.
    public var ledger:Int
    
    ///  ISO8601 timestamp of the ledger closing time.
    public var ledgerClosedAt:String
    
    /// StrKey representation of the contract address that emitted this event.
    public var contractId:String
    
    /// Unique identifier for this event.
    public var id:String
    
    @available(*, deprecated, message: "Deprecated for protocol version >= 23. If true the event was emitted during a successful contract call.")
    public var inSuccessfulContractCall:Bool?
    
    /// List containing the topic this event was emitted with. [XdrSCVal as base64|]
    public var topic:[String]
    
    /// The emitted body value of the event (serialized in a base64 string - XdrSCVal).
    public var value:String
    
    /// The emitted body value of the event as XdrSCVal
    public var valueXdr:SCValXDR
    
    /// The transaction which triggered this event.
    public var txHash:String
    
    /// The operation at which an event occurred. Only avalable for protocol version >= 23
    public var opIndex:Int?
    
    /// The transaction at which an event occurred. Only avalable for protocol version >= 23
    public var txIndex:Int?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case ledger
        case ledgerClosedAt
        case contractId
        case id
        case inSuccessfulContractCall
        case topic
        case value
        case txHash
        case opIndex
        case txIndex
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        ledger = try values.decode(Int.self, forKey: .ledger)
        ledgerClosedAt = try values.decode(String.self, forKey: .ledgerClosedAt)
        contractId = try values.decode(String.self, forKey: .contractId)
        id = try values.decode(String.self, forKey: .id)
        inSuccessfulContractCall = try values.decodeIfPresent(Bool.self, forKey: .inSuccessfulContractCall)
        topic = try values.decode([String].self, forKey: .topic)
        value = try values.decode(String.self, forKey: .value)
        valueXdr = try SCValXDR.fromXdr(base64: value)
        txHash = try values.decode(String.self, forKey: .txHash)
        opIndex = try values.decodeIfPresent(Int.self, forKey: .opIndex)
        txIndex = try values.decodeIfPresent(Int.self, forKey: .txIndex)
    }
}

