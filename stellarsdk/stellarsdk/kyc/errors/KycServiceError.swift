//
//  KycServiceError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum KycServiceError: Error {
    case invalidDomain
    case invalidToml
    case noKycOrTransferServerSet
    case parsingResponseFailed(message:String)
    case badRequest(error:String) // 400
    case notFound(error:String) // 404
    case unauthorized(message:String) // 401
    case horizonError(error: HorizonRequestError)
}
