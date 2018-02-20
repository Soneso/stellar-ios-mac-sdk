//
//  SubmitTransactionResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 18.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  A successful response to a post transaction request.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/transactions-create.html "Post Transaction")
public class SubmitTransactionResponse: NSObject, Decodable {
    
    /// A hex-encoded hash of the submitted transaction.
    public var transactionHash:String
    
    /// The ledger number that the submitted transaction was included in.
    public var ledger:Int
    
    public var transactionEnvelope: TransactionEnvelopeXDR
    public var transactionResult: TransactionResultXDR
    public var transactionMeta: TransactionMetaXDR
    
    //public var extras:Extras
    
    private enum CodingKeys: String, CodingKey {
        case transactionHash = "hash"
        case ledger
        case envelopeXDR = "envelope_xdr"
        case transactionResult = "result_xdr"
        case transactionMeta = "result_meta_xdr"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        ledger = try values.decode(Int.self, forKey: .ledger)
        
        let encodedEnvelope = try values.decode(String.self, forKey: .envelopeXDR)
        let data = Data(base64Encoded: encodedEnvelope)!
        transactionEnvelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data:data)
        
        let encodedResult = try values.decode(String.self, forKey: .transactionResult)
        let resultData = Data(base64Encoded: encodedResult)!
        transactionResult = try XDRDecoder.decode(TransactionResultXDR.self, data:resultData)
        
        let encodedMeta = try values.decode(String.self, forKey: .transactionMeta)
        let metaData = Data(base64Encoded: encodedMeta)!
        transactionMeta = try XDRDecoder.decode(TransactionMetaXDR.self, data:metaData)
    }
}
