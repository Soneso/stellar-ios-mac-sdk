//
//  OfferCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an offer creation effect.
/// This effect occurs when a new offer to buy or sell assets is created on the Stellar decentralized exchange (DEX).
/// Triggered by the Manage Sell Offer, Manage Buy Offer, or Create Passive Sell Offer operations.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/operations-and-transactions#manage-buy-offer "Offers")
public class OfferCreatedEffectResponse: EffectResponse {}
