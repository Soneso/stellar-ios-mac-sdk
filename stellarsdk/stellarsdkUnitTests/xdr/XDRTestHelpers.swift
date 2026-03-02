//
//  XDRTestHelpers.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

enum XDRTestHelpers {
    static func publicKey() throws -> PublicKey {
        try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
    }
    static func wrappedData4() -> WrappedData4 { WrappedData4(Data([1, 2, 3, 4])) }
    static func wrappedData12() -> WrappedData12 { WrappedData12(Data(repeating: 0xAB, count: 12)) }
    static func wrappedData16() -> WrappedData16 { WrappedData16(Data(repeating: 0xCD, count: 16)) }
    static func wrappedData32() -> WrappedData32 { WrappedData32(Data(repeating: 0xEF, count: 32)) }
    static func signature() -> DecoratedSignatureXDR {
        DecoratedSignatureXDR(hint: wrappedData4(), signature: Data(repeating: 0x01, count: 64))
    }
    static func asset() -> AssetXDR { .native }
    static func scVal() -> SCValXDR { .u32(42) }
    static func ledgerKey() -> LedgerKeyXDR {
        try! .account(LedgerKeyAccountXDR(accountID: publicKey()))
    }
}
