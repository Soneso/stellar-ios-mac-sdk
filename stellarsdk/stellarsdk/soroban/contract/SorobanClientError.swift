//
//  SorobanClientError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public enum SorobanClientError: Error {
    case deployFailed(message: String)
    case installFailed(message: String)
    case invokeFailed(message: String)
    case methodNotFound(message: String)
}
