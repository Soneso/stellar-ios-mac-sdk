//
//  Crypto.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class Crypto: NSObject {

    func generateRSAKeys() throws -> (Data, Data) {
        let publicKeyAttr = [kSecAttrIsPermanent:true, kSecAttrApplicationTag:"com.xeoscript.app.RsaFromScrach.public".data(using: String.Encoding.utf8)!, kSecClass: kSecClassKey, kSecReturnData: kCFBooleanTrue] as [CFString : Any]
        let privateKeyAttr = [kSecAttrIsPermanent:true, kSecAttrApplicationTag:"com.xeoscript.app.RsaFromScrach.private".data(using: String.Encoding.utf8)!, kSecClass: kSecClassKey, kSecReturnData: kCFBooleanTrue] as [CFString : Any]
        
        var keyPairAttr = [NSObject: NSObject]()
        keyPairAttr[kSecAttrKeyType] = kSecAttrKeyTypeRSA
        keyPairAttr[kSecAttrKeySizeInBits] = 2048 as NSObject
        keyPairAttr[kSecPublicKeyAttrs] = publicKeyAttr as NSObject
        keyPairAttr[kSecPrivateKeyAttrs] = privateKeyAttr as NSObject
        
        var publicKey, privateKey: SecKey?
        let statusCode = SecKeyGeneratePair(keyPairAttr as CFDictionary, &publicKey, &privateKey)
        
        if statusCode == noErr && publicKey != nil && privateKey != nil {
            print("Key pair generated OK")
            var resultPublicKey: AnyObject?
            var resultPrivateKey: AnyObject?
            let statusPublicKey = SecItemCopyMatching(publicKeyAttr as CFDictionary, &resultPublicKey)
            let statusPrivateKey = SecItemCopyMatching(privateKeyAttr as CFDictionary, &resultPrivateKey)
            
            if statusPublicKey == noErr && statusPrivateKey == noErr {
                if let publicKey = resultPublicKey as? Data, let privateKey = resultPrivateKey as? Data {
                    print("Public Key: \((publicKey.base64EncodedString()))")
                    print("Private Key: \((privateKey.base64EncodedString()))")
                    
                    return (publicKey, privateKey)
                }
            }
            throw AccountError.keyGenerationFailed(osStatus: statusPublicKey)
        } else {
            print("Error generating key pair: \(String(describing: statusCode))")
            throw AccountError.keyGenerationFailed(osStatus: statusCode)
        }
    }
    
}
