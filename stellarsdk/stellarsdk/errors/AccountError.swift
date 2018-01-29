//
//  AccountError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

enum AccountError: Error {
    case keyGenerationFailed(osStatus: OSStatus)
}
