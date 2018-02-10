//
//  Seed.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import ed25519C

public class Seed {
    private let buffer: [UInt8]

    init(unchecked bytes: [UInt8]) {
        self.buffer = bytes
    }
    
    public init(bytes: [UInt8]) throws {
        guard bytes.count == 32 else {
            throw Ed25519Error.invalidSeedLength
        }
        
        buffer = bytes
    }

    public convenience init() throws {
        var buffer = [UInt8](repeating: 0, count: 32)
        
        let result = buffer.withUnsafeMutableBufferPointer {
            ed25519_create_seed($0.baseAddress)
        }
        
        guard result == 0 else {
            throw Ed25519Error.seedGenerationFailed
        }
        
        self.init(unchecked: buffer)
    }

    public var bytes: [UInt8] {
        return buffer
    }
}
