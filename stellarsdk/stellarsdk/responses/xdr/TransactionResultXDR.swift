//
//  TransactionResult.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

enum TransactionResultCode: Int {
    case success = 0
    case failed = -1
    case tooEarly = -2
    case tooLate = -3
    case missingOperation = -4
    case badSeq = -5
    case badAuth = -6
    case insufficientBalance = -7
    case noAccount = -8
    case insufficientFee = -9
    case badAuthExtra = -10
    case internalError = -11
}

enum TransactionResultBodyXDR {
    case success([OperationResultXDR])
    case failed
}

struct TransactionResultXDR: XDRCodable {
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
        code = TransactionResultCode(rawValue: try container.decode(Int.self))!
        switch code {
            case .success:
                fallthrough
            case .failed:
                resultBody = .success(try container.decode([OperationResultXDR].self))
            default:
                break
        }
        _ = try container.decode(Int.self)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(feeCharged)
        try container.encode(code.rawValue)
        try container.encode(resultBody)
        try container.encode(reserved)
    }
    
}
