//
//  GetTransactionStatusResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class GetTransactionStatusResponse: NSObject, Decodable {
    
    /// Hash (id) of the transaction as a hex-encoded string
    public var id:String
    
    /// The current status of the transaction by hash, one of: pending, success, error
    public var status:String
    
    /// (optional) Will be present on completed successful transactions.
    public var results:[TransactionStatusResult]?
    
    /// (optional) A base64 encoded string of the raw TransactionEnvelope XDR struct for this transaction.
    public var envelopeXdr:String? // TransactionEnvelope
    
    ///  (optional) A base64 encoded string of the raw TransactionResult XDR struct for this transaction.
    public var resultXdr:String? // TransactionResult
    
    /// (optional) A base64 encoded string of the raw TransactionMeta XDR struct for this transaction.
    public var resultMetaXdr:String? // TransactionResultMeta
    
    /// (optional) Will be present on failed transactions.
    public var error:TransactionStatusError?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case results
        case envelopeXdr
        case resultXdr
        case resultMetaXdr
        case error
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        status = try values.decode(String.self, forKey: .status)
        envelopeXdr = try values.decodeIfPresent(String.self, forKey: .envelopeXdr)
        resultXdr = try values.decodeIfPresent(String.self, forKey: .resultXdr)
        resultMetaXdr = try values.decodeIfPresent(String.self, forKey: .resultMetaXdr)
        results = try values.decodeIfPresent([TransactionStatusResult].self, forKey: .results)
        error = try values.decodeIfPresent(TransactionStatusError.self, forKey: .error)
    }
    
    public var firstResult:TransactionStatusResult? {
        return results?.first
    }
    /// Extracts the wasm id from the response if the transaction installed a contract
    public var wasmId:String? {
        return binHex
    }
    
    /// Extracts the wasm id from the response if the transaction created a contract
    public var contractId:String? {
        return binHex
    }
    
    private var binHex:String? {
        if let data = bin {
            return data.hexEncodedString()
        }
        return nil
    }
    
    private var bin:Data? {
        if results != nil && results!.count > 0 {
            let xdr = results![0].xdr
            do {
                let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
                let xdrVal = try SCValXDR(from: xdrDecoder)
                return xdrVal.object?.bytes
            } catch {}
        }
        return nil
    }
}
