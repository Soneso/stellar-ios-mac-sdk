//
//  EffectsError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum EffectsError: Error {
    case effectNotFound(response: String)
    case parsingFailed(response: String)
    case requestFailed(response: String)
}
