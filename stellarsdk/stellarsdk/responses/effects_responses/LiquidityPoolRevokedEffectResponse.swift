//
//  LiquidityPoolRevokedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool revocation effect.
/// This effect occurs when trustline authorization for a liquidity pool is revoked by an asset issuer.
/// The pool shares are revoked and the reserves are returned.
/// Triggered by the Set Trust Line Flags or Allow Trust operations.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/sdex/liquidity-on-stellar-sdex-liquidity-pools "Liquidity Pools")
public class LiquidityPoolRevokedEffectResponse: EffectResponse {

    /// The liquidity pool details.
    public var liquidityPool:LiquidityPoolEffectResponse

    /// The asset reserves revoked from the pool.
    public var reservesRevoked:[ReserveResponse]

    /// The number of pool shares revoked.
    public var sharesRevoked:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
        case reservesRevoked = "reserves_revoked"
        case sharesRevoked = "shares_revoked"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolEffectResponse.self, forKey: .liquidityPool)
        reservesRevoked = try values.decode([ReserveResponse].self, forKey: .reservesRevoked)
        sharesRevoked = try values.decode(String.self, forKey: .sharesRevoked)
        try super.init(from: decoder)
    }
}
