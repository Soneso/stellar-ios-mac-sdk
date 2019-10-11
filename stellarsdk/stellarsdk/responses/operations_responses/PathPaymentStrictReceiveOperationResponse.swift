//
//  PathPaymentStrictReceiveOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

///  Represents a path payment strict receive operation response.
public class PathPaymentStrictReceiveOperationResponse:PathPaymentOperationResponse {
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
