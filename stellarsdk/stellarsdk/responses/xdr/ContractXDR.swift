//
//  ContractXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCErrorXDR: XDRCodable, Sendable {

    case contract(UInt32)
    case wasmVm
    case context
    case storage
    case object
    case crypto
    case events
    case budget
    case value
    case auth(Int32) //SCErrorCode
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCErrorType(rawValue: discriminant)
        
        switch type {
        case .contract:
            let contractCode = try container.decode(UInt32.self)
            self = .contract(contractCode)
        case .wasmVm:
            self = .wasmVm
        case .context:
            self = .context
        case .storage:
            self = .storage
        case .object:
            self = .object
        case .crypto:
            self = .crypto
        case .events:
            self = .events
        case .budget:
            self = .budget
        case .value:
            self = .value
        case .auth:
            let errCode = try container.decode(Int32.self)
            self = .auth(errCode)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCErrorXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .contract: return SCErrorType.contract.rawValue
        case .wasmVm: return SCErrorType.wasmVm.rawValue
        case .context: return SCErrorType.context.rawValue
        case .storage: return SCErrorType.storage.rawValue
        case .object: return SCErrorType.object.rawValue
        case .crypto: return SCErrorType.crypto.rawValue
        case .events: return SCErrorType.events.rawValue
        case .budget: return SCErrorType.budget.rawValue
        case .value: return SCErrorType.value.rawValue
        case .auth: return SCErrorType.auth.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .contract (let contractCode):
            try container.encode(contractCode)
            break
        case .wasmVm:
            break
        case .context:
            break
        case .storage:
            break
        case .object:
            break
        case .crypto:
            break
        case .events:
            break
        case .budget:
            break
        case .value:
            break
        case .auth (let errCode):
            try container.encode(errCode)
            break
        }
    }
}
