//
//  InflationOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// An inflation operation, which has no parameters.
///
/// The network refuses this operation with `opNOT_SUPPORTED` since protocol 12
/// ([CAP-26](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0026.md)).
/// This class represents it in transactions read from XDR so they can be read, encoded and hashed.
public class InflationOperation: Operation, @unchecked Sendable {
    /// Creates an inflation operation with an optional source account.
    ///
    /// - Parameter sourceAccountId: Optional G-address or M-address. If nil or invalid,
    ///   the transaction's source account is used.
    public override init(sourceAccountId: String? = nil) {
        super.init(sourceAccountId: sourceAccountId)
    }

    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.inflation
    }
}
