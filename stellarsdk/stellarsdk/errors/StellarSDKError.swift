//
//  StellarSDKError.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 14.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum StellarSDKError: Error {
    case invalidArgument(message: String)
    case xdrDecodingError(message: String)
    case xdrEncodingError(message: String)
    case encodingError(message: String)
    case decodingError(message: String)
}
