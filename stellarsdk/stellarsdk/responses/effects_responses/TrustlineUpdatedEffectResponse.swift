//
//  TrustlineUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline update effect.
/// This effect occurs when an existing trustline's limit is modified through a Change Trust operation.
/// The account can increase or decrease the maximum amount of the asset it is willing to hold.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#trustlines "Trustlines")
public class TrustlineUpdatedEffectResponse: TrustlineEffectResponse {}
