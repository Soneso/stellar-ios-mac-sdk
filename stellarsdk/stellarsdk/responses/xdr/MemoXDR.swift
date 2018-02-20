//
//  MemoXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct MemoType {
    static let MEMO_TYPE_NONE: Int32 = 0
    static let MEMO_TYPE_TEXT: Int32 = 1
    static let MEMO_TYPE_ID: Int32 = 2
    static let MEMO_TYPE_HASH: Int32 = 3
    static let MEMO_TYPE_RETURN: Int32 = 4
}

public enum MemoXDR: XDRCodable {
    case none
    case text (String)
    case id (UInt64)
    case hash (WrappedData32)
    case returnHash (WrappedData32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case MemoType.MEMO_TYPE_NONE:
            self = .none
        case MemoType.MEMO_TYPE_TEXT:
            let text = try container.decode(String.self)
            self = .text(text)
        case MemoType.MEMO_TYPE_ID:
            let id = try container.decode(UInt64.self)
            self = .id(id)
        case MemoType.MEMO_TYPE_HASH:
            let hash = try container.decode(WrappedData32.self)
            self = .hash(hash)
        case MemoType.MEMO_TYPE_RETURN:
            let hash = try container.decode(WrappedData32.self)
            self = .returnHash(hash)
        default:
            self = .none
        }
    }
    
    public func type() -> Int32 {
        switch self {
            case .none: return MemoType.MEMO_TYPE_NONE
            case .text: return MemoType.MEMO_TYPE_TEXT
            case .id: return MemoType.MEMO_TYPE_ID
            case .hash: return MemoType.MEMO_TYPE_HASH
            case .returnHash: return MemoType.MEMO_TYPE_RETURN
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
            case .none: break
            case .text(let text): try container.encode(text)
            case .id(let id): try container.encode(id)
            case .hash(let hash): try container.encode(hash)
            case .returnHash(let hash): try container.encode(hash)
        }
    }
    
}
