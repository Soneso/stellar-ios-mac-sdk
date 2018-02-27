//
//  Memo.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/16/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  The memo contains optional extra information. It is the responsibility of the client to interpret this value.
///  See [Horizon Guides](https://www.stellar.org/developers/guides/concepts/transactions.html#memo, "Memo")
///
///  Memos can be one of the following types:
/// - none: Empty memo.
/// - text: A string encoded using either ASCII or UTF-8, up to 28-bytes long.
/// - id: A 64 bit unsigned integer.
/// - hash: A 32 byte hash.
/// - returnHash:  A 32 byte hash intended to be interpreted as the hash of the transaction the sender is refunding.
///
public enum Memo {
    case none
    case text (String)
    case id (UInt64)
    case hash (Data)
    case returnHash (Data)
}

extension Memo: MemoProtocol {
    
    public func toXDR() -> MemoXDR {
        switch self {
            case .none: return MemoXDR.none
            case .text(let text): return MemoXDR.text(text)
            case .id(let id): return MemoXDR.id(id)
            case .hash(let hash): return MemoXDR.hash(WrappedData32(hash))
            case .returnHash(let hash): return MemoXDR.returnHash(WrappedData32(hash))
        }
    }
    
    /// Creates a memo of type text. Validates if the String is up to 28-bytes long.
    ///
    /// - Parameter text: String representing the text for the memo. Must be not larger than 28 bytes.
    ///
    /// - Throws an StellarSDKError.invalidArgument error if the given string is larger than 28 bytes.
    ///
    public init?(text:String) throws {
        if text.utf8CString.count > 28 {
            throw StellarSDKError.invalidArgument(message: "text must be <= 28 bytes. length=\(text.count)" )
        }
        self = .text(text)
    }
    
    /// Creates a memo of type hash. Validates if the hash is up to 32-bytes long.
    ///
    /// - Parameter hash: Data representing the hash for the memo. Must be not larger than 32 bytes.
    ///
    /// - Throws an StellarSDKError.invalidArgument error if the given data is larger than 32 bytes.
    ///
    public init?(hash:Data) throws {
        if (hash.count > 32) {
            throw StellarSDKError.invalidArgument(message: "MEMO_HASH can contain 32 bytes at max.")
        }
        self = .hash(hash)
    }
    
    /// Creates a memo of type returnHash. Validates if the hash is up to 32-bytes long.
    ///
    /// - Parameter hash: Data representing the hash for the memo. Must be not larger than 32 bytes.
    ///
    /// - Throws an StellarSDKError.invalidArgument error if the given data is larger than 32 bytes.
    ///
    public init?(returnHash:Data) throws {
        if (returnHash.count > 32) {
            throw StellarSDKError.invalidArgument(message: "MEMO_RETURN_HASH can contain 32 bytes at max.")
        }
        self = .returnHash(returnHash)
    }
    
    public func type() -> String {
        switch self {
        case .none: return MemoTypeAsString.NONE
        case .text: return MemoTypeAsString.TEXT
        case .id: return MemoTypeAsString.ID
        case .hash: return MemoTypeAsString.HASH
        case .returnHash: return MemoTypeAsString.RETURN
        }
    }
}

extension Memo:MemoHashProtocol {
    
    public func hexValue() throws -> String {
        switch self {
        case .hash(let hash):
            return hash.hexEncodedString()
        case .returnHash(let returnHash):
            return returnHash.hexEncodedString()
        default:
            throw StellarSDKError.invalidArgument(message: "Only hash, return_hash has hex value")
        }
    }
    
    public func trimmedHexValue() throws -> String {
        let str = try self.hexValue().split(separator: "0").first
        return String(describing: str)
    }
}

extension Memo: Equatable {
    public static func ==(lhs: Memo, rhs: Memo) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case let (.text(l), .text(r)): return l == r
        case let (.id(l), .id(r)): return l == r
        case let (.hash(l), .hash(r)): return l == r
        case let (.returnHash(l), .returnHash(r)): return l == r
        default: return false
        }
    }
}

