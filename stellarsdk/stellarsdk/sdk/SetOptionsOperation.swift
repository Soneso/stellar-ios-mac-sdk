//
//  SetOptionsOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a set options operation. This operation sets the options for an account.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SetOptionsOperation:Operation, @unchecked Sendable {

    /// Account of the inflation destination.
    public let inflationDestination:KeyPair?
    /// Indicates which flags to clear. The bit mask subtracts from the existing flags.
    public let clearFlags:UInt32?
    /// Indicates which flags to set. The bit mask adds onto the existing flags.
    public let setFlags:UInt32?
    /// Weight of the master key for signing transactions.
    public let masterKeyWeight:UInt32?
    /// Threshold for operations with low threshold requirement. Value from 0-255.
    public let lowThreshold:UInt32?
    /// Threshold for operations with medium threshold requirement. Value from 0-255.
    public let mediumThreshold:UInt32?
    /// Threshold for operations with high threshold requirement. Value from 0-255.
    public let highThreshold:UInt32?
    /// Sets the home domain of the account.
    public let homeDomain:String?
    /// The public key of the signer to add, remove, or update.
    public let signer:SignerKeyXDR?
    /// The weight of the signer. Set to 0 to remove the signer.
    public let signerWeight:UInt32?

    
    /// Creates a new SetOptionsOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    /// - Parameter inflationDestination: Account of the inflation destination.
    /// - Parameter clearFlags: The asset you would like to buy. Indicates which flags to clear. For details about the flags, please refer to the [Stellar developer docs](https://developers.stellar.org). The bit mask integer subtracts from the existing flags of the account. This allows for setting specific bits without knowledge of existing flags.
    /// - Parameter setFlags: Indicates which flags to set. For details about the flags, please refer to the [Stellar developer docs](https://developers.stellar.org). The bit mask integer adds onto the existing flags of the account. This allows for setting specific bits without knowledge of existing flags.
    /// - Parameter masterKeyWeight: Weight of the master key. This account may also add other keys with which to sign transactions using signer below.
    /// - Parameter lowThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a low threshold.
    /// - Parameter mediumThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a medium threshold.
    /// - Parameter highThreshold: A number from 0-255 representing the threshold this account sets on all operations it performs that have a high threshold.
    /// - Parameter homeDomain: Sets the home domain of an account.
    /// - Parameter signer: Signers PublicKey. If you fill this parameter you also need to fill 'signerWeight'
    /// - Parameter signerWeight: Add or remove the signer from parameter 'signer'. The signer is deleted if the weight is 0.
    ///
    /// - Throws StellarSDKError.invalidArgument if signer is not nil but signerWeight is nil
    ///
    public init(sourceAccountId:String?, inflationDestination:KeyPair? = nil, clearFlags:UInt32? = nil, setFlags:UInt32? = nil, masterKeyWeight:UInt32? = nil, lowThreshold:UInt32? = nil, mediumThreshold:UInt32? = nil, highThreshold:UInt32? = nil, homeDomain:String? = nil, signer:SignerKeyXDR? = nil, signerWeight:UInt32? = nil) throws {
        
        
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
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new SetOptionsOperation object from the given SetOptionsOperationXDR object.
    ///
    /// - Parameter fromXDR: the SetOptionsOperationXDR object to be used to create a new SetOptionsOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:SetOptionsOperationXDR, sourceAccountId:String?) {
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
            self.signerWeight = weight & StellarProtocolConstants.SIGNER_WEIGHT_MASK
        } else {
            self.signerWeight = fromXDR.signer?.weight
        }
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {

        var signerXDR: SignerXDR? = nil
        if let signer = signer, let signerWeight = signerWeight {
            signerXDR = SignerXDR(key: signer, weight: signerWeight)
        }

        return OperationBodyXDR.setOptions(SetOptionsOperationXDR(inflationDestination: inflationDestination?.publicKey,
                                                                  clearFlags: clearFlags,
                                                                  setFlags: setFlags,
                                                                  masterWeight: masterKeyWeight,
                                                                  lowThreshold: lowThreshold,
                                                                  medThreshold: mediumThreshold,
                                                                  highThreshold: highThreshold,
                                                                  homeDomain: homeDomain,
                                                                  signer: signerXDR))
    }
}
