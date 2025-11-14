//
//  SignerUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a signer update effect.
/// This effect occurs when an existing signer's weight is modified through a Set Options operation.
/// Changing a signer's weight affects the multi-signature authorization requirements.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerUpdatedEffectResponse: SignerEffectResponse {}

