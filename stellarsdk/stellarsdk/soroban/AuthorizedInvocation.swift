//
//  AuthorizedInvocation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class AuthorizedInvocation {
    
    public let contractId:String
    public let functionName:String
    public let args:[SCValXDR]
    public let subInvocations:[AuthorizedInvocation]
    
    public init(contractId:String, functionName:String, args:[SCValXDR] = [], subInvocations:[AuthorizedInvocation] = []) {
        self.contractId = contractId
        self.functionName = functionName
        self.args = args
        self.subInvocations = subInvocations
    }
    
    public convenience init(xdr: AuthorizedInvocationXDR) {
        let contractId = xdr.contractID.wrapped.hexEncodedString()
        let functionName = xdr.functionName
        let args = xdr.args
        var subs:[AuthorizedInvocation] = []
        for next in xdr.subInvocations {
            subs.append(AuthorizedInvocation(xdr: next))
        }
        self.init(contractId: contractId, functionName: functionName, args: args, subInvocations: subs)
    }
}
