//
//  AssetType.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright (c) 2018 Soneso. All rights reserved.
//

import Foundation

public struct AssetType: Sendable {
    public static let ASSET_TYPE_NATIVE: Int32 = 0
    public static let ASSET_TYPE_CREDIT_ALPHANUM4: Int32 = 1
    public static let ASSET_TYPE_CREDIT_ALPHANUM12: Int32 = 2
    public static let ASSET_TYPE_POOL_SHARE: Int32 = 3
}
