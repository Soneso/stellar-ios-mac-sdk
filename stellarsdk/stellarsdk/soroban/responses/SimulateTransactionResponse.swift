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
    
    /// If error is present then results will not be in the response
    public var results:[SimulateTransactionResult]?
    
    /// Information about the fees expected, instructions used, etc.
    public var cost:SimulateTransactionCost
    
    /// Stringified-number of the current latest ledger observed by the node when this response was generated.
    public var latestLedger:String
    
    ///  (optional) only present if the transaction failed. This field will include more details from stellar-core about why the invoke host function call failed.
    public var error:String?

    private enum CodingKeys: String, CodingKey {
        case results
        case cost
        case latestLedger
        case error
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        latestLedger = try values.decode(String.self, forKey: .latestLedger)
        cost = try values.decode(SimulateTransactionCost.self, forKey: .cost)
        error = try values.decodeIfPresent(String.self, forKey: .error)
        if error == nil {
            results = try values.decodeIfPresent([SimulateTransactionResult].self, forKey: .results)
        }
    }
    
    public var footprint:Footprint? {
        if(results != nil && results!.count > 0) {
            return results![0].footprint
        }
        return nil;
    }
    
    public var auth:[ContractAuth]? {
        if(results != nil && results!.count > 0) {
            if let auth = results![0].auth, auth.count > 0 {
                do {
                    var res:[ContractAuth] = []
                    for xdr in auth {
                        res.append(try ContractAuth(fromBase64Xdr: xdr))
                    }
                    return res
                } catch {
                    return nil
                }
            }
        }
        return nil;
    }
}
