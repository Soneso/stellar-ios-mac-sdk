//
//  EffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Currently available effect types.
public enum EffectType: Int {
    case accountCreated = 0
    case accountRemoved = 1
    case accountCredited = 2
    case accountDebited = 3
    case accountThresholdsUpdated = 4
    case accountHomeDomainUpdated = 5
    case accountFlagsUpdated = 6
    case accountInflationDestinationUpdated = 7
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

/// Represents an account effect response. Superclass for all other effect response classes.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
public class EffectResponse: NSObject, Decodable {
    
    /// A list of links related to this effect.
    public var links:EffectLinksResponse
    
    /// ID of the effect.
    public var id:String
    
    /// Date of the effect.
    public var createdAt:String
    
    /// A paging token, specifying where the returned records start from.
    public var pagingToken:String
    
    /// Account ID/Public Key of the account the effect belongs to.
    public var account:String
    
    /// Type of the effect as a human readable string.
    public var effectTypeString:String
    
    /// Type of the effect (int) see enum EffectType.
    public var effectType:EffectType
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case account
        case effectTypeString = "type"
        case effectType = "type_i"
        case createdAt = "created_at"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(EffectLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        createdAt = try values.decode(String.self, forKey: .createdAt)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        account = try values.decode(String.self, forKey: .account)
        effectTypeString = try values.decode(String.self, forKey: .effectTypeString)
        let typeIInt = try values.decode(Int.self, forKey: .effectType) as Int
        effectType = EffectType(rawValue: typeIInt)!
    }
}
