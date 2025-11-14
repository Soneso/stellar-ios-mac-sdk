//
//  OfferUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an offer update effect.
/// This effect occurs when an existing offer is modified or partially filled on the Stellar decentralized exchange (DEX).
/// Triggered by the Manage Sell Offer or Manage Buy Offer operations, or when an offer is partially matched.
/// See [Stellar developer docs](https://developers.stellar.org)
public class OfferUpdatedEffectResponse: EffectResponse {}
