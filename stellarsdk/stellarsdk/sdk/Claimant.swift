//
//  Claimant.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

// Claimant class which helps the creation of claimable balances.
// See: https://developers.stellar.org/docs/glossary/claimable-balance/
// The default behavior of this class it to create claimants with an unconditional predicate if none is passed.
public class Claimant {
    
    public final let destination:String
    public final let predicate:ClaimPredicateXDR
    
    /// Constructor
    /// - Parameter destination: The destination account ID.
    /// - Parameter predicate: The claim predicate. Optional, if none is passed an unconditional predicate will be used.
    public init(destination:String, predicate:ClaimPredicateXDR? = nil) {
        self.destination = destination
        if let pred = predicate {
            self.predicate = pred
        } else {
            self.predicate = ClaimPredicateXDR.claimPredicateUnconditional
        }
    }
    
    /// Returns an unconditional claim predicate
    /// - Returns an ClaimPredicateXDR object representing an unconditional claim predicate.
    public static func predicateUnconditional() -> ClaimPredicateXDR {
        return ClaimPredicateXDR.claimPredicateUnconditional
    }
    
    /// Returns an `and` claim predicate
    /// - Parameter left: a claim predicate
    /// - Parameter right: a claim predicate
    /// - Returns an ClaimPredicateXDR object representing an `and` claim predicate.
    public static func predicateAnd(left:ClaimPredicateXDR, right:ClaimPredicateXDR) -> ClaimPredicateXDR {
        return ClaimPredicateXDR.claimPredicateAnd([left,right])
    }
    
    /// Returns an `or` claim predicate
    /// - Parameter left: a claim predicate
    /// - Parameter right: a claim predicate
    /// - Returns an ClaimPredicateXDR object representing an `or` claim predicate.
    public static func predicateOr(left:ClaimPredicateXDR, right:ClaimPredicateXDR) -> ClaimPredicateXDR {
        return ClaimPredicateXDR.claimPredicateOr([left,right])
    }
    
    /// Returns a `not` claim predicate
    /// - Parameter predicate: a claim predicate
    /// - Returns an ClaimPredicateXDR object representing a `not` claim predicate.
    public static func predicateNot(predicate:ClaimPredicateXDR) -> ClaimPredicateXDR {
        return ClaimPredicateXDR.claimPredicateNot(predicate)
    }
    
    /// Returns a `BeforeAbsoluteTime` claim predicate. This predicate will be fulfilled if the closing time of the ledger that
    /// includes the CreateClaimableBalance operation is less than this (absolute) Unix timestamp.
    /// - Parameter unixEpoch: Unix timestamp
    /// - Returns an ClaimPredicateXDR object representing a `BeforeAbsoluteTime` claim predicate.
    public static func predicateBeforeAbsoluteTime(unixEpoch:Int64) -> ClaimPredicateXDR {
        return ClaimPredicateXDR.claimPredicateBeforeAbsTime(unixEpoch)
    }
    
    /// Returns a `BeforeRelativeTime` claim predicate. This predicate will be fulfilled if the closing time of the ledger that
    /// includes the CreateClaimableBalance operation plus this relative time delta
    /// (in seconds) is less than the current time.
    /// - Parameter seconds: seconds seconds since closeTime of the ledger in which the ClaimableBalanceEntry was created
    /// - Returns an ClaimPredicateXDR object representing a `BeforeRelativeTime` claim predicate.
    public static func predicateBeforeRelativeTime(seconds:Int64) -> ClaimPredicateXDR {
        return ClaimPredicateXDR.claimPredicateBeforeRelTime(seconds)
    }
    
    /// Returns the xdr object for this claimant.
    /// - Throws  StellarSDKError.xdrEncodingError if the XDR Object could not be created.
    /// - Returns the generated ClaimantXDR object.
    public func toXDR() throws -> ClaimantXDR {
        do {
            let destPK = try PublicKey.init(accountId: destination)
            return ClaimantXDR.claimantTypeV0(ClaimantV0XDR(accountID: destPK, predicate: predicate))
        } catch {
            throw StellarSDKError.xdrEncodingError(message: "Error encoding claimant: " + error.localizedDescription)
        }
    }
    
    /// Returns a claimant object from its XDR object representation.
    ///
    /// - Parameter claimantXDR: the ClaimantXDR object to be used create the Claimant object.
    ///
    /// - Throws StellarSDKError.xdrDecodingError if the Claimant object could not be created from the given ClaimantXDR object.
    ///
    /// - Returns the generated Claimant object.
    public static func fromXDR(claimantXDR:ClaimantXDR) throws -> Claimant {
        
        var result: Claimant?
        switch claimantXDR {
            case .claimantTypeV0(let v0):
                result = Claimant(destination: v0.accountID.accountId, predicate: v0.predicate)
        }
        guard let claimant = result else {
            throw StellarSDKError.xdrDecodingError(message: "Error decoding claimant: invalid data in xdr")
        }
        return claimant
    }
}
