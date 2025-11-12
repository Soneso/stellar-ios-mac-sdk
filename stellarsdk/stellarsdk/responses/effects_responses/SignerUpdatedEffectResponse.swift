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
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#signers "Account Signers")
public class SignerUpdatedEffectResponse: SignerEffectResponse {}

