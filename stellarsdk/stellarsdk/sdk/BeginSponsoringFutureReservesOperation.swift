//
//  BeginSponsoringFutureReservesOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Establishes the is-sponsoring-future-reserves-for relationship between the source account and sponsoredID.
/// See [Stellar Guides](https://developers.stellar.org/docs/start/list-of-operations/#begin-sponsoring-future-reserves "Begin Sponsoring Future Reserves").
public class BeginSponsoringFutureReservesOperation:Operation {
    
    public let sponsoredId:String
    
    /// Creates a new BeginSponsoringFutureReservesOperation object.
    ///
    /// - Parameter sponsoredId: Account that will have it’s reserves sponsored.
    /// - Parameter sponsoringAccountId: Account that will sponsor.
    public init(sponsoredAccountId:String, sponsoringAccountId:String) {
        self.sponsoredId = sponsoredAccountId
        super.init(sourceAccountId:sponsoringAccountId)
    }
    
    /// Creates a new BeginSponsoringFutureReservesOperation object from the given BeginSponsoringFutureReservesOpXDR object.
    ///
    /// - Parameter fromXDR: the BeginSponsoringFutureReservesOpXDR object to be used to create a new BeginSponsoringFutureReservesOperation object.
    /// - Parameter sponsoringAccountId: Account that will sponsor (source account of the operation)
    public init(fromXDR:BeginSponsoringFutureReservesOpXDR, sponsoringAccountId:String) throws {
        sponsoredId = fromXDR.sponsoredId.accountId
        super.init(sourceAccountId: sponsoringAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        
        let pk = try PublicKey(accountId: sponsoredId)
        let op = BeginSponsoringFutureReservesOpXDR(sponsoredId: pk)
        return OperationBodyXDR.beginSponsoringFutureReserves(op)
    }
}
