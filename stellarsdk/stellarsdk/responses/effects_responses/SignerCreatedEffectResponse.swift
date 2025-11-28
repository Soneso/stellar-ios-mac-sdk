//
//  SignerCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a signer creation effect.
/// This effect occurs when a new signer is added to an account through a Set Options operation.
/// The new signer can be used for multi-signature authorization of transactions.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerCreatedEffectResponse: SignerEffectResponse, @unchecked Sendable {}
