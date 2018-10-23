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
    
    public static func sha256Hash(hash:Data) -> SignerKeyXDR {
        let data = WrappedData32(hash)
        return SignerKeyXDR.hashX(data)
    }
    
    public static func preAuthTx(transaction: Transaction, network: Network) throws -> SignerKeyXDR {
        let data = try transaction.getTransactionHashData(network: network)
        return SignerKeyXDR.preAuthTx(WrappedData32(data))
    }
}
