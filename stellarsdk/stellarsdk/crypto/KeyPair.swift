//
//  KeyPair.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import ed25519C

public final class KeyPair {
    public let publicKey: PublicKey
    public let privateKey: PrivateKey

    public var accountId: String {
        get {
            var versionByte = VersionByte.accountId.rawValue
            let versionByteData = Data(bytes: &versionByte, count: MemoryLayout.size(ofValue: versionByte))
            let payload = NSMutableData(data: versionByteData)
            payload.append(Data(bytes: publicKey.bytes))
            let checksumedData = (payload as Data).crc16Data()
            
            return checksumedData.base32EncodedString!
        }
    }
    
    open static func generateRandomKeyPair() throws -> KeyPair {
        let seed = try Seed()
        let keyPair = KeyPair(seed: seed)
        
        return keyPair
        
    }
    
    public init(publicKey: PublicKey, privateKey: PrivateKey) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }

    public convenience init(seed: Seed) {
        var pubBuffer = [UInt8](repeating: 0, count: 32)
        var privBuffer = [UInt8](repeating: 0, count: 64)

        privBuffer.withUnsafeMutableBufferPointer { priv in
            pubBuffer.withUnsafeMutableBufferPointer { pub in
                seed.bytes.withUnsafeBufferPointer { seed in
                    ed25519_create_keypair(pub.baseAddress,
                                           priv.baseAddress,
                                           seed.baseAddress)
                }
            }
        }

        self.init(publicKey: PublicKey(unchecked: pubBuffer),
                  privateKey: PrivateKey(unchecked: privBuffer))
    }

    public convenience init(publicKey: [UInt8], privateKey: [UInt8]) throws {
        let pub = try PublicKey(publicKey)
        let priv = try PrivateKey(privateKey)
        self.init(publicKey: pub, privateKey: priv)
    }
    
    public func sign(_ message: [UInt8]) -> [UInt8] {
        var signature = [UInt8](repeating: 0, count: 64)
        
        signature.withUnsafeMutableBufferPointer { signature in
            privateKey.bytes.withUnsafeBufferPointer { priv in
                publicKey.bytes.withUnsafeBufferPointer { pub in
                    message.withUnsafeBufferPointer { msg in
                        ed25519_sign(signature.baseAddress,
                                     msg.baseAddress,
                                     message.count,
                                     pub.baseAddress,
                                     priv.baseAddress)
                    }
                }
            }
        }
        
        return signature
    }
    
    public func verify(signature: [UInt8], message: [UInt8]) throws -> Bool {
        return try publicKey.verify(signature: signature, message: message)
    }

    public func keyExchange() -> [UInt8] {
        var secret = [UInt8](repeating: 0, count: 32)
        
        publicKey.bytes.withUnsafeBufferPointer { pub in
            privateKey.bytes.withUnsafeBufferPointer { priv in
                secret.withUnsafeMutableBufferPointer { sec in
                    ed25519_key_exchange(sec.baseAddress,
                                         pub.baseAddress,
                                         priv.baseAddress)
                }
            }
        }
        
        return secret
    }

    public static func keyExchange(publicKey: PublicKey, privateKey: PrivateKey) -> [UInt8] {
        let keyPair = KeyPair(publicKey: publicKey, privateKey: privateKey)
        return keyPair.keyExchange()
    }

    public static func keyExchange(publicKey: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
        let keyPair = try KeyPair(publicKey: publicKey, privateKey: privateKey)
        return keyPair.keyExchange()
    }
    
    public func add(scalar: [UInt8]) throws -> KeyPair {
        guard scalar.count == 32 else {
            throw Ed25519Error.invalidScalarLength
        }

        var pub = publicKey.bytes
        var priv = privateKey.bytes
        
        pub.withUnsafeMutableBufferPointer { pub in
            priv.withUnsafeMutableBufferPointer { priv in
                scalar.withUnsafeBufferPointer { scalar in
                    ed25519_add_scalar(pub.baseAddress,
                                       priv.baseAddress,
                                       scalar.baseAddress)
                }
            }
        }
        
        return KeyPair(publicKey: PublicKey(unchecked: pub),
                       privateKey: PrivateKey(unchecked: priv))
    }
}
