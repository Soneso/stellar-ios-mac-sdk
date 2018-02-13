//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct Operation: XDRCodable {
    public var sourceAccount: PublicKey?
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
        
        if sourceAccount != nil {
            try container.encode(1)
            try container.encode(sourceAccount)
        }
        else {
            try container.encode(0)
        }
        
        try container.encode(body)
    }
    
    public enum Body: XDRCodable {
        case createAccount (CreateAccountOperation)
        case payment (PaymentOperation)
        case pathPayment (PathPaymentOperation)
        case manageOffer (ManageOfferOperation)
        case createPassiveOffer (CreatePassiveOfferOperation)
        case setOptions (SetOptionsOperation)
        case changeTrust (ChangeTrustOperation)
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            let type = try container.decode(Int32.self)
            
            switch type {
                case OperationType.accountCreated.rawValue:
                    self = .createAccount(try container.decode(CreateAccountOperation.self))
                case OperationType.payment.rawValue:
                    self = .payment(try container.decode(PaymentOperation.self))
                case OperationType.pathPayment.rawValue:
                    self = .pathPayment(try container.decode(PathPaymentOperation.self))
                case OperationType.manageOffer.rawValue:
                    self = .manageOffer(try container.decode(ManageOfferOperation.self))
                case OperationType.createPassiveOffer.rawValue:
                    self = .createPassiveOffer(try container.decode(CreatePassiveOfferOperation.self))
                case OperationType.setOptions.rawValue:
                    self = .setOptions(try container.decode(SetOptionsOperation.self))
                case OperationType.changeTrust.rawValue:
                    self = .changeTrust(try container.decode(ChangeTrustOperation.self))
                default:
                    self = .createAccount(try container.decode(CreateAccountOperation.self))
            }
        }
        
        public func type() -> Int32 {
            switch self {
                case .createAccount: return OperationType.accountCreated.rawValue
                case .payment: return OperationType.payment.rawValue
                case .pathPayment: return OperationType.pathPayment.rawValue
                case .manageOffer: return OperationType.manageOffer.rawValue
                case .createPassiveOffer: return OperationType.createPassiveOffer.rawValue
                case .setOptions: return OperationType.setOptions.rawValue
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
                case .pathPayment (let op):
                    try container.encode(op)
                case .manageOffer (let op):
                    try container.encode(op)
                case .createPassiveOffer (let op):
                    try container.encode(op)
                case .setOptions (let op):
                    try container.encode(op)
                case .changeTrust (let op):
                    try container.encode(op)
            }
        }
    }
}

public struct CreateAccountOperation: XDRCodable {
    public let destination: PublicKey
    public let startingBalance: Int64
    
    public init(destination: PublicKey, balance: Int64) {
        self.destination = destination
        self.startingBalance = balance
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        destination = try container.decode(PublicKey.self)
        startingBalance = try container.decode(Int64.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(destination)
        try container.encode(startingBalance)
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
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        destination = try container.decode(PublicKey.self)
        asset = try container.decode(Asset.self)
        amount = try container.decode(Int64.self)
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(destination)
        try container.encode(asset)
        try container.encode(amount)
    }
}

public struct PathPaymentOperation: XDRCodable {
    public let sendAsset: Asset
    public let sendMax: Int64
    public let destinationID: PublicKey
    public let destinationAsset: Asset
    public let destinationAmount: Int64
    public let path: [Asset]
    
    init(sendAsset: Asset, sendMax: Int64, destinationID: PublicKey, destinationAsset: Asset, destinationAmount:Int64, path:[Asset]) {
        self.sendAsset = sendAsset
        self.sendMax = sendMax
        self.destinationID = destinationID
        self.destinationAsset = destinationAsset
        self.destinationAmount = destinationAmount
        self.path = path
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sendAsset = try container.decode(Asset.self)
        sendMax = try container.decode(Int64.self)
        destinationID = try container.decode(PublicKey.self)
        destinationAsset = try container.decode(Asset.self)
        destinationAmount = try container.decode(Int64.self)
        self.path = try container.decode(Array<Asset>.self)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sendAsset)
        try container.encode(sendMax)
        try container.encode(destinationID)
        try container.encode(destinationAsset)
        try container.encode(destinationAmount)
        try container.encode(path)
    }
}

public struct ManageOfferOperation: XDRCodable {
    public let selling: Asset
    public let buying: Asset
    public let amount: Int64
    public let price: Price
    public let offerID: UInt64
   
    public init(selling: Asset, buying: Asset, amount:Int64, price:Price, offerID:UInt64) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        self.offerID = offerID
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        selling = try container.decode(Asset.self)
        buying = try container.decode(Asset.self)
        amount = try container.decode(Int64.self)
        price = try container.decode(Price.self)
        offerID = try container.decode(UInt64.self)
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(selling)
        try container.encode(buying)
        try container.encode(amount)
        try container.encode(price)
        try container.encode(offerID)
    }
}

public struct CreatePassiveOfferOperation: XDRCodable {
    public let selling: Asset
    public let buying: Asset
    public let amount: Int64
    public let price: Price
    
    public init(selling: Asset, buying: Asset, amount:Int64, price:Price, offerID:UInt64) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        selling = try container.decode(Asset.self)
        buying = try container.decode(Asset.self)
        amount = try container.decode(Int64.self)
        price = try container.decode(Price.self)
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(selling)
        try container.encode(buying)
        try container.encode(amount)
        try container.encode(price)
    }
}

public struct SetOptionsOperation: XDRCodable {
    public var inflationDestination: PublicKey?
    public var clearFlags: UInt32?
    public var setFlags: UInt32?
    public var masterWeight: UInt32?
    public var lowThreshold: UInt32?
    public var medThreshold: UInt32?
    public var highThreshold: UInt32?
    public var homeDomain: String?
    public var signer: Signer?
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        inflationDestination = try container.decode(Array<PublicKey>.self).first
        clearFlags = try container.decode(Array<UInt32>.self).first
        setFlags = try container.decode(Array<UInt32>.self).first
        masterWeight = try container.decode(Array<UInt32>.self).first
        lowThreshold = try container.decode(Array<UInt32>.self).first
        medThreshold = try container.decode(Array<UInt32>.self).first
        highThreshold = try container.decode(Array<UInt32>.self).first
        homeDomain = try container.decode(Array<String>.self).first
        signer = try container.decode(Array<Signer>.self).first
        
    }
    
    public init(inflationDestination: PublicKey?, clearFlags:UInt32?, setFlags:UInt32, masterWeight:UInt32?, lowThreshold:UInt32, medThreshold:UInt32, highThreshold:UInt32?, homeDomain:String?, signer:Signer?) {
        self.inflationDestination = inflationDestination
        self.clearFlags = clearFlags
        self.setFlags = setFlags
        self.masterWeight = masterWeight
        self.lowThreshold = lowThreshold
        self.medThreshold = medThreshold
        self.highThreshold = highThreshold
        self.homeDomain = homeDomain
        self.signer = signer
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(inflationDestination)
        try container.encode(clearFlags)
        try container.encode(setFlags)
        try container.encode(masterWeight)
        try container.encode(lowThreshold)
        try container.encode(medThreshold)
        try container.encode(highThreshold)
        try container.encode(homeDomain)
        try container.encode(signer)
        try container.encode(0)
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

