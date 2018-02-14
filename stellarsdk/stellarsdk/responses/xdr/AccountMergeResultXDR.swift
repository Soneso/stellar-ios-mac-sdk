//
//  AccountMergeResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AccountMergeResultCode: Int {
    case success = 0
    case malformed = -1
    case noAccount = -2
    case immutableSet = -3
    case hasSubEntries = -4
}

class AccountMergeResultXDR: XDRCodable {

}
