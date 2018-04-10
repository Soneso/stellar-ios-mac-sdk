//
//  SetOptionsOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct SetOptionsOperationXDR: XDRCodable {
    public var inflationDestination: PublicKey?
    public var clearFlags: UInt32?
    public var setFlags: UInt32?
    public var masterWeight: UInt32?
    public var lowThreshold: UInt32?
    public var medThreshold: UInt32?
    public var highThreshold: UInt32?
    public var homeDomain: String?
    public var signer: SignerXDR?
    
    public init(from decoder: Decoder) throws {
        //var container = try decoder.unkeyedContainer()
        
        inflationDestination = try decodeArray(type: PublicKey.self, dec: decoder).first
        clearFlags = try decodeArray(type: UInt32.self, dec: decoder).first
        setFlags = try decodeArray(type: UInt32.self, dec: decoder).first
        masterWeight = try decodeArray(type: UInt32.self, dec: decoder).first
        lowThreshold = try decodeArray(type: UInt32.self, dec: decoder).first
        medThreshold = try decodeArray(type: UInt32.self, dec: decoder).first
        highThreshold = try decodeArray(type: UInt32.self, dec: decoder).first
        homeDomain = try decodeArray(type: String.self, dec: decoder).first
        signer = try decodeArray(type: SignerXDR.self, dec: decoder).first
        
    }
    
    public init(inflationDestination: PublicKey?, clearFlags:UInt32?, setFlags:UInt32?, masterWeight:UInt32?, lowThreshold:UInt32?, medThreshold:UInt32?, highThreshold:UInt32?, homeDomain:String?, signer:SignerXDR?) {
        self.inflationDestination = inflationDestination
        self.clearFlags = clearFlags
        self.setFlags = setFlags
        self.masterWeight = masterWeight
        self.lowThreshold = lowThreshold
        self.medThreshold = medThreshold
        self.highThreshold = highThreshold
        self.homeDomain = homeDomain
        self.signer = signer
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(inflationDestination)
        try container.encode(clearFlags)
        try container.encode(setFlags)
        try container.encode(masterWeight)
        try container.encode(lowThreshold)
        try container.encode(medThreshold)
        try container.encode(highThreshold)
        try container.encode(homeDomain)
        try container.encode(signer)
    }
}
