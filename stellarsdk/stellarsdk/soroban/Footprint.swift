//
//  Footprint.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 17.01.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Ledger footprint wrapper for Soroban transaction simulation.
///
/// A footprint represents the set of ledger entries that a Soroban transaction
/// will read from or write to during execution. Footprints are returned when
/// simulating transactions and must be included in the final transaction to
/// ensure resource limits are properly calculated.
///
/// The footprint contains two categories of ledger keys:
/// - Read-only: Entries the transaction will read but not modify
/// - Read-write: Entries the transaction will read and potentially modify
///
/// This class provides utility methods to:
/// - Parse footprints from base64-encoded XDR
/// - Extract specific ledger keys (contract code, contract data)
/// - Convert footprints to XDR format for transaction submission
///
/// Example:
/// ```swift
/// // Parse footprint from simulation response
/// let footprint = try Footprint(fromBase64: simulationResponse.footprint)
///
/// // Extract contract code ledger key
/// if let codeKey = footprint.contractCodeLedgerKey {
///     print("Contract code key: \(codeKey)")
/// }
///
/// // Create empty footprint
/// let emptyFootprint = Footprint.empty()
/// ```
///
/// See also:
/// - [SimulateTransactionResponse] for simulation results
/// - SorobanTransactionDataXDR for transaction resource configuration
/// - [Stellar developer docs](https://developers.stellar.org)
public final class Footprint: Sendable {

    /// The underlying XDR footprint containing read-only and read-write ledger keys.
    public let xdrFootprint:LedgerFootprintXDR

    /// Creates a footprint from an XDR footprint object.
    ///
    /// - Parameter xdrFootprint: The XDR representation of the ledger footprint
    public init(xdrFootprint: LedgerFootprintXDR) {
        self.xdrFootprint = xdrFootprint
    }

    /// Creates a footprint by decoding base64-encoded XDR.
    ///
    /// - Parameter xdr: Base64-encoded XDR string representing a LedgerFootprintXDR
    /// - Throws: XDR decoding errors if the input is invalid
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self.xdrFootprint = try LedgerFootprintXDR(from: xdrDecoder)
    }

    /// Creates an empty footprint with no read-only or read-write entries.
    ///
    /// - Returns: A new Footprint instance with empty ledger key arrays
    public static func empty() -> Footprint {
        let xdrFootprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        return Footprint(xdrFootprint: xdrFootprint)
    }

    /// The footprint encoded as a base64 XDR string.
    ///
    /// Use this to include the footprint in transaction submission.
    public var xdrEncoded:String {
        return xdrFootprint.xdrEncoded!
    }

    /// The first contract code ledger key found in the footprint, encoded as base64 XDR.
    ///
    /// Returns nil if no contract code entry exists in the footprint.
    public var contractCodeLedgerKey:String? {
        return contractCodeLedgerKeyXDR?.xdrEncoded
    }

    /// The first contract code ledger key found in the footprint as an XDR object.
    ///
    /// Searches both read-only and read-write entries for a LedgerEntryType.contractCode key.
    /// Returns nil if no contract code entry exists in the footprint.
    public var contractCodeLedgerKeyXDR:LedgerKeyXDR? {
        return firstKeyOfType(type: LedgerEntryType.contractCode)
    }

    /// The first contract data ledger key found in the footprint, encoded as base64 XDR.
    ///
    /// Returns nil if no contract data entry exists in the footprint.
    public var contractDataLedgerKey:String? {
      return contractDataLedgerKeyXDR?.xdrEncoded
    }

    /// The first contract data ledger key found in the footprint as an XDR object.
    ///
    /// Searches both read-only and read-write entries for a LedgerEntryType.contractData key.
    /// Returns nil if no contract data entry exists in the footprint.
    public var contractDataLedgerKeyXDR:LedgerKeyXDR? {
        return firstKeyOfType(type: LedgerEntryType.contractData)
    }
    
    private func firstKeyOfType(type:LedgerEntryType) -> LedgerKeyXDR? {
        for key in xdrFootprint.readOnly {
            if key.type() == type.rawValue {
                return key
            }
        }
        for key in xdrFootprint.readWrite {
            if key.type() == type.rawValue {
                return key
            }
        }
        return nil
    }
    
}
