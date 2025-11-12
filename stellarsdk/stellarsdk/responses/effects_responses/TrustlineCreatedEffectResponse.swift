//
//  TrustlineCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline creation effect.
/// This effect occurs when an account establishes a new trustline to an asset through a Change Trust operation.
/// Trustlines are required to hold and trade non-native assets on the Stellar network.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#trustlines "Trustlines")
public class TrustlineCreatedEffectResponse: TrustlineEffectResponse {}
