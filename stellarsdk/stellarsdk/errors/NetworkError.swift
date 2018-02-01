//
//  NetworkError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 01/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum NetworkError: Error {
    case requestFailed(message: String)
    case resourceNotFound(message: String)
    case internalError(message: String)
    case emptyResponse
}
