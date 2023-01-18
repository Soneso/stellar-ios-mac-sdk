//
//  SorobanRpcRequestError.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SorobanRpcRequestError: Error {
    case requestFailed(message: String)
    case errorResponse(errorData:[String: Any])
    case parsingResponseFailed(message:String, responseData:Data)
}
