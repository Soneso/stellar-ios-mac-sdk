//
//  TrustlineDeauthorizedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline deauthorization effect.
/// This effect occurs when an asset issuer revokes authorization for another account to hold its asset through an Allow Trust or Set Trust Line Flags operation.
/// The account can no longer receive or send the asset.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/security/authorization-flags "Authorization Flags")
public class TrustlineDeauthorizedEffectResponse: TrustlineEffectResponse {}
