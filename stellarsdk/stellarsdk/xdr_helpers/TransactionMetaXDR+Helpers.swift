//
//  TransactionMetaXDR+Helpers.swift
//  stellarsdk
//
//  SDK convenience helpers for TransactionMetaXDR.
//

import Foundation

public enum TransactionMetaType: Int32, Sendable {
    case operations = 0
    case transactionMetaV1 = 1
    case transactionMetaV2 = 2
    case transactionMetaV3 = 3
    case transactionMetaV4 = 4
}

extension TransactionMetaXDR {

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try TransactionMetaXDR(from: xdrDecoder)
    }

    public var transactionMetaV3: TransactionMetaV3XDR? {
        switch self {
        case .transactionMetaV3(let val):
            return val
        default:
            return nil
        }
    }

    public var transactionMetaV4: TransactionMetaV4XDR? {
        switch self {
        case .transactionMetaV4(let val):
            return val
        default:
            return nil
        }
    }
}
