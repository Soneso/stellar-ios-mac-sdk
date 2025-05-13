//
//  AssembledTransactionError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public enum AssembledTransactionError: Error {
    case notYetAssembled(message: String)
    case notYetSimulated(message: String)
    case notYetSigned(message: String)
    case missingPrivateKey(message: String)
    case simulationFailed(message: String)
    case restoreNeeded(message: String)
    case isReadCall(message: String)
    case unexpectedTxType(message: String)
    case multipleSignersRequired(message: String)
    case pollInterrupted(message: String)
    case automaticRestoreFailed(message: String)
    case sendFailed(message: String)
}
