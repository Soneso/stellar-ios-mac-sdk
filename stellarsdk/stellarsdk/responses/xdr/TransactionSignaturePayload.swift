//
//  TransactionSignaturePayload.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 20/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

struct TransactionSignaturePayload: XDREncodable {
    let networkId: WrappedData32
    let taggedTransaction: TaggedTransaction
    
    enum TaggedTransaction: XDREncodable {
        case typeTX (TransactionXDR)
        
        private func discriminant() -> Int32 {
            switch self {
            case .typeTX: return EnvelopeType.typeTX.rawValue
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            try container.encode(discriminant())
            
            switch self {
            case .typeTX (let tx): try container.encode(tx)
            }
        }
    }
}
