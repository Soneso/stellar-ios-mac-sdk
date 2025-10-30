//
//  SEPConstants.swift
//  stellarsdk
//
//  Created on 30.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Constants defined by Stellar Ecosystem Proposals (SEPs).
/// These values represent configuration defaults, timeouts, and validation constraints
/// specified in various SEP standards.
///
/// Reference: https://github.com/stellar/stellar-protocol/tree/master/ecosystem
public struct SEPConstants {

    // MARK: - SEP-10 Web Authentication

    /// Grace period for SEP-10 challenge transaction validation in seconds (300 seconds = 5 minutes)
    /// This is the time window within which a challenge transaction must be submitted
    /// after its minTime and before its maxTime
    /// Reference: SEP-10 https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md
    public static let WEBAUTH_GRACE_PERIOD_SECONDS: UInt64 = 300
}
