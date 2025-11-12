//
//  TrustlineAuthorizedToMaintainLiabilitiesResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 15.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline authorized to maintain liabilities effect.
/// This effect occurs when an asset issuer sets a trustline to maintain liabilities only through an Allow Trust or Set Trust Line Flags operation.
/// The account can maintain existing offers and outstanding liabilities but cannot receive new assets.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/security/authorization-flags "Authorization Flags")
public class TrustlineAuthorizedToMaintainLiabilitiesEffecResponse: TrustlineEffectResponse {}

