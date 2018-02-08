//
//  OperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class AllOperationsResponse: NSObject {
    public var operations:[OperationResponse]
    
    public init(operations: [OperationResponse]) {
        self.operations = operations
    }
    
}
