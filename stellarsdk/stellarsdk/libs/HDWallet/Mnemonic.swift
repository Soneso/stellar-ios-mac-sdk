//
//  Mnemonic.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/02/11.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki

import Foundation

public final class Mnemonic {
    public enum Strength: Int {
        case normal = 128
        case high = 256
    }
    
    public static func create(strength: Strength = .normal, language: WordList = .english) -> String {
        let byteCount = strength.rawValue / 8
        var bytes = Data(count: byteCount)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0) }
        return create(entropy: bytes, language: language)
    }
    
    public static func create(entropy: Data, language: WordList = .english) -> String {
        let entropybits = String(entropy.flatMap { ("00000000" + String($0, radix: 2)).suffix(8) })
        let hashBits = String(entropy.sha256().flatMap { ("00000000" + String($0, radix: 2)).suffix(8) })
        let checkSum = String(hashBits.prefix((entropy.count * 8) / 32))
        
        let words = language.words
        let concatenatedBits = entropybits + checkSum
        
        var mnemonic: [String] = []
        for index in 0..<(concatenatedBits.count / 11) {
            let startIndex = concatenatedBits.index(concatenatedBits.startIndex, offsetBy: index * 11)
            let endIndex = concatenatedBits.index(startIndex, offsetBy: 11)
            let wordIndex = Int(strtoul(String(concatenatedBits[startIndex..<endIndex]), nil, 2))
            mnemonic.append(String(words[wordIndex]))
        }
        
        return mnemonic.joined(separator: " ")
    }

    
    public static func createSeed(mnemonic: String, withPassphrase passphrase: String = "") -> Data {
        guard let password = mnemonic.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing password failed in \(self)")
        }
        
        guard let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing salt failed in \(self)")
        }
        
        return HDCrypto.PBKDF2SHA512(password: password.bytes, salt: salt.bytes)
    }
}


