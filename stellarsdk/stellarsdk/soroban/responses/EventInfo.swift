//
//  EventInfo.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Part of the getEvents respopnse
/// See https://soroban.stellar.org/api/methods/getEvents
public class EventInfo: NSObject, Decodable {
    
    /// String-ified sequence number of the ledger.
    public var ledger:String
    
    ///  ISO8601 timestamp of the ledger closing time.
    public var ledgerClosedAt:String
    
    /// ID of the emitting contract.
    public var contractId:String
    
    /// Unique identifier for this event.
    public var id:String
    
    ///  Duplicate of id field, but in the standard place for pagination tokens.
    public var pagingToken:String
    
    /// If true the event was emitted during a successful contract call.
    public var inSuccessfulContractCall:Bool
    
    /// List containing the topic this event was emitted with. [XdrSCVal as base64|]
    public var topic:[String]
    
    /// List containing the topic this event was emitted with
    public var value:EventInfoValue
    
    private enum CodingKeys: String, CodingKey {
        case ledger
        case ledgerClosedAt
        case contractId
        case id
        case pagingToken
        case inSuccessfulContractCall
        case topic
        case value
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ledger = try values.decode(String.self, forKey: .ledger)
        ledgerClosedAt = try values.decode(String.self, forKey: .ledgerClosedAt)
        contractId = try values.decode(String.self, forKey: .contractId)
        id = try values.decode(String.self, forKey: .id)
        inSuccessfulContractCall = try values.decode(Bool.self, forKey: .inSuccessfulContractCall)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        topic = try values.decode([String].self, forKey: .topic)
        value = try values.decode(EventInfoValue.self, forKey: .value)
    }
}

