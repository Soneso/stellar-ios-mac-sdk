//
//  ClaimantPredicateResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimant predicate that defines conditions for claiming a claimable balance.
/// Predicates can be unconditional or time-based, and can be combined using logical operators.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimantPredicateResponse: NSObject, Decodable {

    /// Indicates whether the claimable balance can be claimed without any conditions.
    public var unconditional:Bool?

    /// A list of predicates that must all be satisfied (logical AND).
    public var and:[ClaimantPredicateResponse]?

    /// A list of predicates where at least one must be satisfied (logical OR).
    public var or:[ClaimantPredicateResponse]?

    /// A predicate that must not be satisfied (logical NOT).
    public var not:ClaimantPredicateResponse?

    /// An ISO 8601 formatted timestamp before which the claimable balance can be claimed.
    public var beforeAbsoluteTime:String?

    /// A relative time in seconds since the close time of the ledger in which the claimable balance was created.
    public var beforeRelativeTime:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case unconditional
        case and
        case or
        case not
        case beforeAbsoluteTime = "abs_before"
        case absBefore = "absBefore"
        case beforeRelativeTime = "rel_before"
        case relBefore = "relBefore"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        unconditional = try values.decodeIfPresent(Bool.self, forKey: .unconditional)
        and = try values.decodeIfPresent([ClaimantPredicateResponse].self, forKey: .and)
        or = try values.decodeIfPresent([ClaimantPredicateResponse].self, forKey: .or)
        not = try values.decodeIfPresent(ClaimantPredicateResponse.self, forKey: .not)
        if let absBefore = try values.decodeIfPresent(String.self, forKey: .beforeAbsoluteTime) {
            beforeAbsoluteTime = absBefore
        } else if let absBefore = try values.decodeIfPresent(String.self, forKey: .absBefore) {
            beforeAbsoluteTime = absBefore
        }
        if let relBefore = try values.decodeIfPresent(String.self, forKey: .beforeRelativeTime) {
            beforeRelativeTime = relBefore
        } else if let relBefore = try values.decodeIfPresent(String.self, forKey: .relBefore) {
            beforeRelativeTime = relBefore
        }
    }

    /// Prints a human-readable representation of the predicate structure to the console.
    public func printPredicate() {
        print("{")
        if let u = unconditional {
            print("unconditional:\(u)")
        }
        if let a = and {
            print("AND")
            for c in a {
                c.printPredicate()
            }
        }
        if let o = or {
            print("OR")
            for c in o {
                c.printPredicate()
            }
        }
        if let n = not {
            print("NOT")
            n.printPredicate()
        }
        if let absB = beforeAbsoluteTime {
            print("absBefore:\(absB)")
        }
        if let relB = beforeRelativeTime {
            print("relBefore:\(relB)")
        }
        print("}")
    }
}
