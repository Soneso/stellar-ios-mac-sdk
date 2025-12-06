//
//  AccountRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account removal effect.
/// This effect occurs when an account is merged into another account through an Account Merge operation.
/// The account's remaining balance is transferred to the destination account, and the source account is removed from the ledger.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AccountRemovedEffectResponse: EffectResponse, @unchecked Sendable {}
