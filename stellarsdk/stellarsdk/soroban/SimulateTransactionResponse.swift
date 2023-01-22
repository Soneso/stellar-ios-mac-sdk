//
//  SimulateTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response that will be received when submitting a trial contract invocation.
public class SimulateTransactionResponse: NSObject, Decodable {
    
    /// Footprint containing the ledger keys expected to be written by this transaction
    public var footprint:Footprint
    
    /// If error is present then results will not be in the response
    public var results:[TransactionStatusResult]?
    
    /// Information about the fees expected, instructions used, etc.
    public var cost:Cost
    
    /// Stringified-number of the current latest ledger observed by the node when this response was generated.
    public var latestLedger:String
    
    ///  (optional) only present if the transaction failed. This field will include more details from stellar-core about why the invoke host function call failed.
    public var error:String?

    private enum CodingKeys: String, CodingKey {
        case footprint
        case results
        case cost
        case latestLedger
        case error
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let footBase64 = try values.decodeIfPresent(String.self, forKey: .footprint)
        if (footBase64 != nil && footBase64!.trim() != "") {
            footprint = try Footprint(fromBase64: footBase64!)
        } else {
            footprint = Footprint.empty()
        }
        latestLedger = try values.decode(String.self, forKey: .latestLedger)
        cost = try values.decode(Cost.self, forKey: .cost)
        error = try values.decodeIfPresent(String.self, forKey: .error)
        if error == nil {
            results = try values.decodeIfPresent([TransactionStatusResult].self, forKey: .results)
        }
    }
}
