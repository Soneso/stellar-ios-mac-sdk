//
//  Ed25519Error.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

public enum Ed25519Error: Error {
    case seedGenerationFailed
    case invalidSeed
    case invalidSeedLength
    case invalidScalarLength
    case invalidPublicKey
    case invalidPublicKeyLength
    case invalidPrivateKey
    case invalidPrivateKeyLength
    case invalidSignatureLength
}
