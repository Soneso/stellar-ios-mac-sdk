//
//  DecoratedSignature.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DecoratedSignature: XDRCodable {
    public let hint: WrappedData4;
    public let signature: Data
    
    public init(hint: WrappedData4, signature: Data) {
        self.hint = hint
        self.signature = signature
    }
}
