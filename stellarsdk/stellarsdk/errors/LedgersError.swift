//
//  LedgersError.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgersError: Error {
    case ledgersNotFound(response: String)
    case parsingFailed(response: String)
    case requestFailed(response: String)
}

