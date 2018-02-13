//
//  Memo.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum Memo: XDRCodable {
    case none
    case text (String)
    case id (UInt64)
    case hash (WrappedData32)
    case `return` (WrappedData32)
    
    private func type() -> Int32 {
        switch self {
        case .none: return Int32(MemoType.none.rawValue)
        case .text: return Int32(MemoType.text.rawValue)
        case .id: return Int32(MemoType.id.rawValue)
        case .hash: return Int32(MemoType.hash.rawValue)
        case .`return`: return Int32(MemoType.`return`.rawValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        _ = try container.decode(Int32.self)
        
        self = .none
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .none: break
        case .text(let text): try container.encode(text)
        case .id(let id): try container.encode(id)
        case .hash(let hash): try container.encode(hash)
        case .`return`(let hash): try container.encode(hash)
        }
    }
}
