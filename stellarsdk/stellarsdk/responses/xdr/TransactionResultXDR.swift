//
//  TransactionResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

public enum TransactionResultCode: Int32 {
    case feeBumpInnerSuccess = 1
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
    case notSupported = -12
    case feeBumpInnerFailed = -13 // fee bump inner transaction failed
    case badSponsorship = -14 // sponsorship not ended
    case badMinSeqAgeOrGap = -15 // minSeqAge or minSeqLedgerGap conditions not met
    case malformed = -16 // precondition is invalid
    case sorobanInvalid = -17 // soroban-specific preconditions were not met
}

public enum TransactionResultBodyXDR: Encodable {
    case success([OperationResultXDR])
    case failed([OperationResultXDR])
    case feeBumpInnerSuccess(InnerTransactionResultPair)
    case feeBumpInnerFailed(InnerTransactionResultPair)
    case tooEarly
    case tooLate
    case missingOperation
    case badSeq
    case badAuth
    case insufficientBalance
    case noAccount
    case insufficientFee
    case badAuthExtra
    case internalError
    case notSupported
    case badSponsorship
    case badMinSeqAgeOrGap
    case malformed
    case sorobanInvalid
    
    public func type() -> Int32 {
        switch self {
        case .success(_): return TransactionResultCode.success.rawValue
        case .failed(_): return TransactionResultCode.failed.rawValue
        case .feeBumpInnerSuccess(_): return TransactionResultCode.feeBumpInnerSuccess.rawValue
        case .feeBumpInnerFailed(_): return TransactionResultCode.feeBumpInnerFailed.rawValue
        case .tooEarly: return TransactionResultCode.tooEarly.rawValue
        case .tooLate: return TransactionResultCode.tooLate.rawValue
        case .missingOperation: return TransactionResultCode.missingOperation.rawValue
        case .badSeq: return TransactionResultCode.badSeq.rawValue
        case .badAuth: return TransactionResultCode.badAuth.rawValue
        case .insufficientBalance: return TransactionResultCode.insufficientBalance.rawValue
        case .noAccount: return TransactionResultCode.noAccount.rawValue
        case .insufficientFee: return TransactionResultCode.insufficientFee.rawValue
        case .badAuthExtra: return TransactionResultCode.badAuthExtra.rawValue
        case .internalError: return TransactionResultCode.internalError.rawValue
        case .notSupported: return TransactionResultCode.notSupported.rawValue
        case .badSponsorship: return TransactionResultCode.badSponsorship.rawValue
        case .badMinSeqAgeOrGap: return TransactionResultCode.badMinSeqAgeOrGap.rawValue
        case .malformed: return TransactionResultCode.malformed.rawValue
        case .sorobanInvalid: return TransactionResultCode.sorobanInvalid.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .success(let operationResult):
            try container.encode(operationResult)
        case .failed(let operationResult):
            try container.encode(operationResult)
        case .feeBumpInnerSuccess(let inner):
            try container.encode(inner)
        case .feeBumpInnerFailed(let inner):
            try container.encode(inner)
        default:
            break
        }
    }
}

public struct InnerTransactionResultPair: XDRCodable {
    public var hash:WrappedData32
    public var result:InnerTransactionResultXDR
    
    public init(hash:WrappedData32, result:InnerTransactionResultXDR) {
        self.hash = hash
        self.result = result
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hash = try container.decode(WrappedData32.self)
        result = try container.decode(InnerTransactionResultXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hash)
        try container.encode(result)
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
                resultBody = .success(try decodeArray(type: OperationResultXDR.self, dec: decoder))
            case .failed:
                resultBody = .failed(try decodeArray(type: OperationResultXDR.self, dec: decoder))
            case .feeBumpInnerSuccess:
                resultBody = .feeBumpInnerSuccess(try container.decode(InnerTransactionResultPair.self))
            case .feeBumpInnerFailed:
                resultBody = .feeBumpInnerFailed(try container.decode(InnerTransactionResultPair.self))
            case .tooEarly: resultBody = .tooEarly
            case .tooLate: resultBody = .tooLate
            case .missingOperation: resultBody = .missingOperation
            case .badSeq: resultBody = .badSeq
            case .badAuth: resultBody = .badAuth
            case .insufficientBalance: resultBody = .insufficientBalance
            case .noAccount: resultBody = .noAccount
            case .insufficientFee: resultBody = .insufficientFee
            case .badAuthExtra: resultBody = .badAuthExtra
            case .internalError: resultBody = .internalError
            case .notSupported: resultBody = .notSupported
            case .badSponsorship: resultBody = .badSponsorship
            case .badMinSeqAgeOrGap: resultBody = .badMinSeqAgeOrGap
            case .malformed: resultBody = .malformed
            case .sorobanInvalid: resultBody = .sorobanInvalid
        }
        _ = try container.decode(Int32.self)
        
    }
    
    public static func fromXdr(base64:String) throws -> TransactionResultXDR {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: base64))
        return try TransactionResultXDR(from: xdrDecoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(feeCharged)
        try container.encode(code.rawValue)
        try container.encode(resultBody)
        try container.encode(reserved)
    }
    
}

public enum InnerTransactionResultBodyXDR: Encodable {
    case success([OperationResultXDR])
    case failed([OperationResultXDR])
    case tooEarly
    case tooLate
    case missingOperation
    case badSeq
    case badAuth
    case insufficientBalance
    case noAccount
    case insufficientFee
    case badAuthExtra
    case internalError
    case notSupported
    case badSponsorship
    case badMinSeqAgeOrGap
    case malformed
    case sorobanInvalid
    
    public func type() -> Int32 {
        switch self {
        case .success(_): return TransactionResultCode.success.rawValue
        case .failed(_): return TransactionResultCode.failed.rawValue
        case .tooEarly: return TransactionResultCode.tooEarly.rawValue
        case .tooLate: return TransactionResultCode.tooLate.rawValue
        case .missingOperation: return TransactionResultCode.missingOperation.rawValue
        case .badSeq: return TransactionResultCode.badSeq.rawValue
        case .badAuth: return TransactionResultCode.badAuth.rawValue
        case .insufficientBalance: return TransactionResultCode.insufficientBalance.rawValue
        case .noAccount: return TransactionResultCode.noAccount.rawValue
        case .insufficientFee: return TransactionResultCode.insufficientFee.rawValue
        case .badAuthExtra: return TransactionResultCode.badAuthExtra.rawValue
        case .internalError: return TransactionResultCode.internalError.rawValue
        case .notSupported: return TransactionResultCode.notSupported.rawValue
        case .badSponsorship: return TransactionResultCode.badSponsorship.rawValue
        case .badMinSeqAgeOrGap: return TransactionResultCode.badMinSeqAgeOrGap.rawValue
        case .malformed: return TransactionResultCode.malformed.rawValue
        case .sorobanInvalid: return TransactionResultCode.sorobanInvalid.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .success(let operationResult):
            try container.encode(operationResult)
        case .failed(let operationResult):
            try container.encode(operationResult)
        default:
            break
        }
    }
}

public struct InnerTransactionResultXDR: XDRCodable {
    public var feeCharged:Int64
    public var resultBody:InnerTransactionResultBodyXDR?
    public var code:TransactionResultCode
    public let reserved: Int32 = 0
    
    public init(feeCharged:Int64, resultBody:InnerTransactionResultBodyXDR?, code:TransactionResultCode) {
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
                resultBody = .success(try decodeArray(type: OperationResultXDR.self, dec: decoder))
            case .failed:
                resultBody = .failed(try decodeArray(type: OperationResultXDR.self, dec: decoder))
            case .tooEarly: resultBody = .tooEarly
            case .tooLate: resultBody = .tooLate
            case .missingOperation: resultBody = .missingOperation
            case .badSeq: resultBody = .badSeq
            case .badAuth: resultBody = .badAuth
            case .insufficientBalance: resultBody = .insufficientBalance
            case .noAccount: resultBody = .noAccount
            case .insufficientFee: resultBody = .insufficientFee
            case .badAuthExtra: resultBody = .badAuthExtra
            case .internalError: resultBody = .internalError
            case .notSupported: resultBody = .notSupported
            case .badSponsorship: resultBody = .badSponsorship
            case .badMinSeqAgeOrGap: resultBody = .badMinSeqAgeOrGap
            case .malformed: resultBody = .malformed
            case .sorobanInvalid: resultBody = .sorobanInvalid
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
