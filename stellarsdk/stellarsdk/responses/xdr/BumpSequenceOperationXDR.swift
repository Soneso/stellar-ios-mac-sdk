//
//  BumpSequenceOperationXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct BumpSequenceOperationXDR: XDRCodable {

    public var bumpTo:Int64
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        bumpTo = try container.decode(Int64.self)
    }
    
    public init(bumpTo:Int64) {
        self.bumpTo = bumpTo
    }
    
}
