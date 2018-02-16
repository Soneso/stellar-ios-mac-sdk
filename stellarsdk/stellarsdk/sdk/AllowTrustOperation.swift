//
//  AllowTrustOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents an allow trust operation. Updates the authorized flag of an existing trustline. This can only be called by the issuer of a trustline’s asset. The issuer can only clear the authorized flag if the issuer has the AUTH_REVOCABLE_FLAG set. Otherwise, the issuer can only set the authorized flag.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#allow-trust, "Change Trust Operations")
 */
public class AllowTrustOperation:Operation {
    
    public let trustor:KeyPair
    public let assetCode:String
    public let authorize:Bool
    
    /**
        Constructor
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
        - Parameter trustor: The account of the recipient of the trustline.
        - Parameter asset: The asset of the trustline the source account is authorizing. For example, if an anchor wants to allow another account to hold its USD credit, the type is USD:anchor.
        - Parameter authorize: Flag indicating whether the trustline is authorized.
     */
    public init(sourceAccount:KeyPair, trustor:KeyPair, assetCode:String, authorize:Bool) {
        self.trustor = trustor
        self.assetCode = assetCode
        self.authorize = authorize
        super.init(sourceAccount:sourceAccount)
    }
}
