//
//  OfferRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an offer removal effect.
/// This effect occurs when an existing offer is cancelled or fully filled on the Stellar decentralized exchange (DEX).
/// Triggered by the Manage Sell Offer or Manage Buy Offer operations, or when an offer is completely matched.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/operations-and-transactions#manage-buy-offer "Offers")
public class OfferRemovedEffectResponse: EffectResponse {}
