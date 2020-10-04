//
//  EndSponsoringFutureReservesOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Terminates the current is-sponsoring-future-reserves-for relationship in which the source account is sponsored.
/// See [Stellar Guides](https://developers.stellar.org/docs/start/list-of-operations/#end-sponsoring-future-reserves "End Sponsoring Future Reserves").
public class EndSponsoringFutureReservesOperation:Operation {
    
    /// Creates a new EndSponsoringFutureReservesOperation object.
    ///
    /// - Parameter sponsoredAccountId: Account that will have it’s reserves sponsored.
    public init(sponsoredAccountId:String) {
        super.init(sourceAccountId:sponsoredAccountId)
    }
    
    /// Creates a new EndSponsoringFutureReservesOperation object from the given EndSponsoringFutureReservesOpXDR object.
    ///
    /// - Parameter fromXDR: the EndSponsoringFutureReservesOpXDR object to be used to create a new EndSponsoringFutureReservesOperation object.
    /// - Parameter sponsoredAccountId: the account id of the sponsored account (source account of the operation)
    public init(fromXDR:BeginSponsoringFutureReservesOpXDR, sponsoredAccountId:String) throws {
        super.init(sourceAccountId: sponsoredAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.endSponsoringFutureReserves
    }
}
