//
//  OperationResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

enum OperationResultCode: Int {
    case inner = 0
    case badAuth = -1
    case noAccount = -2
}

enum OperationResultXDR: XDRCodable {
    case createAccount(CreateAccountResultXDR)
    case payment(PaymentResultXDR)
    case pathPayment(PathPaymentResultXDR)
    case manageOffer(ManageOfferResultXDR)
    case createPassiveOffer(ManageOfferResultXDR)
    case setOptions(SetOptionsResultXDR)
    case changeTrust(ChangeTrustResultXDR)
    case allowTrust(AllowTrustResultXDR)
    case accountMerge(AccountMergeResultXDR)
    case inflation(InflationResultXDR)
    case manageData(ManageDataResultXDR)
    case empty
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = OperationResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
        case .inner:
            let type = OperationType(rawValue: try container.decode(Int32.self))!
            switch type {
            case .accountCreated:
                self = .createAccount(try container.decode(CreateAccountResultXDR.self))
            case .payment:
                self = .payment(try container.decode(PaymentResultXDR.self))
            case .pathPayment:
                self = .pathPayment(try container.decode(PathPaymentResultXDR.self))
            case .manageOffer:
                self = .manageOffer(try container.decode(ManageOfferResultXDR.self))
            case .createPassiveOffer:
                self = .createPassiveOffer(try container.decode(ManageOfferResultXDR.self))
            case .setOptions:
                self = .setOptions(try container.decode(SetOptionsResultXDR.self))
            case .changeTrust:
                self = .changeTrust(try container.decode(ChangeTrustResultXDR.self))
            case .allowTrust:
                self = .allowTrust(try container.decode(AllowTrustResultXDR.self))
            case .accountMerge:
                self = .accountMerge(try container.decode(AccountMergeResultXDR.self))
            case .inflation:
                self = .inflation(try container.decode(InflationResultXDR.self))
            case .manageData:
                self = .manageData(try container.decode(ManageDataResultXDR.self))
            }
        default:
            self = .empty
            break
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        switch self {
        case .createAccount(let result):
            try container.encode(result)
        case .payment(let result):
            try container.encode(result)
        case .pathPayment(let result):
            try container.encode(result)
        case .manageOffer(let result):
            try container.encode(result)
        case .createPassiveOffer(let result):
            try container.encode(result)
        case .setOptions(let result):
            try container.encode(result)
        case .changeTrust(let result):
            try container.encode(result)
        case .allowTrust(let result):
            try container.encode(result)
        case .accountMerge(let result):
            try container.encode(result)
        case .inflation(let result):
            try container.encode(result)
        case .manageData(let result):
            try container.encode(result)
        case .empty:
            break
        }
        
    }
    
}
