//
//  AccountEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AccountFlags: Sendable {
    // Flags set on issuer accounts
    // trust lines are created with authorized set to "false" requiring
    // the issuer to set it for each trust line
    public static let AUTH_REQUIRED_FLAG: UInt32 = 1
    // If set, the authorized flag in trust lines can be cleared
    // otherwise, authorization cannot be revoked
    public static let AUTH_REVOCABLE_FLAG: UInt32 = 2
    // Once set, causes all AUTH_* flags to be read-only
    public static let AUTH_IMMUTABLE_FLAG: UInt32 = 4
    // trust lines are created with clawback enabled set to "true",
    // and claimable balances created from those trustlines are created
    // with clawback enabled set to "true"
    public static let AUTH_CLAWBACK_ENABLED_FLAG: UInt32 = 8
}
