//
//  KeyPair.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

open class KeyPair: NSObject {
    public let publicKey: Data
    public let privateKey: Data
    
    init(publicKey: Data, privateKey: Data) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    open static func generateRandomKeyPair() throws -> KeyPair {
        let keys = try Crypto().generateRSAKeys()
        let keyPair = KeyPair(publicKey: keys.0, privateKey: keys.1)
            
        return keyPair
        
    }
    
}
