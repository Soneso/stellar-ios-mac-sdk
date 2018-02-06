//
//  OperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class OperationsResponse: NSObject {
    public var operations:[Operation]
    
    public init(operations: [Operation]) {
        self.operations = operations
    }
    
}
