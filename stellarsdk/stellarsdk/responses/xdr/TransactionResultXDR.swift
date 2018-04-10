//
//  TransactionResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

public enum TransactionResultCode: Int32 {
    case success = 0 // all operations succeeded
    case failed = -1 // one of the operations failed (none were applied)
    case tooEarly = -2 // ledger closeTime before minTime
    case tooLate = -3  // ledger closeTime after maxTime
    case missingOperation = -4 // no operation was specified
    case badSeq = -5 // sequence number does not match source account
    case badAuth = -6 // too few valid signatures / wrong network
    case insufficientBalance = -7 // fee would bring account below reserve
    case noAccount = -8 // source account not found
    case insufficientFee = -9 // fee is too small
    case badAuthExtra = -10 // unused signatures attached to transaction
    case internalError = -11 // an unknown error occured
}

public enum TransactionResultBodyXDR: Encodable {
    case success([OperationResultXDR])
    case failed
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .success(let operationResult):
            var container = encoder.unkeyedContainer()
            try container.encode(operationResult)
        default:
            break
        }
    }
}

public struct TransactionResultXDR: XDRCodable {
    public var feeCharged:Int64
    public var resultBody:TransactionResultBodyXDR?
    public var code:TransactionResultCode
    public let reserved: Int32 = 0
    
    public init(feeCharged:Int64, resultBody:TransactionResultBodyXDR?, code:TransactionResultCode) {
        self.feeCharged = feeCharged
        self.resultBody = resultBody
        self.code = code
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        feeCharged = try container.decode(Int64.self)
        let discriminant = try container.decode(Int32.self)
        code = TransactionResultCode(rawValue: discriminant)!
        switch code {
            case .success:
                fallthrough
            case .failed:
                resultBody = .success(try decodeArray(type: OperationResultXDR.self, dec: decoder))
            default:
                break
        }
        _ = try container.decode(Int32.self)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(feeCharged)
        try container.encode(code.rawValue)
        try container.encode(resultBody)
        try container.encode(reserved)
    }
    
}
