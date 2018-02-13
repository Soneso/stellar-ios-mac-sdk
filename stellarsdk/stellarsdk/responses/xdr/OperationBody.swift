//
//  OperationBody.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum OperationBody: XDRCodable {
    case createAccount (CreateAccountOperation)
    case payment (PaymentOperation)
    case pathPayment (PathPaymentOperation)
    case manageOffer (ManageOfferOperation)
    case createPassiveOffer (CreatePassiveOfferOperation)
    case setOptions (SetOptionsOperation)
    case allowTrust (AllowTrustOperation)
    case changeTrust (ChangeTrustOperation)
    case inflation
    case manageData (ManageDataOperation)
    case accountMerge (PublicKey)
    
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
        case OperationType.allowTrust.rawValue:
            self = .allowTrust(try container.decode(AllowTrustOperation.self))
        case OperationType.changeTrust.rawValue:
            self = .changeTrust(try container.decode(ChangeTrustOperation.self))
        case OperationType.manageData.rawValue:
            self = .manageData(try container.decode(ManageDataOperation.self))
        case OperationType.accountMerge.rawValue:
            self = .accountMerge(try container.decode(PublicKey.self))
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
        case .allowTrust: return OperationType.allowTrust.rawValue
        case .changeTrust: return OperationType.changeTrust.rawValue
        case .inflation: return OperationType.inflation.rawValue
        case .manageData: return OperationType.manageData.rawValue
        case .accountMerge: return OperationType.accountMerge.rawValue
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
        case .allowTrust (let op):
            try container.encode(op)
        case .changeTrust (let op):
            try container.encode(op)
        case .inflation:
            break
        case .manageData (let op):
            try container.encode(op)
        case .accountMerge (let op):
            try container.encode(op)
        }
    }
}
