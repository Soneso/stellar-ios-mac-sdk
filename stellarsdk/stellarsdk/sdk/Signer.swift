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
        return SignerKeyXDR.ed25519(keyPair.publicKey.wrappedData32())
    }
    
    public static func ed25519PublicKey(accountId:String) throws -> SignerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        return SignerKeyXDR.ed25519(pk.wrappedData32())
    }
    
    public static func sha256Hash(hash:Data) -> SignerKeyXDR {
        let data = WrappedData32(hash)
        return SignerKeyXDR.hashX(data)
    }
    
    public static func preAuthTx(transaction: Transaction, network: Network) throws -> SignerKeyXDR {
        let data = try transaction.getTransactionHashData(network: network)
        return SignerKeyXDR.preAuthTx(WrappedData32(data))
    }
    
    /**
     * Data model for the <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#xdr-changes">signed payload signer </a>
     */
    public static func signedPayload(accountId: String, payload: Data) throws -> SignerKeyXDR {
        if payload.count > StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD {
            throw StellarSDKError.invalidArgument(message: "invalid payload length, must be less than \(StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD)")
        }
        let pk = try PublicKey(accountId: accountId)
        return SignerKeyXDR.signedPayload(Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: payload))
    }
}
