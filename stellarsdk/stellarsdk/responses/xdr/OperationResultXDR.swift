//
//  OperationResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

enum OperationResultCode: Int {
    case inner = 0
    case badAuth = -1
    case noAccount = -2
}

enum OperationResultXDR: XDRCodable {
    case createAccount(Int, CreateAccountResultXDR)
    case payment(Int, PaymentResultXDR)
    case pathPayment(Int, PathPaymentResultXDR)
    case manageOffer(Int, ManageOfferResultXDR)
    case createPassiveOffer(Int, ManageOfferResultXDR)
    case setOptions(Int, SetOptionsResultXDR)
    case changeTrust(Int, ChangeTrustResultXDR)
    case allowTrust(Int, AllowTrustResultXDR)
    case accountMerge(Int, AccountMergeResultXDR)
    case inflation(Int, InflationResultXDR)
    case manageData(Int, ManageDataResultXDR)
    case empty (Int)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = OperationResultCode(rawValue: try container.decode(Int.self))!
        
        switch code {
        case .inner:
            let type = OperationType(rawValue: try container.decode(Int32.self))!
            switch type {
                case .accountCreated:
                    self = .createAccount(code.rawValue, try container.decode(CreateAccountResultXDR.self))
                case .payment:
                    self = .payment(code.rawValue, try container.decode(PaymentResultXDR.self))
                case .pathPayment:
                    self = .pathPayment(code.rawValue, try container.decode(PathPaymentResultXDR.self))
                case .manageOffer:
                    self = .manageOffer(code.rawValue, try container.decode(ManageOfferResultXDR.self))
                case .createPassiveOffer:
                    self = .createPassiveOffer(code.rawValue, try container.decode(ManageOfferResultXDR.self))
                case .setOptions:
                    self = .setOptions(code.rawValue, try container.decode(SetOptionsResultXDR.self))
                case .changeTrust:
                    self = .changeTrust(code.rawValue, try container.decode(ChangeTrustResultXDR.self))
                case .allowTrust:
                    self = .allowTrust(code.rawValue, try container.decode(AllowTrustResultXDR.self))
                case .accountMerge:
                    self = .accountMerge(code.rawValue, try container.decode(AccountMergeResultXDR.self))
                case .inflation:
                    self = .inflation(code.rawValue, try container.decode(InflationResultXDR.self))
                case .manageData:
                    self = .manageData(code.rawValue, try container.decode(ManageDataResultXDR.self))
            }
        default:
            self = .empty(code.rawValue)
            break
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        switch self {
            case .createAccount(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .payment(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .pathPayment(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .manageOffer(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .createPassiveOffer(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .setOptions(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .changeTrust(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .allowTrust(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .accountMerge(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .inflation(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .manageData(let code, let result):
                try container.encode(code)
                try container.encode(result)
            case .empty (let code):
                try container.encode(code)
                break
        }
    }
}
