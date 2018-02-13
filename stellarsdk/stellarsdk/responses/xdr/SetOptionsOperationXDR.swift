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
        var container = try decoder.unkeyedContainer()
        
        inflationDestination = try container.decode(Array<PublicKey>.self).first
        clearFlags = try container.decode(Array<UInt32>.self).first
        setFlags = try container.decode(Array<UInt32>.self).first
        masterWeight = try container.decode(Array<UInt32>.self).first
        lowThreshold = try container.decode(Array<UInt32>.self).first
        medThreshold = try container.decode(Array<UInt32>.self).first
        highThreshold = try container.decode(Array<UInt32>.self).first
        homeDomain = try container.decode(Array<String>.self).first
        signer = try container.decode(Array<SignerXDR>.self).first
        
    }
    
    public init(inflationDestination: PublicKey?, clearFlags:UInt32?, setFlags:UInt32, masterWeight:UInt32?, lowThreshold:UInt32, medThreshold:UInt32, highThreshold:UInt32?, homeDomain:String?, signer:SignerXDR?) {
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
    }
}
