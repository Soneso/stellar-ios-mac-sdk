//
//  EventInfo.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation


public class EventInfo: NSObject, Decodable {
    
    public var type:String
    public var ledger:String
    public var ledgerClosedAt:String
    public var contractId:String
    public var id:String
    public var pagingToken:String
    public var topic:[String]
    public var value:EventInfoValue
    
    private enum CodingKeys: String, CodingKey {
        case type
        case ledger
        case ledgerClosedAt
        case contractId
        case id
        case pagingToken
        case topic
        case value
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        ledger = try values.decode(String.self, forKey: .ledger)
        ledgerClosedAt = try values.decode(String.self, forKey: .ledgerClosedAt)
        contractId = try values.decode(String.self, forKey: .contractId)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        topic = try values.decode([String].self, forKey: .topic)
        value = try values.decode(EventInfoValue.self, forKey: .value)
    }
    
}

