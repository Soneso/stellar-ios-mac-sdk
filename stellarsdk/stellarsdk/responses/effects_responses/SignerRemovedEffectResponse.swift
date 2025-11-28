//
//  SignerRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a signer removal effect.
/// This effect occurs when a signer is removed from an account through a Set Options operation.
/// The removed signer can no longer authorize transactions for the account.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerRemovedEffectResponse: SignerEffectResponse, @unchecked Sendable {}


