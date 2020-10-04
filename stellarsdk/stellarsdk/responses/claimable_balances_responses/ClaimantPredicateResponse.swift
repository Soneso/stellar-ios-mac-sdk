//
//  ClaimantPredicateResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class ClaimantPredicateResponse: NSObject, Decodable {
    
    public var unconditional:Bool?
    public var and:[ClaimantPredicateResponse]?
    public var or:[ClaimantPredicateResponse]?
    public var not:ClaimantPredicateResponse?
    public var beforeAbsoluteTime:String?
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
