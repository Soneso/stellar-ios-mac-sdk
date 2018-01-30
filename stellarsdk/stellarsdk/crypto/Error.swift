//
//  Data+CRC.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

public enum Ed25519Error: Error {
    case seedGenerationFailed
    case invalidSeedLength
    case invalidScalarLength
    case invalidPublicKeyLength
    case invalidPrivateKeyLength
    case invalidSignatureLength
}
