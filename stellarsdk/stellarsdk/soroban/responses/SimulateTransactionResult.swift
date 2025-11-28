//
//  SimulateTransactionResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Individual result from a simulated transaction operation.
///
/// Part of SimulateTransactionResponse, contains the return value and authorization
/// requirements for a single host function invocation.
///
/// Contains:
/// - Return value from the contract function
/// - Authorization entries required for execution
///
/// For most contract calls, SimulateTransactionResponse.results will contain
/// a single element with the contract's return value.
///
/// See also:
/// - [SimulateTransactionResponse] for the complete simulation response
public struct SimulateTransactionResult: Decodable, Sendable {

    /// Array of serialized base64 strings - Per-address authorizations recorded when simulating this Host Function call.
    public let auth:[String] // SorobanAuthorizationEntryXDR, see SimulateTransactionResponse.sorobanAuth

    /// Serialized base64 string - return value of the Host Function call.
    public let xdr:String

    private enum CodingKeys: String, CodingKey {
        case auth
        case xdr
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        auth = try values.decode([String].self, forKey: .auth)
        xdr = try values.decode(String.self, forKey: .xdr)
    }

    /// Converts the return value of the Host Function call to a SCValXDR object
    public var value:SCValXDR? {
        return try? SCValXDR.fromXdr(base64: xdr)
    }
}
