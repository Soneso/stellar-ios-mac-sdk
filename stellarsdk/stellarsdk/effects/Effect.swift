//
//  EffectsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

//TODO: Move this to operations when available
enum OperationType: Int {
    case accountCreated = 0
    case payment = 1
    case pathPayment = 2
    case manageOffer = 3
    case createPassiveOffer = 4
    case setOptions = 5
    case changeTrust = 6
    case allowTrust = 7
    case accountMerge = 8
    case inflation = 9
    case manageData = 10
}

public enum EffectType: Int {
    case accountCreated = 0
    case accountRemoved = 1
    case accountCredited = 2
    case accountDebited = 3
    case accountThresholdsUpdated = 4
    case accountHomeDomainUpdated = 5
    case accountFlagsUpdated = 6
    case signerCreated = 10
    case signerRemoved = 11
    case signerUpdated = 12
    case trustlineCreated = 20
    case trustlineRemoved = 21
    case trustlineUpdated = 22
    case trustlineAuthorized = 23
    case trustlineDeauthorized = 24
    case offerCreated = 30
    case offerRemoved = 31
    case offerUpdated = 32
    case tradeEffect = 33
}

public class Effect: NSObject, Codable {
    
    public var links:Links
    public var id:String
    public var pagingToken:String
    public var account:String
    public var effectTypeString:String
    public var effectType:EffectType
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case account
        case effectTypeString = "type"
        case effectType = "type_i"
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(Links.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        account = try values.decode(String.self, forKey: .account)
        effectTypeString = try values.decode(String.self, forKey: .effectTypeString)
        let typeIInt = try values.decode(Int.self, forKey: .effectType) as Int
        effectType = EffectType(rawValue: typeIInt)!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(id, forKey: .id)
        try container.encode(pagingToken, forKey: .pagingToken)
        try container.encode(account, forKey: .account)
        try container.encode(effectTypeString, forKey: .effectTypeString)
        try container.encode(effectType.rawValue, forKey: .effectType)
    }
    
}
