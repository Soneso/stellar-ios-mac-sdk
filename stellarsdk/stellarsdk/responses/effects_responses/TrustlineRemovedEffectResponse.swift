//
//  TrustlineRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline removal effect.
/// This effect occurs when an account removes a trustline to an asset through a Change Trust operation with limit set to zero.
/// The account must have a zero balance of the asset before the trustline can be removed.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#trustlines "Trustlines")
public class TrustlineRemovedEffectResponse: TrustlineEffectResponse {}
