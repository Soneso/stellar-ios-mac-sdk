//
//  RecoveryServiceErrors.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation


public enum RecoveryServiceError: Error {
    case badRequest(message:String)
    case unauthorized(message:String)
    case notFound(message:String)
    case conflict(message:String)
    case parsingResponseFailed(message:String)
    case horizonError(error: HorizonRequestError)
}
