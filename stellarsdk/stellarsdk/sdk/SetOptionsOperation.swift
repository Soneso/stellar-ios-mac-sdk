//
//  SetOptionsOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a set options operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#set-options, "Set Options Operations")
 */
public class SetOptionsOperation:Operation {
    
    public let inflationDestination:KeyPair?
    public let clearFlags:Int?
    public let setFlags:Int?
    public let masterKeyWeight:Int?
    public let lowThreshold:Int?
    public let mediumThreshold:Int?
    public let highThreshold:Int?
    public let homeDomain:String?
    public let signer:SignerKeyXDR?
    public let signerWeight:Int?
    
    public init(sourceAccount:KeyPair, inflationDestination:KeyPair?, clearFlags:Int?, setFlags:Int?, masterKeyWeight:Int?, lowThreshold:Int?, mediumThreshold:Int?, highThreshold:Int?, homeDomain:String?, signer:SignerKeyXDR?, signerWeight:Int?) {
        self.inflationDestination = inflationDestination
        self.clearFlags = clearFlags
        self.setFlags = setFlags
        self.masterKeyWeight = masterKeyWeight
        self.lowThreshold = lowThreshold
        self.mediumThreshold = mediumThreshold
        self.highThreshold = highThreshold
        self.homeDomain = homeDomain
        self.signer = signer
        self.signerWeight = signerWeight
        super.init(sourceAccount:sourceAccount)
    }
}
