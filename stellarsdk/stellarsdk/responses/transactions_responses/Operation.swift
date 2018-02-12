//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct Operation: XDRCodable {
    let sourceAccount: PublicKey?
    let body: Body
    
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
    
    enum Body: XDRCodable {
        case createAccount (CreateAccountOperation)
        case payment (PaymentOperation)
        case changeTrust (ChangeTrustOperation)
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            let discriminant = try container.decode(Int32.self)
            
            switch discriminant {
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
        
        private func discriminant() -> Int32 {
            switch self {
            case .createAccount: return OperationType.accountCreated.rawValue
            case .payment: return OperationType.payment.rawValue
            case .changeTrust: return OperationType.changeTrust.rawValue
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            try container.encode(discriminant())
            
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

struct CreateAccountOperation: XDRCodable {
    let destination: PublicKey
    let balance: Int64
    
    init(destination: PublicKey, balance: Int64) {
        self.destination = destination
        self.balance = balance
    }
}

struct PaymentOperation: XDRCodable {
    let destination: PublicKey
    let asset: Asset
    let amount: Int64
    
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

struct ChangeTrustOperation: XDRCodable {
    let asset: Asset
    let limit: Int64 = Int64.max
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        asset = try container.decode(Asset.self)
        _ = try container.decode(Int64.self)
    }
    
    init(asset: Asset) {
        self.asset = asset
    }
}
