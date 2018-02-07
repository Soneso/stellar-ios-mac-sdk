//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum OperationType: Int {
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

public class Operation: NSObject, Codable {

    public var links:Links
    public var id:String
    public var pagingToken:String
    public var sourceAccount:String
    public var operationTypeString:String
    public var operationType:OperationType
    public var createdAt:Date
    public var transactionHash:String
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case sourceAccount = "source_account"
        case operationTypeString = "type"
        case operationType = "type_i"
        case createdAt = "created_at"
        case transactionHash = "transaction_hash"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(Links.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        sourceAccount = try values.decode(String.self, forKey: .sourceAccount)
        operationTypeString = try values.decode(String.self, forKey: .operationTypeString)
        let typeIInt = try values.decode(Int.self, forKey: .operationType) as Int
        operationType = OperationType(rawValue: typeIInt)!
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(id, forKey: .id)
        try container.encode(pagingToken, forKey: .pagingToken)
        try container.encode(sourceAccount, forKey: .sourceAccount)
        try container.encode(operationTypeString, forKey: .operationTypeString)
        try container.encode(operationType.rawValue, forKey: .operationType)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(transactionHash, forKey: .transactionHash)
    }
    
}
