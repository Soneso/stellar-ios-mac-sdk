//
//  Address.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum Address: XDRCodable {
    case accountId(String)
    case contractId(String)
    
    public init(xdr: SCAddressXDR) {
        switch xdr {
        case .account(let pk):
            self = .accountId(pk.accountId)
        case .contract(let data):
            let contractId = data.wrapped.hexEncodedString()
            self = .contractId(contractId)
        }
    }
}
