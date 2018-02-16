//
//  AccountFlag.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 15.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    AccountFlag is the 'enum' that can be used in 'SetOptionsOperation'
    See [Stellar Guides](https://www.stellar.org/developers/guides/concepts/accounts.html#flags, "Account Flags)
 */

enum AccountFlag: Int {
    /// Authorization required: Requires the issuing account to give other accounts permission before they can hold the issuing account’s credit.
    case required = 1
    /// Authorization revocable: Allows the issuing account to revoke its credit held by other accounts.
    case revocable = 2
    /// Authorization immutable: If this is set then none of the authorization flags can be set and the account can never be deleted.
    case immutable = 4
}
