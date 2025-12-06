//
//  TrustlineAuthorizedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline authorization effect.
/// This effect occurs when an asset issuer authorizes another account to hold its asset through an Allow Trust or Set Trust Line Flags operation.
/// Required when the issuer has the AUTH_REQUIRED flag set.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineAuthorizedEffectResponse: TrustlineEffectResponse, @unchecked Sendable {}
