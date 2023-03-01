//
//  AccountEd25519Signature.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class AccountEd25519Signature {
    
    public let publicKey:PublicKey
    public let signature:[UInt8]
    
    public init(publicKey:PublicKey, signature:[UInt8]) {
        self.publicKey = publicKey
        self.signature = signature
    }
}
