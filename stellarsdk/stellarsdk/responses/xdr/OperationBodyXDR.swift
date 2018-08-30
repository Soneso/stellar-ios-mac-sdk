 //
//  OperationBodyXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum OperationBodyXDR: XDRCodable {
    case createAccount (CreateAccountOperationXDR)
    case payment (PaymentOperationXDR)
    case pathPayment (PathPaymentOperationXDR)
    case manageOffer (ManageOfferOperationXDR)
    case createPassiveOffer (CreatePassiveOfferOperationXDR)
    case setOptions (SetOptionsOperationXDR)
    case allowTrust (AllowTrustOperationXDR)
    case changeTrust (ChangeTrustOperationXDR)
    case inflation
    case manageData (ManageDataOperationXDR)
    case accountMerge (PublicKey)
    case bumpSequence (BumpSequenceOperationXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case OperationType.accountCreated.rawValue:
                self = .createAccount(try container.decode(CreateAccountOperationXDR.self))
            case OperationType.payment.rawValue:
                self = .payment(try container.decode(PaymentOperationXDR.self))
            case OperationType.pathPayment.rawValue:
                self = .pathPayment(try container.decode(PathPaymentOperationXDR.self))
            case OperationType.manageOffer.rawValue:
                self = .manageOffer(try container.decode(ManageOfferOperationXDR.self))
            case OperationType.createPassiveOffer.rawValue:
                self = .createPassiveOffer(try container.decode(CreatePassiveOfferOperationXDR.self))
            case OperationType.setOptions.rawValue:
                self = .setOptions(try container.decode(SetOptionsOperationXDR.self))
            case OperationType.allowTrust.rawValue:
                self = .allowTrust(try container.decode(AllowTrustOperationXDR.self))
            case OperationType.changeTrust.rawValue:
                self = .changeTrust(try container.decode(ChangeTrustOperationXDR.self))
            case OperationType.inflation.rawValue:
                self = .inflation
            case OperationType.manageData.rawValue:
                self = .manageData(try container.decode(ManageDataOperationXDR.self))
            case OperationType.accountMerge.rawValue:
                self = .accountMerge(try container.decode(PublicKey.self))
            case OperationType.bumpSequence.rawValue:
                self = .bumpSequence(try container.decode(BumpSequenceOperationXDR.self))
            default:
                throw StellarSDKError.xdrDecodingError(message: "Could not decode operation")
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
            case .bumpSequence: return OperationType.bumpSequence.rawValue
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
        case .bumpSequence (let op):
            try container.encode(op)
        }
    }
}
