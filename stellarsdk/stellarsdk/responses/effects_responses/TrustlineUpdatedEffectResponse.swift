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
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineUpdatedEffectResponse: TrustlineEffectResponse {}
