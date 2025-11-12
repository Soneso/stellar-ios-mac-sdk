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
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#signers "Account Signers")
public class SignerCreatedEffectResponse: SignerEffectResponse {}
