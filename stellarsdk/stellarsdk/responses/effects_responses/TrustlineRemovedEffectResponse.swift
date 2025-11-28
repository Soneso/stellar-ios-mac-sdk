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
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineRemovedEffectResponse: TrustlineEffectResponse, @unchecked Sendable {}
