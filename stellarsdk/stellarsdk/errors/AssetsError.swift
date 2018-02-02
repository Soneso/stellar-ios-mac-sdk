//
//  AssetsError.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum AssetsError: Error {
    case assetsNotFound(response: String)
    case parsingFailed(response: String)
    case requestFailed(response: String)
}

