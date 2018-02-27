//
//  Signer.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/27/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class Signer {
    
    public static func ed25519PublicKey(keyPair:KeyPair) -> SignerKeyXDR {
        return KeyPair.fromXDRSignerKey(keyPair.publicKey)
    }
    
}
