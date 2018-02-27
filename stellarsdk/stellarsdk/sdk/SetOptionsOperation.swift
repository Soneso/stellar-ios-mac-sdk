//
//  SetOptionsOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a set options operation. This operation sets the options for an account.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#set-options, "Set Options Operations").
public class SetOptionsOperation:Operation {
    
    public let inflationDestination:KeyPair?
    public let clearFlags:UInt32?
    public let setFlags:UInt32?
    public let masterKeyWeight:UInt32?
    public let lowThreshold:UInt32?
    public let mediumThreshold:UInt32?
    public let highThreshold:UInt32?
    public let homeDomain:String?
    public let signer:SignerKeyXDR?
    public let signerWeight:UInt32?
    
    /// Creates a new SetOptionsOperation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    /// - Parameter inflationDestination: Account of the inflation destination.
    /// - Parameter clearFlags: The asset you would like to buy. Indicates which flags to clear. For details about the flags, please refer to the accounts doc (https://www.stellar.org/developers/guides/concepts/accounts.html). The bit mask integer subtracts from the existing flags of the account. This allows for setting specific bits without knowledge of existing flags.
    /// - Parameter setFlags: Indicates which flags to set. For details about the flags, please refer to the accounts doc (https://www.stellar.org/developers/guides/concepts/accounts.html). The bit mask integer adds onto the existing flags of the account. This allows for setting specific bits without knowledge of existing flags.
    /// - Parameter masterKeyWeight: Weight of the master key. This account may also add other keys with which to sign transactions using signer below.
    /// - Parameter lowThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a low threshold.
    /// - Parameter mediumThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a medium threshold.
    /// - Parameter highThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a high threshold.
    /// - Parameter homeDomain: Sets the home domain of an account. See Federation (https://www.stellar.org/developers/guides/concepts/federation.html).
    /// - Parameter signer: Signers PublicKey. If you fill this parameter you also need to fill 'signerWeight'
    /// - Parameter signerWeight: Add or remove the signer from parameter 'signer'. The signer is deleted if the weight is 0.
    ///
    /// - Throws StellarSDKError.invalidArgument if signer is not nil but signerWeight is nil
    ///
    public init(sourceAccount:KeyPair? = nil, inflationDestination:KeyPair? = nil, clearFlags:UInt32? = nil, setFlags:UInt32? = nil, masterKeyWeight:UInt32? = nil, lowThreshold:UInt32? = nil, mediumThreshold:UInt32? = nil, highThreshold:UInt32? = nil, homeDomain:String? = nil, signer:SignerKeyXDR? = nil, signerWeight:UInt32? = nil) throws {
        
        
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
    
    /// Creates a new SetOptionsOperation object from the given SetOptionsOperationXDR object.
    ///
    /// - Parameter fromXDR: the SetOptionsOperationXDR object to be used to create a new SetOptionsOperation object.
    ///
    public init(fromXDR:SetOptionsOperationXDR, sourceAccount:KeyPair? = nil) {
        if let inflation = fromXDR.inflationDestination {
            self.inflationDestination = KeyPair(publicKey: inflation)
        } else {
            self.inflationDestination = nil
        }
        self.clearFlags = fromXDR.clearFlags
        self.setFlags = fromXDR.setFlags
        self.masterKeyWeight = fromXDR.masterWeight
        self.lowThreshold = fromXDR.lowThreshold
        self.mediumThreshold = fromXDR.medThreshold
        self.highThreshold = fromXDR.highThreshold
        self.homeDomain = fromXDR.homeDomain
        self.signer = fromXDR.signer?.key
        if let weight = fromXDR.signer?.weight {
            self.signerWeight = weight & 0xFF
        } else {
            self.signerWeight = fromXDR.signer?.weight
        }
        super.init(sourceAccount: sourceAccount)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {

        
        if signer != nil && signerWeight != nil {
            return OperationBodyXDR.setOptions(SetOptionsOperationXDR(inflationDestination: inflationDestination?.publicKey,
                                                                      clearFlags: clearFlags,
                                                                      setFlags: setFlags,
                                                                      masterWeight: masterKeyWeight,
                                                                      lowThreshold: lowThreshold,
                                                                      medThreshold: mediumThreshold,
                                                                      highThreshold: highThreshold,
                                                                      homeDomain: homeDomain,
                                                                      signer:SignerXDR(key: signer!, weight: signerWeight!)))
        } else {
            return OperationBodyXDR.setOptions(SetOptionsOperationXDR(inflationDestination: inflationDestination?.publicKey,
                                                                      clearFlags: clearFlags,
                                                                      setFlags: setFlags,
                                                                      masterWeight: masterKeyWeight,
                                                                      lowThreshold: lowThreshold,
                                                                      medThreshold: mediumThreshold,
                                                                      highThreshold: highThreshold,
                                                                      homeDomain: homeDomain,
                                                                      signer:nil))
        }
    }
}
