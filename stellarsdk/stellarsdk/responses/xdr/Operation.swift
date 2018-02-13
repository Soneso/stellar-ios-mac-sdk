//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct Operation: XDRCodable {
    public let sourceAccount: PublicKey?
    public let body: Body
    
    init(sourceAccount: PublicKey?, body: Body) {
        self.sourceAccount = sourceAccount
        self.body = body
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(Array<PublicKey>.self).first
        body = try container.decode(Body.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sourceAccount)
        try container.encode(body)
    }
    
    public enum Body: XDRCodable {
        case createAccount (CreateAccountOperation)
        case payment (PaymentOperation)
        case changeTrust (ChangeTrustOperation)
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            let type = try container.decode(Int32.self)
            
            switch type {
                case OperationType.accountCreated.rawValue:
                    self = .createAccount(try container.decode(CreateAccountOperation.self))
                case OperationType.changeTrust.rawValue:
                    self = .changeTrust(try container.decode(ChangeTrustOperation.self))
                case OperationType.payment.rawValue:
                    self = .payment(try container.decode(PaymentOperation.self))
                default:
                    self = .createAccount(try container.decode(CreateAccountOperation.self))
            }
        }
        
        public func type() -> Int32 {
            switch self {
                case .createAccount: return OperationType.accountCreated.rawValue
                case .payment: return OperationType.payment.rawValue
                case .changeTrust: return OperationType.changeTrust.rawValue
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            try container.encode(type())
            
            switch self {
                case .createAccount (let op):
                    try container.encode(op)
                
                case .payment (let op):
                    try container.encode(op)
                
                case .changeTrust (let op):
                    try container.encode(op)
            }
        }
    }
}

public struct CreateAccountOperation: XDRCodable {
    public let destination: PublicKey
    public let balance: Int64
    
    public init(destination: PublicKey, balance: Int64) {
        self.destination = destination
        self.balance = balance
    }
}

public struct PaymentOperation: XDRCodable {
    public let destination: PublicKey
    public let asset: Asset
    public let amount: Int64
    
    init(destination: PublicKey, asset: Asset, amount: Int64) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(destination)
        try container.encode(asset)
        try container.encode(amount)
    }
}

public struct ChangeTrustOperation: XDRCodable {
    public let asset: Asset
    public let limit: Int64 = Int64.max
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        asset = try container.decode(Asset.self)
        _ = try container.decode(Int64.self)
    }
    
    public init(asset: Asset) {
        self.asset = asset
    }
}
