//
//  Footprint.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 17.01.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Footprint received when simulating a transaction.
/// Contains utility functions.
public class Footprint {
    
    public let xdrFootprint:LedgerFootprintXDR
    
    public init(xdrFootprint: LedgerFootprintXDR) {
        self.xdrFootprint = xdrFootprint
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self.xdrFootprint = try LedgerFootprintXDR(from: xdrDecoder)
    }
    
    public static func empty() -> Footprint {
        let xdrFootprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        return Footprint(xdrFootprint: xdrFootprint)
    }
    
    public var xdrEncoded:String {
        return xdrFootprint.xdrEncoded!
    }
    
    public var contractCodeLedgerKey:String? {
        return contractCodeLedgerKeyXDR?.xdrEncoded
    }
    
    public var contractCodeLedgerKeyXDR:LedgerKeyXDR? {
        return firstKeyOfType(type: LedgerEntryType.contractCode)
    }
    
    public var contractDataLedgerKey:String? {
      return contractDataLedgerKeyXDR?.xdrEncoded
    }
    
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
