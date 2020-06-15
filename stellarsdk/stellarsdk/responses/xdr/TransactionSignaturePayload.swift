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
        case typeTXV0 (TransactionV0XDR)
        case typeTX (TransactionXDR)
        case typeFeeBump (FeeBumpTransactionXDR)
        
        private func discriminant() -> Int32 {
            switch self {
            case .typeTXV0: return EnvelopeType.ENVELOPE_TYPE_TX
            case .typeTX: return EnvelopeType.ENVELOPE_TYPE_TX
            case .typeFeeBump: return EnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            try container.encode(discriminant())
            
            switch self {
            case .typeTXV0 (let tx): try container.encode(tx)
            case .typeTX (let tx): try container.encode(tx)
            case .typeFeeBump (let tx): try container.encode(tx)
            }
        }
    }
}
