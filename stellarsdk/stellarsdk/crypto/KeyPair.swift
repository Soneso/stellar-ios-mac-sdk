//
//  KeyPair.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import ed25519C

/// Holds a Stellar keypair.
public final class KeyPair {
    public let publicKey: PublicKey
    public let privateKey: PrivateKey?

    /// Human readable Stellar account ID
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
    
    /// Generates a random Stellar keypair.
    open static func generateRandomKeyPair() throws -> KeyPair {
        let seed = try Seed()
        let keyPair = KeyPair(seed: seed)
        
        return keyPair
        
    }
    
    /// Creates a new KeyPair from the given public and private keys.
    ///
    /// - Parameter publicKey: The public key
    /// - Parameter publicKey: The private key. Optional, if nil creates a new KeyPair without a private key.
    ///
    public init(publicKey: PublicKey, privateKey: PrivateKey?) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }

    /// Creates a new Stellar KeyPair from a Stellar account ID. The new KeyPair is without a private key.
    ///
    /// - Parameter accountId: The Stellar account ID.
    ///
    public convenience init(accountId: String) throws {
        let publicKeyFromAccountId = try PublicKey(accountId: accountId)
        self.init(publicKey: publicKeyFromAccountId, privateKey:nil)
    }
    
    /// Creates a new Stellar keypair from a Stellar secret seed. The new KeyPair contains public and private key.
    ///
    /// - Parameter secretSeed: the Stellar secret seed.
    public convenience init(secretSeed: String) throws {
        let seedFromSecret = try Seed(secret:secretSeed)
        self.init(seed: seedFromSecret)
    }
    
    /// Creates a new KeyPair without a private key. Useful e.g. to simply verify a signature from a given public address
    ///
    /// - Parameter publicKey: The public key
    ///
    public convenience init(publicKey: PublicKey)
    {
        self.init(publicKey:publicKey, privateKey:nil)
    }
    
    /// Creates a new Stellar keypair from a seed object. The new KeyPair contains public and private key.
    ///
    /// - Parameter seed: the seed object
    ///
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
    
    /// Creates a new Stellar keypair from a public key byte array and a private key byte array.
    ///
    /// - Parameter publicKey: the public key byte array. Must have a lenght of 32.
    /// - Parameter privateKey: the private key byte array. Must have a lenght of 64.
    ///
    /// - Throws Ed25519Error.invalidPublicKeyLength if the lenght of the given byte array != 32
    /// - Throws Ed25519Error.invalidPrivateKeyLength if the lenght of the given byte array != 64
    ///
    public convenience init(publicKey: [UInt8], privateKey: [UInt8]) throws {
        let pub = try PublicKey(publicKey)
        let priv = try PrivateKey(privateKey)
        self.init(publicKey: pub, privateKey: priv)
    }

    /// TODO: is this needed?
    public static func fromXDRPublicKey(_ publicKey: PublicKey) -> KeyPair {
        var seedBuffer = [UInt8](repeating: 0, count: 32)
        var privBuffer = [UInt8](repeating: 0, count: 64)
        var pubBuffer = [UInt8](publicKey.bytes)
        
        privBuffer.withUnsafeMutableBufferPointer { priv in
            pubBuffer.withUnsafeMutableBufferPointer { pub in
                seedBuffer.withUnsafeMutableBufferPointer { seed in
                    ed25519_create_keypair(pub.baseAddress,
                                           priv.baseAddress,
                                           seed.baseAddress)
                }
            }
        }
        
        return KeyPair(publicKey: PublicKey(unchecked: pubBuffer),
                  privateKey: PrivateKey(unchecked: privBuffer))
    }
    
    /// Sign the provided data with the keypair's private key.
    ///
    /// - Parameter message: The data to sign.
    ///
    /// - Returns signed bytes, "empty" byte array containing only 0 if the private key for this keypair is null.
    ///
    public func sign(_ message: [UInt8]) -> [UInt8] {
        
        var signature = [UInt8](repeating: 0, count: 64)
        
        if (privateKey == nil) { return signature}
        
        signature.withUnsafeMutableBufferPointer { signature in
            privateKey?.bytes.withUnsafeBufferPointer { priv in
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
    
    /// Sign the provided data with the keypair's private key and returns the DecoratedSignatureXDR
    ///
    /// - Parameter data: data to be signed
    ///
    /// - Returns the DecoratedSignatureXDR object
    ///
    public func signDecorated(_ message: [UInt8]) -> DecoratedSignatureXDR {
        var signatureBytes = sign(message)
        let signatureData = Data(bytes: &signatureBytes, count: signatureBytes.count)
        var publicKeyData = publicKey.bytes
        let hint = Data(bytes: &publicKeyData, count: publicKeyData.count).suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint) , signature: signatureData)
        
        return decoratedSignature
    }

    ///  Verify the provided data and signature match this keypair's public key.
    ///
    /// - Parameter signature: The signature. Byte array must have a lenght of 64.
    /// - Parameter message: The data that was signed.
    ///
    /// - Returns: True if they match, false otherwise.
    ///
    /// - Throws: Ed25519Error.invalidSignatureLength if the signature length is not 64
    ///
    public func verify(signature: [UInt8], message: [UInt8]) throws -> Bool {
        return try publicKey.verify(signature: signature, message: message)
    }
    
    /*
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
    }*/
}
