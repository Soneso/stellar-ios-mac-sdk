//
//  Ed25519Derivation.swift
//  stellarsdk
//
//  Created by Satraj Bambra on 2018-03-07.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Ed25519Derivation used to derivce and derive m/44'/148' key from BIP39 seed.
public struct Ed25519Derivation {
    public let raw: Data
    public let chainCode: Data
    
    public init(seed: Data) {
        let output = HDCrypto.HMACSHA512(key: "ed25519 seed".data(using: .utf8)!, data: seed)
        self.raw = output[0..<32]
        self.chainCode = output[32..<64]
    }
    
    private init(privateKey: Data, chainCode: Data) {
        self.raw = privateKey
        self.chainCode = chainCode
    }
    
    public func derived(at index: UInt32) -> Ed25519Derivation {
        let edge: UInt32 = 0x80000000
        guard (edge & index) == 0 else { fatalError("Invalid index") }
        
        var data = Data()
        data += UInt8(0)
        data += raw
        
        let derivingIndex = edge + index
        data += derivingIndex.bigEndian
        
        let digest = HDCrypto.HMACSHA512(key: chainCode, data: data)
        let factor = BInt(data: digest[0..<32])
        
        let derivedPrivateKey = factor.data
        let derivedChainCode = digest[32..<64]
        
        return Ed25519Derivation (
            privateKey: derivedPrivateKey,
            chainCode: derivedChainCode
        )
    }
}
