//
//  OperationsError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum OperationsError: Error {
    case operationNotFound(response: String)
    case parsingFailed(response: String)
    case requestFailed(response: String)
}
