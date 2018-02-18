//
//  SetOptionsOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a set options operation. This operation sets the options for an account.
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
    
    /**
     Constructor
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
        - Parameter inflationDestination: Account of the inflation destination.
        - Parameter clearFlags: The asset you would like to buy. Indicates which flags to clear. For details about the flags, please refer to the accounts doc (https://www.stellar.org/developers/guides/concepts/accounts.html). The bit mask integer subtracts from the existing flags of the account. This allows for setting specific bits without knowledge of existing flags.
        - Parameter setFlags: Indicates which flags to set. For details about the flags, please refer to the accounts doc (https://www.stellar.org/developers/guides/concepts/accounts.html). The bit mask integer adds onto the existing flags of the account. This allows for setting specific bits without knowledge of existing flags.
        - Parameter masterKeyWeight: Weight of the master key. This account may also add other keys with which to sign transactions using signer below.
        - Parameter lowThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a low threshold.
        - Parameter mediumThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a medium threshold.
        - Parameter highThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a high threshold.
        - Parameter homeDomain: Sets the home domain of an account. See Federation (https://www.stellar.org/developers/guides/concepts/federation.html).
        - Parameter signer: Signers PublicKey. If you fill this parameter you also need to fill 'signerWeight'
        - Parameter signerWeight: Add or remove the signer from parameter 'signer'. The signer is deleted if the weight is 0.
     
        - Throws StellarSDKError.invalidArgument if signer is not nil but signerWeight is nil
     */
    public init(sourceAccount:KeyPair, inflationDestination:KeyPair?, clearFlags:Int?, setFlags:Int?, masterKeyWeight:Int?, lowThreshold:Int?, mediumThreshold:Int?, highThreshold:Int?, homeDomain:String?, signer:SignerKeyXDR?, signerWeight:Int?) throws {
        
        
        if signer != nil && signerWeight == nil {
            throw StellarSDKError.invalidArgument(message: "Signer Weight can not be nil if signer is not nil")
        }
        
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
